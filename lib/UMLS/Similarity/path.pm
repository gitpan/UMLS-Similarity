# UMLS::Similarity::path.pm
#
# This module is a copy of UMLS::Similarity::path.pm version 0.01
# (used as is from Semantic::Similarity)
# (Updated 09/01/2009 -- Bridget)
#
# This module is a copy of Semantic::Similarity::path.pm version 0.01
# (Updated 08/09/2004 -- Sid)
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
    
    return ($#path+1);
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
of word senses by simple edge counting. This is a taxonomy independent
implementation of the algorithm.

=head1 SYNOPSIS

  use UMLS::Similarity::path;

  use WordNet::Interface;

  my $interface = WordNet::Interface->new();

  my $myobj = UMLS::Similarity::path->new($interface);

  my $cui1 = "C0005767";
  my $cui2 = "C0007634";

  my $value = $myobj->getRelatedness($cui1, $cui2);

  ($error, $errorString) = $myobj->getError();

  die "$errorString\n" if($error);
 
  print "Similarity (path) : $cui1 <-> $cui2 = $value\n";

=head1 DESCRIPTION

This module computes the semantic relatedness of word senses by simple
edge counitng in a taxonomy. 

=head1 USAGE

The semantic relatedness modules in this distribution are built as classes
that expose the following methods:
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
should have been created earlier in the program. The interface object
defines methods to access a backend taxonomy (such as UMLS, etc.). 

If the 'new' method is unable to create the object, '$measure' would 
be undefined. This, as well as any other error/warning may be tested.

   die "Unable to create object.\n" if(!defined $measure);
   ($err, $errString) = $measure->getError();
   die $errString."\n" if($err);

To find the sematic relatedness of the concept 'blood' (C0005767) and
the concept 'cell' (C0007634) using the measure, we would write
the following piece of code:

   $relatedness = $measure->getRelatedness('C0005767', 'C0007634');
    
To get traces for the above computation:

   print $measure->getTraceString();

However, traces must be enabled using configuration files. By default
traces are turned off.

=head1 SEE ALSO

perl(1), UMLS::Similarity(3)

http://www.cogsci.princeton.edu/~wn

http://www.ai.mit.edu/people/jrennie/WordNet

http://groups.yahoo.com/group/wn-similarity

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
