# UMLS::Similarity::def.pm
#
# Module that returns the definitions and related definitions of a concept
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


package UMLS::Similarity::def;

use strict;
use warnings;
use UMLS::Similarity;

use vars qw($VERSION);
$VERSION = '0.01';

my $debug      = 0;

my $term_option= 0;
my $cui_option = 0;
my $par_option = 0;
my $chd_option = 0;
my $sib_option = 0;
my $syn_option = 0;
my $rb_option  = 0;
my $rn_option  = 0;
my $ro_option  = 0;

sub new
{
    my $className = shift;
    
    return undef if(ref $className);

    if($debug) { print STDERR "In UMLS::Similarity::def->new()\n"; }

    my $interface = shift;
    my $params    = shift;

    $params = {} if(!defined $params); 
    
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
	$self->{'errorString'} .= "\nError (UMLS::Similarity::def->new()) - ";
	$self->{'errorString'} .= "An interface object is required.";
	$self->{'error'} = 2;
    }

    # The backend interface object.
    $self->{'interface'} = $interface;

    my $config = $params->{'config'};
    
    my $def_option = 0;
    if(defined $config) {
	open(CONFIG, $config) || die "Could not open config file: $config\n";
	while(<CONFIG>) {
	    chomp;
	    if($_=~/DEF \:\: include (.*)/) {
		my $options = $1;
		my @defs = split/[\,]/, $options;
		foreach my $def (@defs) {
		    $def=~s/\s+//g;
		    if($def eq "PAR") { $par_option = 1; }
		    if($def eq "CHD") { $chd_option = 1; }
		    if($def eq "SIB") { $sib_option = 1; }
		    if($def eq "SYN") { $syn_option = 1; }
		    if($def eq "RO")  { $ro_option  = 1; }
		    if($def eq "RN")  { $rn_option  = 1; }
		    if($def eq "RB")  { $rb_option  = 1; }
		    if($def eq "CUI") { $cui_option = 1; }
		    if($def eq "TERM"){ $term_option= 1; }
		}
		$def_option = 1;
	    }
	}
    }
    if($def_option == 0) {
	$par_option = 1;
	$chd_option = 1;
	$sib_option = 1;
	$syn_option = 1;
	$ro_option  = 1;
	$rn_option  = 1;
	$rb_option  = 1;
	$cui_option = 1;
	$term_option= 1;
    }

    return $self;
}


sub getDef
{
    my $self = shift;
    return undef if(!defined $self || !ref $self);
    my $concept = shift;
    
    my $interface = $self->{'interface'};

    my @defs = ();

    if($par_option == 1) {
	my @parents   = $interface->getRelated($concept, "PAR");
	foreach my $parent (@parents) {
	    my @pardefs = $interface->getCuiDef($parent);
	    @defs = (@defs, @pardefs);
	}
    }
    if($chd_option == 1) {
	my @children   = $interface->getRelated($concept, "CHD");
	foreach my $child (@children) { 
	    my @chddefs = $interface->getCuiDef($child);
	    @defs = (@defs, @chddefs);
	}
    }
    if($sib_option == 1) {
	my @siblings   = $interface->getRelated($concept, "SIB");
	foreach my $sib (@siblings) {
	    my @sibdefs = $interface->getCuiDef($sib);
	    @defs = (@defs, @sibdefs);
	}
    }
    if($syn_option == 1) {
	my @syns   = $interface->getRelated($concept, "SYN");
	foreach my $syn (@syns) {
	    my @syndefs = $interface->getCuiDef($syn);
	    @defs = (@defs, @syndefs);
	}
    }
    if($rb_option == 1) {
	my @rbs    = $interface->getRelated($concept, "RB");
	foreach my $rb (@rbs) {
	    my @rbdefs = $interface->getCuiDef($rb);
	    @defs = (@defs, @rbdefs);
	}
    }
    if($rn_option == 1) {
	my @rns    = $interface->getRelated($concept, "RN");
	foreach my $rn (@rns) {
	    my @rndefs = $interface->getCuiDef($rn);
	    @defs = (@defs, @rndefs);
	}
    }
    if($ro_option == 1) {
	my @ros    = $interface->getRelated($concept, "RO");
	foreach my $ro (@ros) {
	    my @rodefs = $interface->getCuiDef($ro);
	    @defs = (@defs, @rodefs);
	}
    }
    if($cui_option == 1) {
	my @def   = $interface->getCuiDef($concept);
	@defs = (@defs, @def);
    }
    if($term_option == 1) {
	my @terms = $interface->getTermList($concept);
	@defs = (@defs, @terms);
    }

    my @clean_defs = ();
    foreach my $def (@defs) {
	$def=~s/[\.\,\?\'\"\;\:\/\]\[\}\{\!\@\#\$\%\^\&\*\(\)\-\_]//g;
	push @clean_defs, $def;
    }

    return \@clean_defs;

}

# Method to return recent error/warning condition
sub getError
{
    my $self = shift;
    return (2, "") if(!defined $self || !ref $self);

    if($debug) { print STDERR "In UMLS::Similarity::def->getError()\n"; }

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

UMLS::Similarity::def - Perl module for returning the UMLS definition 
of a concept and the definition of its related concepts. 

=head1 SYNOPSIS

  use UMLS::Interface;
  use UMLS::Similarity::def; 

  my $option_hash{"config"} = $config_file;

  my $umls = UMLS::Interface->new(\%option_hash); 
  die "Unable to create UMLS::Interface object.\n" if(!$umls);
  ($errCode, $errString) = $umls->getError();
  die "$errString\n" if($errCode);

   my $handler = UMLS::Similarity::def->new($umls);

   my $def = $handler->getDef('C0005767');

   foreach my $d (@{$def}) { print "$d\n"; }

=head1 DESCRIPTION

This module returns the UMLS definition of a given concept and 
the definition of its related concepts. The definitions are 
specified in the configuration file using the following format:

DEF :: include PAR, CHD, SIB, SYN, RO, RB, RN, CUI, TERM

You are not required to use all of the possible relations but 
the default does contain all of them. 

=head1 USAGE

The semantic relatedness modules in this distribution are built as classes
that expose the following methods:
  new()
  getDef()
  getError()
  getTraceString()

See the UMLS::Similarity(3) documentation for details of these methods.

=head1 TYPICAL USAGE EXAMPLES

To create an object of the def measure, we would have the following
lines of code in the perl program. 

   use UMLS::Similarity::def;
   $handler = UMLS::Similarity::def->new($interface);

The reference of the initialized object is stored in the scalar
variable '$handler'. '$interface' contains an interface object that
should have been created earlier in the program (UMLS-Interface). 

If the 'new' method is unable to create the object, '$measure' would 
be undefined. This, as well as any other error/warning may be tested.

   die "Unable to create object.\n" if(!defined $measure);
   ($err, $errString) = $measure->getError();
   die $errString."\n" if($err);

To find the definition of the concept 'blood' (C0005767) and the 
definition of its related concepts, we would write the following 
piece of code:

   $def = $handler->getDef('C0005767')
  
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
  Ted Pedersen <tpederse at d.umn.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2009 by Bridget T McInnes, Siddharth Patwardhan, 
Serguei Pakhomov and Ted Pedersen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
