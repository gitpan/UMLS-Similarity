# UMLS::Similarity::path.pm
#
# Module implementing the simple edge counting measure of 
# semantic relatedness.
#
# Copyright (c) 2004-2009,
#
# Bridget T McInnes, University of Minnesota, Twin Cities
# bthomson at cs.umn.edu
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


package UMLS::Similarity::path;

use strict;
use warnings;
use UMLS::Similarity;

use vars qw($VERSION);
$VERSION = '0.01';

my $debug = 0;

sub new
{
    my $className = shift;
    return undef if(ref $className);
    
    if($debug) { print STDERR "In UMLS::Similarity::path->new()\n"; }
    
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
	$self->{'errorString'} .= "\nError (UMLS::Similarity::path->new()) - ";
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
    
    my (@path) = $interface->findShortestPath($concept1, $concept2);
    
    if($#path < 0 ) { return 0; }

    return (1/($#path+1));
}

# Method to return recent error/warning condition
sub getError
{
    my $self = shift;
    return (2, "") if(!defined $self || !ref $self);
    
    if($debug) { print STDERR "In UMLS::Similarity::path->getError()\n"; }
    
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

UMLS::Similarity::path - Perl module for computing semantic relatedness
of concepts in the UMLS by simple edge counting. 

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::path;

  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);
  ($errCode, $errString) = $umls->getError();
  die "$errString\n" if($errCode);

  my $path = UMLS::Similarity::path->new($umls);
  die "Unable to create measure object.\n" if(!$path);
  
  my $cui1 = "C0005767";
  my $cui2 = "C0007634";
	
  @ts1 = $umls->getTermList($cui1);
  my $term1 = pop @ts1;

  @ts2 = $umls->getTermList($cui2);
  my $term2 = pop @ts2;

  my $value = $path->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

If the concepts being compared are the same, then the resulting 
relatedness score will be 1.  For example, the score for C0005767 
and C0005767 is 1.

Due to multiple inheritance, it is possible for there to be a tie 
for the shortest path between synsets.  If such a tie occurs, then 
all of the paths that are tied will be printed to the trace string.

The relatedness value returned by C<getRelatedness()> is the 
multiplicative inverse of the path length between the two synsets 
(1/path_length).  This has a slightly subtle effect: it shifts 
the relative magnitude of scores. For example, if we have the 
following pairs of synsets with the given path lengths:

  concept1 concept2: 3
  concept3 concept4: 4
  concept5 concept6: 5

We observe that the difference in the score for concept1-concept2 
and concept3-concept4 is the same as for concept3-concept4 and 
concept5-concept6. When we take the multiplicative inverse of them, 
we get:

  concept1 concept2: .333
  concept3 concept4: .25
  concept5 concept6: .2

Now the difference between the scores for concept3-concept4 is less 
than the difference for concept1-concept2 and concept3-concept4. This 
can have negative consequences when computing correlation coefficients.
It might be useful to compute relatedness as S<max_distance - 
path_length>, where max_distance is the longest possible shortest 
path between two conceps.  The original path length can be easily 
determined by taking the multiplicative inverse of the returned 
relatedness score: S<1/score = 1/(1/path_length) = path_length>. 

If two different terms are given as input to getRelatedness, but 
both terms belong to the same concept, then 1 is returned (e.g.,
car and auto both belong to the same concept).

=head1 USAGE

The semantic relatedness modules in this distribution are built as 
classes that expose the following methods:
  new()
  getRelatedness()
  getError()
  getTraceString()

See the UMLS::Similarity(3) documentation for details of these methods.


=head1 TYPICAL USAGE EXAMPLES

To create an object of the path measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::path;
   $measure = UMLS::Similarity::path->new($interface);

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

=head1 AUTHORS

  Bridget T McInnes <bthomson@cs.umn.edu>
  Siddharth Patwardhan <sidd@cs.utah.edu>
  Serguei Pakhomov <pakhomov.serguei@mayo.edu>
  Ted Pedersen <tpederse@d.umn.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2009 by Bridget T McInnes, Siddharth Patwardhan, 
Serguei Pakhomov and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
