# UMLS::Similarity::jcn.pm
#
# Module implementing the semantic relatedness measure described 
# by Jiang and Conrath (1997)
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


package UMLS::Similarity::jcn;

use strict;
use warnings;
use UMLS::Similarity;

use vars qw($VERSION);
$VERSION = '0.07';

my $debug = 0;

sub new
{
    my $className = shift;
    
    return undef if(ref $className);

    if($debug) { print STDERR "In UMLS::Similarity::jcn->new()\n"; }

    my $interface = shift;

    my $self = {};
     
    # Bless the object.
    bless($self, $className);
    
    # The backend interface object.
    $self->{'interface'} = $interface;
    
    #  check the configuration file if defined
    my $errorhandler = UMLS::Similarity::ErrorHandler->new("jcn",  $interface);
    if(!$errorhandler) {
	print STDERR "The UMLS::Similarity::ErrorHandler did not load properly\n";
	exit;
    }
    
    return $self;
}


sub getRelatedness
{
    my $self = shift;

    return undef if(!defined $self || !ref $self);

    my $concept1 = shift;
    my $concept2 = shift;
    
    my $interface = $self->{'interface'};
    
    #  get the IC of each of the concepts
    my $ic1 = $interface->getIC($concept1);
    my $ic2 = $interface->getIC($concept2);
    
    #  Check to make certain that the IC for each of the
    #  concepts is greater than zero otherwise return zero
    if($ic1 <= 0 or $ic2 <= 0) { return 0; }

    #  get the lcses of the concepts
    my @lcses = $interface->findLeastCommonSubsumer($concept1, $concept2);
    
    #  get the IC of the lcs witht he lowest IC 
    my $iclcs = 0;
    foreach my $lcs (@lcses) {
	my $value = $interface->getIC($lcs);
	if($iclcs < $value) { $iclcs = $value; }
    }
    
    #  if this is zero just return zero
    if($iclcs == 0) { return 0; }

    #  otherwise calculate the distance
    my $distance = $ic1 + $ic2 - (2 * $iclcs);
    
    #  calculate the similarity score
    my $score = 0;
    if($distance > 0) { 
	$score = 1 / $distance;
    }

    return $score;
}

1;
__END__

=head1 NAME

UMLS::Similarity::jcn - Perl module for computing the semantic 
relatednessof concepts in the Unified Medical Language System 
(UMLS) using the method described by Jiang and Conrath (1997).

=head1 CITATION

 @inproceedings{JiangC97,
  Author = {Jiang, J. and Conrath, D.},
  Booktitle = {Proceedings on International Conference 
               on Research in Computational Linguistics},
  Pages = {pp. 19-33},
  Title = {Semantic similarity based on corpus statistics 
           and lexical taxonomy},
  Year = {1997}
 }

=head1 SYNOPSIS

  use UMLS::Interface;

  use UMLS::Similarity::jcn;

  my $icpropagation = "samples/icpropagation";

  my %option_hash = ();

  $option_hash{"propagation"} = $icpropagation;

  my $umls = UMLS::Interface->new(\%option_hash); 

  die "Unable to create UMLS::Interface object.\n" if(!$umls);

  my $jcn = UMLS::Similarity::jcn->new($umls);

  die "Unable to create measure object.\n" if(!$jcn);

  my $cui1 = "C0005767";

  my $cui2 = "C0007634";

  @ts1 = $umls->getTermList($cui1);

  my $term1 = pop @ts1;

  @ts2 = $umls->getTermList($cui2);

  my $term2 = pop @ts2;

  my $value = $jcn->getRelatedness($cui1, $cui2);

  print "The similarity between $cui1 ($term1) and $cui2 ($term2) is $value\n";

=head1 DESCRIPTION

This module computes the semantic similarity of two concepts in 
the UMLS according to a method described by Jiang and Conrath (1997). 
This measure is based on a combination of using edge counts in the UMLS 
'is-a' hierarchy and using the information content values of the concepts, 
as describedin the paper by Jiang and Conrath. Their measure, however, 
computes values that indicate the semantic distance between words (as 
opposed to their semantic similarity). In this implementation of the 
measure we invert the value so as to obtain a measure of semantic 
relatedness. Other issues that arise due to this inversion (such as 
handling of zero values in the denominator) have been taken care of 
as special cases.

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
in the samples/ directory. 

A propagation file can be created using the create-icfrequency.pl and 
the create-icpropagation.pl programs in the utils/ directory. The 
create-icfrequency.pl program takes plain text and returns a list of 
CUIs that are mapped to the text and the CUIs frequency counts. This 
file can then be used by the create-icpropagation.pl program to create 
a file containing a list of CUIs and their probability counts, or used 
directly by the umls-similarity.pl program which will calculate the 
probability of a concept on the fly. 

=head1 PROPAGATION

The Information Content (IC) is  defined as the negative log 
of the probability of a concept. The probability of a concept, 
c, is determine by summing the probability of the concept 
ocurring in some text plus the probability its decendants 
occuring in some text:

For more information on how this is calculated please see 
the README file. 

=head1 USAGE

The semantic relatedness modules in this distribution are built as classes
that expose the following methods:
  new()
  getRelatedness()

=head1 TYPICAL USAGE EXAMPLES

To create an object of the jcn measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::jcn;
   $measure = UMLS::Similarity::jcn->new($interface);

The reference of the initialized object is stored in the scalar
variable '$measure'. '$interface' contains an interface object that
should have been created earlier in the program (UMLS-Interface). 

If the 'new' method is unable to create the object, '$measure' would 
be undefined. 

To find the semantic relatedness of the concept 'blood' (C0005767) and
the concept 'cell' (C0007634) using the measure, we would write
the following piece of code:

   $relatedness = $measure->getRelatedness('C0005767', 'C0007634');

=head1 CONFIGURATION OPTION

The UMLS-Interface package takes a configuration file to determine 
which sources and relations to use when obtaining the path information.

The format of the configuration file is as follows:

SAB :: <include|exclude> <source1, source2, ... sourceN>

REL :: <include|exclude> <relation1, relation2, ... relationN>

For example, if we wanted to use the MSH vocabulary with only 
the RB/RN relations, the configuration file would be:

SAB :: include MSH
REL :: include RB, RN

or 

SAB :: include MSH
REL :: exclude PAR, CHD

If you go to the configuration file directory, there will 
be example configuration files for the different runs that 
you have performed.

For more information about the configuration options please 
see the README.

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
Serguei Pakhomov, Ying Liu and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
