# UMLS::Similarity::lesk.pm
#
# Module implementing the semantic relatedness measure described 
# by Banerjee and Pedersen(2002)
#
# Copyright (c) 2009-2010,
#
# Bridget T McInnes, University of Minnesota, Twin Cities
# bthomson at umn.edu
#
# Siddharth Patwardhan, University of Utah, Salt Lake City
# sidd at cs.utah.edu
#
# Serguei Pakhomov, University of Minnesota, Twin Cities
# pakh002 at umn.edu
#
# Ted Pedersen, University of Minnesota, Duluth
# tpederse at d.umn.edu
#
# Ying Liu, University of Minnesota, Twin Cities
# liux0935 at umn.edu
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to 
#
# The Free Software Foundation, Inc., 
# 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307, USA.


package UMLS::Similarity::lesk;

use strict;
use warnings;

use UMLS::Similarity;
use Text::OverlapFinder;
use Lingua::Stem::En;


use vars qw($VERSION);
$VERSION = '0.02';

my $debug      = 0;

my $debugfile  = ""; 
my $stoplist   = "";
my $stopregex  = "";
my $finder     = "";
my $dictfile   = "";
my $defraw_option = 0;
my $stem	   = "";
my $stemmed_words = "";
my $score 		= 0;
my %dictionary = ();


local(*DEBUG);

sub new
{
    my $className = shift;

    return undef if(ref $className);

    my $interface = shift;
    my $params    = shift;

    $params = {} if(!defined $params);

    $stoplist   = $params->{'stoplist'};
    $debugfile  = $params->{'debugfile'};
    $dictfile   = $params->{'dictfile'};
	$stem		= $params->{'stem'};	

    my $defraw     = $params->{'defraw'};

    my $self = {};
    
    # Bless the object.
    bless($self, $className);

    #  set the finder handler
    $finder = Text::OverlapFinder->new;
    
    # The backend interface object.
    $self->{'interface'} = $interface;

    #  check the configuration file if defined
    my $errorhandler = UMLS::Similarity::ErrorHandler->new("lesk",  $interface);
    if(!$errorhandler) {
	print STDERR "The UMLS::Similarity::ErrorHandler did not load properly\n";
	exit;
    }

    if(defined $defraw) { 
	$defraw_option = 1;
    }

    if(defined $debugfile) { 
	if(-e $debugfile) {
	    print "Debug file $debugfile already exists! Overwrite (Y/N)? ";
	    my $reply = <STDIN>;
	    chomp $reply;
	    $reply = uc $reply;
	    exit 0 if ($reply ne "Y");
	}
	
	open(DEBUG, ">$debugfile") 
	    || die "Could not open debug file: $debugfile\n";
	
	$debug = 1;
    }

    #  Check for stoplist
    if(defined $stoplist) {

	open(STP, $stoplist) || die "Could not open stoplist: $stoplist\n";

	$stopregex  = "(";
	while(<STP>) {
	    chomp;
		if ($_ ne ""){
	    	$_=~s/\///g;
	    	$stopregex .= "$_|";
		}
	}
	chop $stopregex; $stopregex .= ")";
	close STP;

    }


    if(defined $dictfile) { 
	open(DICT, "$dictfile") 
	    || die("Error: cannot open dictionary file ($dictfile)\n");
	
	while(<DICT>) {
	    chomp;
	    if($_=~/^\s*$/) { next; }
	    
	    my @defs = split/\s+/;
	    my $concept = shift @defs;
	    my $definition = join (" ", @defs);
	    
	    if($concept=~/C[0-9]+/) {
		$dictionary{$concept} = $definition;
	    }
	    else {
		my @cuis = $interface->getConceptList($concept);
		foreach my $cui (@cuis) {
		    if(exists $dictionary{$cui}) {
			$dictionary{$cui} .= " " . $definition;
		    }
		    else {
			$dictionary{$cui} = $definition;
		    }
		}
	    }
	}
	close DICT;


    }
    return $self;
}


