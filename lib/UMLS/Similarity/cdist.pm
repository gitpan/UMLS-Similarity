# UMLS::Similarity::cdist.pm
#
# Module implementing the simple edge counting measure of 
# semantic relatedness proposed by Rada, et. al. (1989).
#
# Copyright (c) 2004-2010,
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


package UMLS::Similarity::cdist;

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
    
    if($debug) { print STDERR "In UMLS::Similarity::cdist->new()\n"; }
    
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
	$self->{'errorString'} .= "\nError (UMLS::Similarity::cdist->new()) - ";
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
    
    #  get the shortest path between the concepts
    my (@paths) = $interface->findShortestPath($concept1, $concept2);
    
    #  if there are no paths return nothing
    if($#paths < 0) { return; }
    
    #  otherwise get the path length
    my $pathstring = shift @paths;
    my @path = split/\s+/, $pathstring;

    #  and return it
    if($#path < 0 ) { return 0; }
    return $#path;
}

# Method to return recent error/warning condition
sub getError
{
    my $self = shift;
    return (2, "") if(!defined $self || !ref $self);
    
    if($debug) { print STDERR "In UMLS::Similarity::cdist->getError()\n"; }
    
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

UMLS::Similarity::cdist - Perl module for computing semantic relatedness
of concepts in the UMLS by simple edge counting proposed by Rada, et. al. 
(1989).

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::cdist;

  my $umls = UMLS::Interface->new(); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);
  ($errCode, $errString) = $umls->getError();
  die "$errString\n" if($errCode);

  my $cdist = UMLS::Similarity::cdist->new($umls);
  die "Unable to create measure object.\n" if(!$cdist);
  
  my $cui1 = "C0005767";
  my $cui2 = "C0007634";
	
  @ts1 = $umls->getTermList($cui1);
  my $term1 = pop @ts1;

  @ts2 = $umls->getTermList($cui2);
  my $term2 = pop @ts2;

  my $value = $cdist->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

If the concepts being compared are the same, then the resulting 
similarity score will be 1.  For example, the score for C0005767 
and C0005767 is 1.

The relatedness value returned by C<getRelatedness()> is the 
number of edges between the two concepts.

=head1 USAGE

The semantic relatedness modules in this distribution are built as 
classes that expose the following methods:
  new()
  getRelatedness()
  getError()

=head1 TYPICAL USAGE EXAMPLES

To create an object of the cdist measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::cdist;
   $measure = UMLS::Similarity::cdist->new($interface);

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
