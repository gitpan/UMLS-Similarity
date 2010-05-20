# UMLS::Similarity::lin.pm
#
# Module implementing the semantic relatedness measure described 
# by Lin (1997)
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


package UMLS::Similarity::lin;

use strict;
use warnings;
use UMLS::Similarity;

use vars qw($VERSION);
$VERSION = '0.03';

my $debug = 0;

sub new
{
    my $className = shift;
    return undef if(ref $className);

    if($debug) { print STDERR "In UMLS::Similarity::lin->new()\n"; }

    my $interface = shift;

    my $self = {};
    
    # Initialize the error string and the error level.
    $self->{'errorString'} = "";
    $self->{'error'} = 0;
 
   # Bless the object.
    bless($self, $className);
    
    # The backend interface object.
    $self->{'interface'} = $interface;

    if(!$interface)
    {
	$self->{'errorString'} .= "\nError (UMLS::Similarity::lin->new()) - ";
	$self->{'errorString'} .= "An interface object is required.";
	$self->{'error'} = 2;
    }

    # The backend interface object.
    $self->{'interface'} = $interface;
    
    return $self;
}


sub getRelatedness
{
    my $self = shift;
    return undef if(!defined $self || !ref $self);
    my $concept1 = shift;
    my $concept2 = shift;

    #  set up the interface
    my $interface = $self->{'interface'};

    #  get the ic of the concepts
    my $ic1 = $interface->getIC($concept1);
    my $ic2 = $interface->getIC($concept2);

    #  get the lcses
    my @lcses = $interface->findLeastCommonSubsumer($concept1, $concept2);
    
    #  get the ic of the lcs with the lowest ic score
    my $iclcs = 0; my $l = "";
    foreach my $lcs (@lcses) {
	my $value = $interface->getIC($lcs);
	if($iclcs < $value) { $iclcs = $value; $l = $lcs; }
    }
    
    #  if it is zero just return zero
    if($iclcs == 0) { return 0; }



    #  calculate lin
    my $score = 0;
    if($ic1 > 0 and $ic2 > 0) { 
	$score = (2 * $iclcs) / ($ic1 + $ic2);
    }
    
    return $score
}

# Method to return recent error/warning condition
sub getError
{
    my $self = shift;
    return (2, "") if(!defined $self || !ref $self);

    if($debug) { print STDERR "In UMLS::Similarity::lin->getError()\n"; }

    my $dontClear = shift;
    my $error = $self->{'error'};
    my $errorString = $self->{'errorString'};

    if(!(defined $dontClear && $dontClear)) {
	$self->{'error'} = 0;
	$self->{'errorString'} = "";
    }
    $errorString =~ s/^\n//;

    return ($error, $errorString);
}

1;
__END__

=head1 NAME

UMLS::Similarity::lin - Perl module for computing the semantic 
relatednessof concepts in the Unified Medical Language System 
(UMLS) using the method described by Lin (1997).

=head1 CITATION

 @article{Lin97,
  title={{Using syntactic dependency as local context to resolve 
          word sense ambiguity}},
  author={Lin, D.},
  journal={Proceedings of the 35th Annual Meeting of the 
           Association for Computational Linguistics},
  pages={64--71},
  year={1997}
 }

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::lin;

  my $propagation_file = "samples/icpropagation";

  my %option_hash = ();
  $option_hash{"propagation"} = $propagation_file;

  my $umls = UMLS::Interface->new(\%option_hash); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);
  ($errCode, $errString) = $umls->getError();
  die "$errString\n" if($errCode);

  my $lin = UMLS::Similarity::lin->new($umls);
  die "Unable to create measure object.\n" if(!$lin);
  
  my $cui1 = "C0005767";
  my $cui2 = "C0007634";
	
  @ts1 = $umls->getTermList($cui1);
  my $term1 = pop @ts1;

  @ts2 = $umls->getTermList($cui2);
  my $term2 = pop @ts2;

  my $value = $lin->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

This module computes the semantic relatedness of two concepts in 
the UMLS according to a method described by Lin (1998). The 
relatedness measure proposed by Lin is the IC(lcs) / IC(concept1) 
+ IC(concept2). One can observe, then, that the realtedness value 
will be greater-than or equal-to zero and less-than or equal-to one.

If the information content of any of either concept1 or concept2 is zero,
then zero is returned as the relatedness score, due to lack of data.
Ideally, the information content of a synset would be zero only if that
synset were the root node, but when the frequency of a synset is zero,
we use the value of zero as the information content because of a lack
of better alternatives.

The IC of a concept is defined as the negative log of the probabilty 
of the concept. 

To use this measure, a propagation file containing the probability 
of a CUI for each of the CUIs from the source(s) specified in the 
configuration file. The format for this file is as follows:

 C0000039<>0.00003951
 C0000052<>0.00003951
 C0000084<>0.00003951
 C0000096<>0.00003951

A larger of example of this file can be found in the icpropagation file 
in the samples/ directory. In order to create a propagation file given 

A propagation file can be created using the create-propagation-file.pl
program in the utils/ directory. This file will take either a list 
of CUIs with their frequency counts or a raw text file and compute the 
probability of each of the CUIs using the set of source(s) and relations 
specified in the configuration file.


=head1 USAGE

The semantic relatedness modules in this distribution are built as classes
that expose the following methods:
  new()
  getRelatedness()
  getError()

=head1 TYPICAL USAGE EXAMPLES

To create an object of the lin measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::lin;
   $measure = UMLS::Similarity::lin->new($interface);

The reference of the initialized object is stored in the scalar
variable '$measure'. '$interface' contains an interface object that
should have been created earlier in the program (UMLS-Interface). 

If the 'new' method is unable to create the object, '$measure' would 
be undefined. This, as well as any other error/warning may be tested.

   die "Unable to create object.\n" if(!defined $measure);
   ($err, $errString) = $measure->getError();
   die $errString."\n" if($err);

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

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2010 by Bridget T McInnes, Siddharth Patwardhan, 
Serguei Pakhomov and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