sub getRelatedness
{
    my $self = shift;
    return undef if(!defined $self || !ref $self);
    my $concept1 = shift;
    my $concept2 = shift;
    
    if(defined $debugfile) { 
	print DEBUG "$concept1<>$concept2\n";
    }

    #  set up the interface
    my $interface = $self->{'interface'};

    my $def1 = ""; 
    my $def2 = ""; 
    
    if(defined $dictfile) { 
	$def1 = $dictionary{$concept1};
	$def2 = $dictionary{$concept2};

	if(defined $debugfile) { 
	    print DEBUG "DEFINITIONS FROM DICTFILE FOR $concept1: \n"; 
	    print DEBUG "1. $def1\n";
	    print DEBUG "DEFINITIONS FROM DICTFILE FOR $concept2: \n"; 
	    print DEBUG "1. $def2\n";
	}
    }
    else {
	#  get the definitions
	my $defs1 = $interface->getExtendedDefinition($concept1);
	my $defs2 = $interface->getExtendedDefinition($concept2);
   
	#  if debug setting is on print out definition one information
	if(defined $debugfile) { print DEBUG "DEFINITIONS FOR $concept1: \n"; }

	#  set up the definition string - note the format is:
	#  CUI REL CUI SAB : <definition>
	my $i = 1;
	foreach my $def (@{$defs1}) {
	    if($debug) { 
		print DEBUG "$i. $def\n"; 
		$i++;
	    }
	    $def=~/(C[0-9]+) ([A-Za-z]+) (C[0-9]+) ([A-Z]+) \s*\:\s*(.*?)$/;
	    #$def1 .= $5 . " "; 
	    $def1 .= $5 . " " . "<stop>" . " "; 
	}

	#  if debug setting is on print out definition two information
	if(defined $debugfile) { print DEBUG "DEFINITIONS FOR $concept2: \n"; }
	
	#  set up the definition string - note the format is:
	#  CUI REL CUI SAB : <definition>
	my $j = 1;    
	foreach my $def (@{$defs2}) {
	    if($debug) { 
		print DEBUG "$j. $def\n"; 
		$j++;
	    }
	    $def=~/(C[0-9]+) ([A-Za-z]+) (C[0-9]+) ([A-Z]+) \s*\:\s*(.*?)$/;
	    #$def2 .= $5 . " "; 
	    $def2 .= $5 . " " . "<stop>" . " "; 
	}
    }

    #  if the --defraw option is not set clean up the defintions
    if($defraw_option == 0) { 
	$def1 = lc($def1); $def2 = lc($def2);

	# remove punctuation doesn't contain '<' and '>'	
	$def1=~s/[\.\,\?\/\'\"\;\:\[\]\{\}\!\@\#\$\%\^\&\*\(\)\-\_\+\-\=]//g;
	$def2=~s/[\.\,\?\/\'\"\;\:\[\]\{\}\!\@\#\$\%\^\&\*\(\)\-\_\+\-\=]//g;
	
    }


	# remove stop words
	my $overlaps = "";
	my $len1 = 0;
	my $len2 = 0;
	if (defined $stoplist)
	{
		my @d1 = split(/\s/, $def1);
		my @d2 = split(/\s/, $def2);
	
		my $new_def1 = "";
		my $new_def2 = "";
		foreach my $check (@d1)
		{
			if(!($check =~ /$stopregex/))
			{
				$new_def1 .= "$check ";		
			}
		}		
			
		foreach my $check (@d2)
		{
			if(!($check =~ /$stopregex/))
			{
				$new_def2 .= "$check ";		
			}
		}		

		if (defined $stem)
		{
			my @def1_words = split(/\s/, $new_def1);
			my @def2_words = split(/\s/, $new_def2);
			my $stemmed_words1 = Lingua::Stem::En::stem({ -words => \@def1_words, -locale => 'en'});	
			my $stemmed_words2 = Lingua::Stem::En::stem({ -words => \@def2_words, -locale => 'en'});	

			my $stem1 = join(" ", @{$stemmed_words1});
			my $stem2 = join(" ", @{$stemmed_words2});

    		#  find the overlap
    		($overlaps, $len1, $len2) = $finder->getOverlaps($stem1, $stem2);
		}
		else
		{
    		#  find the overlap
    		($overlaps, $len1, $len2) = $finder->getOverlaps($new_def1, $new_def2);
		}
	}	
	else
	{
    	#  find the overlap
    	($overlaps, $len1, $len2) = $finder->getOverlaps($def1, $def2);
	}


	#foreach my $overlap (keys %$overlaps) {
    #    print "$overlap occurred $overlaps->{$overlap} times.\n";
    #}
 
    #  calculate lesk on the overlaps which doesn't cross defs 
    my $score = 0;
    foreach my $overlap (keys %{$overlaps}) {
		if ($overlap !~ /\<stop\>/){ 
	    my @array = split/\s+/, $overlap;
	    my $length = $#array + 1;
	    my $num = $overlaps->{$overlap};
	    my $value = $num * ($length**2);
	    $score += $value;
	#	print "$score\n";
		}
	}

    return $score;

}


1;
__END__

=head1 NAME

UMLS::Similarity::lesk - Perl module for computing semantic relatedness
of concepts in the Unified Medical Language System (UMLS) using the 
method described by Banerjee and Pedersen (2002). 

=head1 CITATION

 @article{BanerjeeP03,
  title={An Adapted Lesk Algorithm for Word Sense Disambiguation using WordNet}, 
  author={Banerjee and Pedersen},
  journal={Proceedings of the Third International Conference on Intelligent Text Processiong 
		   and Computational Linguistics},  
  pages={136-145},
  year={2002}
  month={February}
  address={Mexico City}
 }

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::lesk;

  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);

  my $lesk = UMLS::Similarity::lesk->new($umls);
  die "Unable to create measure object.\n" if(!$lesk);

  my $cui1 = "C0005767";
  my $cui2 = "C0007634";

  @ts1 = $umls->getTermList($cui1);
  my $term1 = pop @ts1;

  @ts2 = $umls->getTermList($cui2);
  my $term2 = pop @ts2;

  my $value = $lesk->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

This module computes the semantic relatedness of two concepts in 
the UMLS according to a method described by Banerjee and Pedersen(2002). 
The relatedness measure proposed by Banerjee and Pedersen is and
adaptation of Lesk's dictionary-based word sense disambiguation algorithm.  

--defraw option is a flag for the lesk measure. The definitions 
used are 'cleaned'. If the --defraw flag is set they will not be cleaned, 
and it will leave the definitions in their "raw" form. 

--dictfile option is a dictionary file for the lesk measure. It 
contains the 'definitions' of a concept which would be used rather 
than the definitions from the UMLS. 

--stoplist option is a word list file for the lesk measure. The words
in the file should be removed from the definition. In the stop list file, 
each word is in the regular expression format. A stop word sample file 
is under the samples folder which is called toplist-nsp.regex.

--stem option is a flag for the lesk measure. If we the --stem flag
is set, the words of the definition are stemmed by the the Porter Stemming
algorithm.  


=head1 USAGE

The semantic relatedness modules in this distribution are built as classes
that expose the following methods:
  new()
  getRelatedness()

=head1 TYPICAL USAGE EXAMPLES

To create an object of the lesk measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::lesk;
   $measure = UMLS::Similarity::lesk->new($interface);

The reference of the initialized object is stored in the scalar
variable '$measure'. '$interface' contains an interface object that
should have been created earlier in the program (UMLS-Interface). 

If the 'new' method is unable to create the object, '$measure' would 
be undefined. 

To find the semantic relatedness of the concept 'blood' (C0005767) and
the concept 'cell' (C0007634) using the measure, we would write
the following piece of code:

   $relatedness = $measure->getRelatedness('C0005767', 'C0007634');

=head1 SEE ALSO

perl(1), UMLS::Interface

perl(1), UMLS::Similarity(3)

=head1 CONTACT US

  If you have any trouble installing and using UMLS-Similarity, 
  please contact us via the users mailing list :

      umls-similarity@yahoogroups.com

  You can join this group by going to:

      http://tech.groups.yahoo.com/group/umls-similarity/

  You may also contact us directly if you prefer :

      Bridget T. McInnes: bthomson at cs.umn.edu 

      Ted Pedersen : tpederse at d.umn.edu

=head1 AUTHORS

  Bridget T McInnes <bthomson at cs.umn.edu>
  Siddharth Patwardhan <sidd at cs.utah.edu>
  Serguei Pakhomov <pakh0002 at umn.edu>
  Ted Pedersen <tpederse at d.umn.edu>
  Ying Liu <liux0395 at umn.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2010 by Bridget T McInnes, Siddharth Patwardhan, 
Serguei Pakhomov, Ying Liu and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
