# UMLS::Similarity::vector.pm
#
# Module implementing the vector semantic relatedness measure 
# based on the measure proposed by Patwardhan (2003)
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
# Ying Liu, University of Minnesota
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


package UMLS::Similarity::vector;


use warnings;

use UMLS::Similarity;

use vars qw($VERSION);
$VERSION = '0.01';

my $debug        = 0;
my $defraw_option= 0;

my $vectormatrix = "";
my $vectorindex  = "";
my $debugfile    = "";
my $dictfile     = "";

my %index         = ();
my %reverse_index = ();
my %position      = ();
my %length        = ();
my %dictionary    = ();

local(*DEBUG);

sub new
{
    my $className = shift;

    return undef if(ref $className);

    if($debug) { print STDERR "In UMLS::Similarity::vector->new()\n"; }

    my $interface = shift;
    my $params    = shift;

    $params = {} if(!defined $params);

    $vectorindex  = $params->{'vectorindex'};
    $vectormatrix = $params->{'vectormatrix'};
    $config       = $params->{'config'};
    $dictfile     = $params->{'dictfile'};
    $debugfile	  = $params->{'debugfile'};
    
    my $defraw       = $params->{'defraw'};
    
    if(defined $defraw) { 
	$defraw_option = 1;
    }

    if (defined $dictfile) {
	
	open(DICT, "<$dictfile")
	    or die("Error: cannot open file '$dictfile' for output index.\n");
	
	while(<DICT>) {
	    chomp;

	    if($_=~/^\s*$/) { next; }

	    my @defs = split/ /;
	    my $concept = shift @defs; 
	    my $definition = join (" ", @defs);	

	    $dictionary{$concept} = $definition;	
	}
	close DICT;
    }

    open(INDX, "<$vectorindex")
        or die("Error: cannot open file '$vectorindex' for output index.\n");
    
    while (my $line = <INDX>)
    {
	chomp($line);
	my @terms = split(' ', $line);
	
	$index{$terms[0]} = $terms[1];
	$reverse_index{$terms[1]} = $terms[0];
	$position{$terms[1]} = $terms[2]; 
	$length{$terms[1]} = $terms[3]; 
    }
    close INDX;


    if(defined $debugfile) { 
	if(-e $debugfile) {
	    print "Debug file $debugfile already exists! Overwrite (Y/N)? ";
	    my $reply = <STDIN>;
	    chomp $reply;
	    $reply = uc $reply;
	    exit 0 if ($reply ne "Y");
	}
	
	open(DEBUG, ">$debugfile") || die "Could not open debug file: $debugfile\n";
    }
    
    
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
	$self->{'errorString'} .= "\nError (UMLS::Similarity::vector->new()) - ";
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
    
    my $interface = $self->{'interface'};
        
    my $d1 = "";
    my $d2 = "";
    if (defined $dictfile)
    {
	$d1 = $dictionary{$concept1};
	$d2 = $dictionary{$concept2};
       
	if(defined $debugfile) { 
	    print DEBUG "DEFINITIONS FOR CUI 1: \n";
	    print DEBUG "1. $d1\n";
	    print DEBUG "DEFINITIONS FOR CUI 2: \n";
	    print DEBUG "1. $d2\n";
	}
    }
    else
    {

	my $defs1 = $interface->getExtendedDefinition($concept1);
	my $defs2 = $interface->getExtendedDefinition($concept2);
	
	$d1 = ""; 

	if(defined $debugfile) { print DEBUG "DEFINITIONS FOR CUI 1: \n"; }
	
	my $i = 1;
	foreach my $def (@{$defs1}) {
	    if(defined $debugfile) { 
		print DEBUG "$i. $def\n"; 
		$i++;
	    }
	    $def=~/(C[0-9]+) ([A-Za-z]+) (C[0-9]+) ([A-Z]+) \s*\:\s*(.*?)$/;
	    $d1 .= $5 . " "; 
	}
	
	$d2 = ""; 
	
	if(defined $debugfile) { print DEBUG "DEFINITIONS FOR CUI 2: \n"; }

	my $j = 1;
	foreach my $def (@{$defs2}) {
	    if(defined $debugfile) { 
		print DEBUG "$j. $def\n"; 
		$j++;
	    }
	    $def=~/(C[0-9]+) ([A-Za-z]+) (C[0-9]+) ([A-Z]+) \s*\:\s*(.*?)$/;
	    $d2 .= $5 . " "; 
	}
	
    }
    
    #  if the --defraw option is not set clean up the defintions
    if($defraw_option == 0) { 
	$d1 = lc($d1); $d2 = lc($d2);
	
	$d1=~s/[\.\,\?\/\'\"\;\:\[\]\{\}\!\@\#\$\%\^\&\*\(\)\-\_\+\-\=]//g;
	$d2=~s/[\.\,\?\/\'\"\;\:\[\]\{\}\!\@\#\$\%\^\&\*\(\)\-\_\+\-\=]//g;
	
    }
    
    open(MATX, "<$vectormatrix")
        or die("Error: cannot open file '$vectormatrix' for output index.\n");
    
    my %vector1 = ();
    my %vector2 = ();
    my @defs1 = split(" ", $d1);	
    my @defs2 = split(" ", $d2);	
        
    my $def1_length = 0 ;
    
    foreach my $def_term1 (@defs1)
    {
	if (defined $index{$def_term1})
	{
	    my $index_term = $index{$def_term1};
            my $p = $position{$index_term};
	    my $l = $length{$index_term};
	    
	    if (($p==0) and (!defined $l))
	    {
		next;
	    }
	    else
	    {
		$def1_length++;
		
		my ($data, $n);
		seek MATX, $p, 0;
		if (($n = read MATX, $data, $l) != 0)
		{
		    if (defined $debugfile) {
			print DEBUG "$def_term1: ";
		    }

		    chomp($data);
		    my @word_vector = split (' ', $data);
		    my $index = shift @word_vector;
		    $index =~ m/^(\d+)\:$/;
		    
		    if ($index_term == $1)
		    {
			for (my $z=0; $z<@word_vector; )
			{
			    $vector1{$word_vector[$z]} += $word_vector[$z+1];
			    $z += 2;
			    
			    if (defined $debugfile) { 
				if(defined $word_vector[$z]) {
				    print DEBUG "$reverse_index{$word_vector[$z]} ";
				}
			    } 	
			    
			}
			
			if (defined $debugfile) {
			    print DEBUG "\n";
			} 	
		    }
		    else 
		    {
			print STDERR "$def_term1 is not a correct word!\n";
			exit;
		    }
		}	
	    }
	}
    }
    
    if (defined $debugfile) {
	print DEBUG "def1 length: $def1_length\n";
    } 	
    
    if (defined $debugfile) {
	print DEBUG "def2: $d2\n";
    }
    
    my $def2_length = 0 ;
    foreach my $def_term2 (@defs2)
    {
	if (defined $index{$def_term2})
	{
	    my $index_term = $index{$def_term2};
            my $p = $position{$index_term};
            my $l = $length{$index_term};
	    
	    if (($p==0) and (!defined $l))
	    {
		next;
	    }
	    else
	    {
		$def2_length++;
		
                my ($data, $n);
              	seek MATX, $p, 0;
                if (($n = read MATX, $data, $l) != 0)
                {
		    if (defined $debugfile) {
			print DEBUG "$def_term2: ";
		    }
		    chomp($data);
		    my @word_vector = split (' ', $data);
		    my $index = shift @word_vector;
                    $index =~ m/^(\d+)\:$/;
		    
                    if ($index_term == $1)
		    {
                    	for (my $z=0; $z<@word_vector; )
                        {
			    $vector2{$word_vector[$z]} += $word_vector[$z+1];
			    $z += 2;
			    
			    if (defined $debugfile) {
				if(defined $wordvector[$z]) {
				    print DEBUG "$reverse_index{$word_vector[$z]} ";
				}
			    } 	
			    
                       	}
			
			if (defined $debugfile) {
			    print DEBUG "\n";
			} 	
                    }
                    else
                    {
			print STDERR "$def_term2 is not a correct word!\n";
			exit;
                    }
                }
	    }
	}
    }
    
    
    if (defined $debugfile) {
	print DEBUG "def2_length: $def2_length\n";
    } 	
    
    
    #  normalize
    my $vec1 = &norm(\%vector1);
    my $vec2 = &norm(\%vector2);
    
    #  cosine
    my $score = &_inner($vec1, $vec2);
    
    return $score;
}

# Subroutine to normalize a vector.
sub norm
{
    my $vec = shift;
    my $out = {};
    my $lent = 0;
    my $ind = 0;

    return {} if(!defined $vec);
    foreach $ind (keys %{$vec})
    {
	$lent += (($vec->{$ind}) * ($vec->{$ind}));
    }
    $lent = sqrt($lent);
    if($lent)
    {
	foreach $ind (keys %{$vec})
	{
	    $out->{$ind} = $vec->{$ind}/$lent;
	}    
    }

    return $out;
}


# Subroutine to find the dot-product of two vectors.
sub _inner
{
    my $a = shift;
    my $b = shift;
    my $ind;
    my $dotProduct = 0;

    return 0 if(!defined $a || !defined $b);
    foreach $ind (keys %{$a})
    {
	$dotProduct += $a->{$ind} * $b->{$ind} if(defined $a->{$ind} && defined $b->{$ind});
    }

    return $dotProduct;
}

# Method to return recent error/warning condition
sub getError
{
    my $self = shift;
    return (2, "") if(!defined $self || !ref $self);

    if($debug) { print STDERR "In UMLS::Similarity::vector->getError()\n"; }

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

UMLS::Similarity::vector - Perl module for computing semantic relatedness
of concepts in the Unified Medical Language System (UMLS) using the 
method described by Resnik 1995.

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::vector;

  my $vectormatrix = "samples/vectormatrix";
  my $vectorindex  = "samples/vectorindex";


  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);
  ($errCode, $errString) = $umls->getError();
  die "$errString\n" if($errCode);

  $vectoroptions{"vectormatrix"} = $vectormatrix;
  $vectoroptions{"vectorindex"} = $vectorindex;
  
  my $vector = UMLS::Similarity::vector->new($umls, \%vectoroptions);
  die "Unable to create measure object.\n" if(!$vector);
  
  my $cui1 = "C0005767";
  my $cui2 = "C0007634";
	
  @ts1 = $umls->getTermList($cui1);
  my $term1 = pop @ts1;

  @ts2 = $umls->getTermList($cui2);
  my $term2 = pop @ts2;

  my $value = $vector->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";


=head1 DESCRIPTION

This module computes the semantic relatedness of two concepts in 
the UMLS according to a method described by Resnik (1995). The 
relatedness measure proposed by Resnik is the information content 
of the least common subsumer of the two concepts. 

=head1 USAGE

The semantic relatedness modules in this distribution are built as classes
that expose the following methods:
  new()
  getRelatedness()
  getError()

=head1 TYPICAL USAGE EXAMPLES

To create an object of the vector measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::vector;
   $measure = UMLS::Similarity::vector->new($interface);

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
  Ying Liu <liux0935 at umn.edu> 

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2010 by Bridget T McInnes, Siddharth Patwardhan, 
Serguei Pakhomov, Ying Liu and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
