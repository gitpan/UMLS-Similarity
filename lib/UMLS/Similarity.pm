# UMLS::Similarity.pm version 0.01
# (Updated 07/05/2008 -- Sid)
#
# Perl implementation of semantic relatedness measures.
# 
# This is a stripped down version of Semantic::Similarity
# to be used with UMLS::Interface
#
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

package UMLS::Similarity;

$VERSION = '0.01';

sub new
{
    my $className = shift;
    return undef if(ref $className);

    my $interface = shift;

    my $self = {};

    # Initialize the error string and the error level.
    $self->{'errorString'} = "";
    $self->{'error'} = 0;
    
    # The backend interface object.
    $self->{'interface'} = $interface;
    if(!$interface)
    {
	$self->{'errorString'} .= "\nError (UMLS::Similarity->new()) - ";
	$self->{'errorString'} .= "An interface object is required.";
	$self->{'error'} = 2;
    }

    # Test the interface for required methods...
    if(!(defined $interface->can("exists") && 
	 defined $interface->can("pathsToRoot") &&
	 defined $interface->can("depth")))
    {
	$self->{'errorString'} .= "\nError (UMLS::Similarity->new()) - ";
	$self->{'errorString'} .= "Interface does not provide the required methods.";
	$self->{'error'} = 2;
    }

    # Bless object, initialize it and return it.
    bless($self, $className);
    $self->_initialize(shift) if($self->{'error'} < 2);

    # [trace]
    $self->{'traceString'} = "";
    $self->{'traceString'} .= "UMLS::Similarity object created:\n";
    $self->{'traceString'} .= "trace :: ".($self->{'trace'})."\n" if(defined $self->{'trace'});
    $self->{'traceString'} .= "cache :: ".($self->{'doCache'})."\n" if(defined $self->{'doCache'});
    # [/trace]

    return $self;
}

sub _initialize
{
    my $self = shift;
    return if(!defined $self || !ref $self);

    # Initialize the cache
    $self->{'doCache'}      = 1;
    $self->{'pathCache'}    = ();
    $self->{'lcsCache'}     = ();
    $self->{'traceCache'}   = ();
    $self->{'cacheQ'}       = ();
    $self->{'maxCacheSize'} = 1000;

    # Initialize tracing.
    $self->{'trace'} = 0;
}

sub findShortestPath
{
    my $self = shift;
    return undef if(!defined $self || !ref $self);

    my $concept1 = shift;
    my $concept2 = shift;

    # Initialize traces.
    $self->{'traceString'} = "" if($self->{'trace'});
    
    # Undefined input cannot go unpunished.
    if(!$concept1 || !$concept2) {
	$self->{'errorString'} .= "\nWarning (UMLS::Similarity->findShortestPath()) - ";
	$self->{'errorString'} .= "Undefined input values.";
	$self->{'error'} = 1 if($self->{'error'} < 1);
	return undef;
    }

    #  check that concept1 and concept2 exist
    return undef if(! (defined $self->_checkConceptExists($concept1)));
    return undef if(! (defined $self->_checkConceptExists($concept2)));
    
    my($lcs, $path) = $self->_findShortestPath($concept1, $concept2);
      
    return @{$path};
}   



#  this function finds the shortest path between 
#  two concepts and returns the path. in the process 
#  it determines the least common subsumer for that 
#  path so it returns both
sub _findShortestPath
{
    my $self = shift;
    my $concept1 = shift;
    my $concept2 = shift;

    my $interface = $self->{'interface'};

    my $lcs;
    my @lTrees;
    my @rTrees;
    my %lcsPaths;
    my %lcsLengths;

    # Check the existence of the interface object.
    if(!$interface) {
	$self->{'errorString'} .= "\nError (UMLS::Similarity->_findShortestPath()) - ";
	$self->{'errorString'} .= "An interface is required.";
	$self->{'error'} = 2;
	return undef;
    }
    

    # Now check if the similarity value for these two concepts is,
    # in fact, in the cache... if so return the cached value.
    if($self->{'doCache'} && defined $self->{'pathCache'}->{"${concept1}::$concept2"}) {
	if(defined $self->{'traceCache'}->{"${concept1}::$concept2"}) {
	    $self->{'traceString'} = $self->{'traceCache'}->{"${concept1}::$concept2"} 
	    if($self->{'trace'});
	}
	return ($self->{'lcsCache'}=>{"${concept1}::$concept2"}, 
		$self->{'pathCache'}->{"${concept1}::$concept2"});
    }

    # Now get down to really finding the relatedness of these two.
    # Get the paths to root.
    @lTrees = $interface->pathsToRoot($concept1);
    @rTrees = $interface->pathsToRoot($concept2);

    # [trace]
    if($self->{'trace'}) {
	foreach my $lTree (@lTrees) {
	    $self->{'traceString'} .= "HyperTree: ".(join("  ", @{$lTree}))."\n\n";
	}
	foreach my $rTree (@rTrees) {
	    $self->{'traceString'} .= "HyperTree: ".(join("  ", @{$rTree}))."\n\n";
	}
    }
    # [/trace]

    # Find the shortest path in these trees.
    %lcsLengths = ();
    %lcsPaths   = ();
    foreach $lTree (@lTrees) {
	foreach $rTree (@rTrees) {
	    $lcs = &_getLCSfromTrees($lTree, $rTree);
	    if(defined $lcs) {

		my $lCount  = 0;
		my $rCount  = 0;
		my $length  = 0;
		my $concept = "";

		my $lArray  = ();
		my $rArray  = ();
		
		foreach $concept (reverse @{$lTree}) {
		    $lCount++;
		    push @lArray, $concept;
		    last if($concept eq $lcs);

		}
		foreach $concept (reverse @{$rTree}) {
		    $rCount++;
		    last if($concept eq $lcs);
		    push @rArray, $concept;
		    
		}

		#  length of the path
		$lcsLengths{$lcs} = $rCount + $lCount - 1;
		
                #  the path
		@{$lcsPaths{$lcs}} = (@lArray, (reverse @rArray));
	    }
	}
    }

    # If no paths exist 
    if(!scalar(keys(%lcsPaths))) {
	# [trace]
	if($self->{'trace'}) {
	    $self->{'traceString'} .= "Relatedness 0. No intersecting paths found.\n";
	}
	# [/trace]
	return 0;
    }

    ($lcs) = sort {$lcsLengths{$b} <=> $lcsLengths{$a}} keys(%lcsLengths);
    
    # [trace]
    if($self->{'trace'}) {
	$self->{'traceString'} .= "LCS: $lcs   ";
	$self->{'traceString'} .= "Path length: $lcsLengths{$lcs}.\n\n";
    }
    # [/trace]


    #  set the Cache
    if($self->{'doCache'}) {
	$self->{'pathCache'}->{"${concept1}::$concept2"}  = $lcsPaths{$lcs};
	$self->{'lcsCache'}->{"${concept1}::$concept2"}   = $lcs;
	$self->{'traceCache'}->{"${concept1}::$concept2"} = $self->{'traceString'} 
	if($self->{'trace'});
	push(@{$self->{'cacheQ'}}, "${concept1}::$concept2");
	if($self->{'maxCacheSize'} >= 0) {
	    while(scalar(@{$self->{'cacheQ'}}) > $self->{'maxCacheSize'}) {
		my $delItem = shift(@{$self->{'cacheQ'}});
		delete $self->{'pathCache'}->{$delItem};
		#delete $self->{'lcsCache'}=>{$delItem};
		delete $self->{'traceCache'}->{$delItem};
	    }
	}
    }
    
    return ($lcs, $lcsPaths{$lcs});
}

