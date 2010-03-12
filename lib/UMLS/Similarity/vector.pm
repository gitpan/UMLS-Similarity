# UMLS::Similarity::vector.pm
#
# Module implementing the vector semantic relatedness measure 
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
use UMLS::Similarity::def;

use vars qw($VERSION);
$VERSION = '0.01';

my $debug      = 0;
my $matrixfile = "";
my $indexfile  = "";
my $config     = "";
my $defhandler = "";
my %index = ();
my %position =();
my %length = ();

sub new
{
    my $className = shift;

    return undef if(ref $className);

    if($debug) { print STDERR "In UMLS::Similarity::vector->new()\n"; }

    my $interface = shift;
    my $params    = shift;

    $params = {} if(!defined $params);

    $indexfile  = $params->{'indexfile'};
    $matrixfile = $params->{'matrixfile'};
    $config     = $params->{'config'};

    if($debug) {
	print STDERR "INDEX: $indexfile\n";
	print STDERR "MATRIX: $matrixfile\n";
    }

#Ying load the index into hash 
	open(INDX, "<$indexfile")
        or die("Error: cannot open file '$indexfile' for output index.\n");

	while (my $line = <INDX>)
	{
        	chomp($line);
        	my @terms = split(' ', $line);
    
       		$index{$terms[0]} = $terms[1];
        	$position{$terms[1]} = $terms[2]; 
       		$length{$terms[1]} = $terms[3]; 
	}
	close INDX;

#Ying load the index into hash 


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

    #  set the def handler
    my %defoptions = ();
    if(defined $config) {
	$defoptions{"config"} = $config;
    }
    $defhandler = UMLS::Similarity::def->new($interface, \%defoptions);
    
    return $self;
}


sub getRelatedness
{
    my $self = shift;
    return undef if(!defined $self || !ref $self);
    my $concept1 = shift;
    my $concept2 = shift;
    
    my $interface = $self->{'interface'};

    my $defs1 = $defhandler->getDef($concept1);
    my $defs2 = $defhandler->getDef($concept2);
    
    my $def1 = join " ", @{$defs1};
    my $def2 = join " ", @{$defs2};
	
	my $d1 = lc ($def1);
	my $d2 = lc ($def2);	

    #  get the vector for each word in the def

# Ying: get the vector 
	open(MATX, "<$matrixfile")
        or die("Error: cannot open file '$matrixfile' for output index.\n");

	my %vector1 = ();
	my %vector2 = ();
	my @defs1 = split(" ", $d1);	
	my @defs2 = split(" ", $d2);	

        foreach my $def_term1 (@defs1)
        {
		if (defined $index{$def_term1})
		{
			#print "has term1: $def_term1\n";
			my $index_term = $index{$def_term1};
        	        my $p = $position{$index_term};
              		my $l = $length{$index_term};

			if (($p==0) and (!defined $l))
			{
				next;
			}
			else
			{
                		my ($data, $n);
                		seek MATX, $p, 0;
                		if (($n = read MATX, $data, $l) != 0)
                		{
					#print "term1 data: $data\n";
                      			my @word_vector = split (' ', $data);
                        		my $index = shift @word_vector;
                        		$index =~ m/^(\d+)\:$/;

	                        	if ($index_term == $1)
       		                	{
                                		for (my $z=0; $z<@word_vector; )
                                		{
                                      			$vector1{$word_vector[$z]} += $word_vector[$z+1];
							$z += 2;
                                		}
                        		}
                        		else
                        		{
                                		print "$def_term1 is not a correct word!\n";
                                		exit;
                        		}
                		}
			}
		}
        }

        foreach my $def_term2 (@defs2)
        {
		if (defined $index{$def_term2})
		{
			#print "has term2: $def_term2\n";
			my $index_term = $index{$def_term2};
                	my $p = $position{$index_term};
                	my $l = $length{$index_term};

			if (($p==0) and (!defined $l))
			{
				next;
			}
			else
			{
                		my ($data, $n);
                		seek MATX, $p, 0;
                		if (($n = read MATX, $data, $l) != 0)
                		{
                       			my @word_vector = split (' ', $data);
                        		my $index = shift @word_vector;
                        		$index =~ m/^(\d+)\:$/;

                        		if ($index_term == $1)
                        		{
                                		for (my $z=0; $z<@word_vector; )
                                		{
                                      			$vector2{$word_vector[$z]} += $word_vector[$z+1];
							$z += 2;
                                		}
                        		}
                        		else
                        		{
                                		print "$def_term2 is not a correct word!\n";
                                		exit;
                        		}
                		}
			}
		}
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

# Function to return the current trace string
sub getTraceString
{
    my $self = shift;
    return "" if(!defined $self || !ref $self);
    my $returnString = $self->{'traceString'};
    $self->{'traceString'} = "" if($self->{'trace'});
    $returnString =~ s/\n+$/\n/;
    return $returnString;
}


1;
__END__

=head1 NAME

UMLS::Similarity::vector - Perl module for computing semantic relatedness
of concepts in the Unified Medical Language System (UMLS) using the 
method described by Patwardhan (2003). 

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::vector;

  my $option_hash{"matrixfile"} = $matrix_file;
  my $option_hash{"indexfile"}  = $index_file;

  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);
  ($errCode, $errString) = $umls->getError();
  die "$errString\n" if($errCode);

  my $vector = UMLS::Similarity::vector->new($umls, \%option_hash);
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

Perl module for computing semantic relatedness of concepts using second 
order co-occurrence vectors of definitions of the concepts as described 
by Patwardhan (2003), and Patwardhan and Pedersen (2006).

Schütze (1998) creates what he calls context vectors (second order 
co-occurrence vectors) of pieces of text for the purpose of Word Sense
Discrimination. This idea is adopted by Patwardhan and Pedersen to 
represent the concepts by second-order co-occurrence vectors of their 
dictionary definitions. The relatedness of two concepts is then computed 
as the cosine of their representative vectors.

=head1 USAGE

The semantic relatedness modules in this distribution are built as classes
that expose the following methods:
  new()
  getRelatedness()
  getError()
  getTraceString()

See the UMLS::Similarity(3) documentation for details of these methods.

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
  
To get traces for the above computation:

   print $measure->getTraceString();

However, traces must be enabled using configuration files. By default
traces are turned off.

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

Copyright 2004-2009 by Bridget T McInnes, Siddharth Patwardhan, 
Serguei Pakhomov and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