sub _checkConceptExists {

    my $self    = shift;
    my $concept = shift;

    my $interface = $self->{'interface'};
    
    # Check the existence of the interface object.
    if(!$interface) {
	$self->{'errorString'} .= "\nError (UMLS::Similarity->_checkConceptExists()) - ";
	$self->{'errorString'} .= "An interface is required.";
	$self->{'error'} = 2;
	return undef;
    }
    
    # Security check -- do the input concepts exist?
    if(!($interface->exists($concept))) {
	$self->{'errorString'} .= "\nWarning (UMLS::Similarity->_checkConceptExists()) - ";
	$self->{'errorString'} .= "Concept '$concept1' not present in database.";
	$self->{'error'} = 1 if($self->{'error'} < 1);
	return undef;
    }
    
    return 1;
}

# Subroutine to get the Least Common Subsumer of two
# paths to the root of a taxonomy
sub _getLCSfromTrees
{
    my $array1 = shift;
    my $array2 = shift;
    
    my @tree1 = reverse @{$array1};
    my @tree2 = reverse @{$array2};
    my $tmpString = " ".join(" ", @tree2)." ";

    foreach my $element (@tree1) {
	if($tmpString =~ / $element /) {
	    return $element;
	}
    }

    return undef;
}

1;
__END__


=head1 NAME

UMLS::Similarity - This is a suite of Perl modules that implements a 
number of measures of semantic relatedness. These algorithms use a backend
taxonomy of concepts to generate relatedness scores between concepts.

=head1 SYNOPSIS

  use UMLS::Similarity::path;

  use UMLS::Interface;

=head1 DESCRIPTION

This package consists of Perl modules along with supporting Perl
programs that implement the semantic relatedness measures described by
Leacock & Chodorow (1998) and a simple path based measure.

This package is essentially a re-implementation of the WordNet::Similarity 
and Semantic::Similarity suite of modules. WordNet::Similarity is
tied to the WordNet lexical database. But, suppose we wish to use
these techniques in the domain of medical informatics, for
instance. This re-implementation allows one to replace WordNet with
another domain-specific taxonomy, and use this to find semantic
relatedness of concepts in that domain.

The Perl modules are designed as objects with methods that take as
input two word senses. The semantic relatedness of these word senses
is returned by these methods. A quantitative measure of the degree to
which two word senses are related has wide ranging applications in
numerous areas, such as word sense disambiguation, information
retrieval, etc. For example, in order to determine which sense of a
given word is being used in a particular context, the sense having the
highest relatedness with its context word senses is most likely to be
the sense being used. Similarly, in information retrieval, retrieving
documents containing highly related concepts are more likely to have
higher precision and recall values.

The following sections describe the organization of this software
package and how to use it. A few typical examples are given to help
clearly understand the usage of the modules and the supporting
utilities.

=head1 SEE ALSO

perl(1), UMLS::Similarity::res(3), UMLS::Similarity::path(3)

http://www.cogsci.princeton.edu/~wn

http://www.ai.mit.edu/people/jrennie/WordNet

http://groups.yahoo.com/group/wn-similarity

=head1 AUTHORS
    
  Bridget T McInnes <bthomson@cs.umn.edu>
  Siddharth Patwardhan <sidd@cs.utah.edu>
  Serguei Pakhomov <pakhomov.serguei@mayo.edu>
  Ted Pedersen <tpederse@d.umn.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2009 by Bridget T McInnes, Siddharth Patwardhan, Serguei Pakhomov and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
