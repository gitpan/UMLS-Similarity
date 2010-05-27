# UMLS::Similarity::ErrorHandler
# (Last Updated $Id: ErrorHandler.pm,v 1.5 2010/05/27 19:32:29 btmcinnes Exp $)
#
# Perl module that provides a perl interface to the
# Unified Medical Language System (UMLS)
#
# Copyright (c) 2004-2010,
#
# Bridget T. McInnes, University of Minnesota, Twin Cities
# bthomson at cs.umn.edu
#
# Siddharth Patwardhan, University of Utah, Salt Lake City
# sidd at cs.utah.edu
# 
# Serguei Pakhomov, University of Minnesota, Twin Cities
# pakh0002 at umn.edu
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

package UMLS::Similarity::ErrorHandler;

use Fcntl;
use strict;
use warnings;
use DBI;
use bytes;

my $e1  = "Measure does not support the configuration option (Error Code 1).";
my $e2  = "Missing configuration option (Error Code 2). ";
my $e3  = "Duplicate configuration option (Error Code 3).";

sub _error {

    my $self           = shift;
    my $measure   = shift;
    my $string        = shift;
    my $code         = shift;
    
    my $errorstring = "";
    if($code == 1) { $errorstring = $e1; }
    if($code == 2) { $errorstring = $e2; }
    if($code == 3) { $errorstring = $e3; }
    
    
    print STDERR "ERROR: UMLS::Similarity->$measure\n";
    print STDERR "$errorstring\n";
    print STDERR "$string\n";
    
    exit;
}

#  checks the configuration file for the measure
#  input : $config  <- string containing the configuration file
#          $measure <- string containing the measure name
#  output: 
sub checkConfig {
    my $self      = shift;
    my $measure   = shift;
    my $interface = shift;

    if($measure=~/(path|cdist|nam|wup|lch|jcn|lin|res)/) {
	$self->checkPathBasedMeasures($measure, $interface);
    }
    elsif($measure=~/(vector|lesk)/ ) {
	$self->checkRelatednessMeasures($measure, $interface);
    }
}

#  check the config file with the path-based and IC measures
#  input : config   <- string containing the configuration file
#             meaure <- string containing the measure 
#  output: 
sub   checkPathBasedMeasures {
    
    my $self      = shift;
    my $measure   = shift;
    my $interface = shift;

    my $hash = $interface->getConfigParameters();

    #  set possible options
    my %options = ();
    $options{"SAB"} = 0;
    $options{"REL"} = 0;
   
   #  get the config options
    my $check = 0;
    foreach my $param (sort keys %{$hash}) {
	$check++;
	if(exists $options{$param}) { $options{$param}++; }
	else {
	    my $string = "Option: ($param).\n";
	    $self->_error($measure, $string, 1);
	}
    }
    
    #  if the check is zero there are no parameters so
    #  it is using defaults which is good otherewise 
    #  check to make certain nothing is mising
    if($check != 0) {
	foreach my $param (sort keys %options) {
	    if($options{$param} == 0) {
		my $string = "Option Missing : $param\n";
		$self->_error($measure, $string, 2);
	    }
	    if($options{$param} > 1)  {  
		my $string = "Duplicate Options : $param\n";
		$self->_error($measure, $string, 3);
	    }
	}
    }   
}


#  check the config file with the relatedness measures
#  input : config   <- string containing the configuration file
#             meaure <- string containing the measure 
#  output: 
sub   checkRelatednessMeasures {
    
    my $self      = shift;
    my $measure   = shift;
    my $interface = shift;

    my $hash = $interface->getConfigParameters();

    #  set possible options
    my %options = ();
    $options{"SABDEF"} = 0;
    $options{"RELDEF"} = 0;
   
   #  get the config options
    my $check = 0;
    foreach my $param (sort keys %{$hash}) {
	$check++;
	if(exists $options{$param}) { $options{$param}++; }
	else {
	    my $string = "Option: ($param).\n";
	    $self->_error($measure, $string, 1);
	}
    }

    #  if the check is zero there are no parameters so
    #  it is using defaults which is good otherewise 
    #  check to make certain nothing is mising
    if($check != 0) {
 	foreach my $param (sort keys %options) {
	    if($options{$param} == 0) {
		my $string = "Option Missing : $param\n";
		$self->_error($measure, $string, 2);
	    }
	    if($options{$param} > 1)  {  
		my $string = "Duplicate Options : $param\n";
		$self->_error($measure, $string, 3);
	    }
	}
    }   
}

#  sets up the error handler module
#  input : $parameters <- reference to a hash
#  output: $self
sub new {

    my $self = {};
    my $className = shift;
    my $measure   = shift;
    my $interface = shift;

    # Bless the object.
    bless($self, $className);
    
    #  check the config options
    $self->checkConfig($measure, $interface);
    

    return $self;
}
1;
__END__

=head1 NAME

UMLS::Similarity::ErrorHandler - provides the error 
handling of the configuration files for the measures 
in the UMLS-Similarity package.

=head1 DESCRIPTION

This package provides the error handeling of the configuration 
files for the measures in the UMLS-Similarity package.

For more information please see the UMLS::Similarity.pm 
documentation. 

=head1 SYNOPSIS

  #!/usr/bin/perl

  use UMLS::Similarity::ErrorHandler();

  $errorhandler = UMLS::Similarity::ErrorHandler->new();
  if(! defined $errorhandler) {
    print STDERR "The error handler did not get passed properly.\n";
    exit;
  }

  $concept = "C012";
  $pkg = "Package";
  $function = "function";

  if(! ($errorhandler->_validCui($concept)) ) {
    $errorhandler->_error($pkg, 
                          $function,   
                          "Incorrect input value ($concept)", 
                          6);
  }

=head1 INSTALL

To install the module, run the following magic commands:

  perl Makefile.PL
  make
  make test
  make install

This will install the module in the standard location. You will, most
probably, require root privileges to install in standard system
directories. To install in a non-standard directory, specify a prefix
during the 'perl Makefile.PL' stage as:

  perl Makefile.PL PREFIX=/home/sid

It is possible to modify other parameters during installation. The
details of these can be found in the ExtUtils::MakeMaker
documentation. However, it is highly recommended not messing around
with other parameters, unless you know what you're doing.

=head1 SEE ALSO

http://tech.groups.yahoo.com/group/umls-similarity/

http://search.cpan.org/dist/UMLS-Similarity/

=head1 AUTHOR

Bridget T McInnes <bthomson@cs.umn.edu>
Ted Pedersen <tpederse@d.umn.edu>

=head1 COPYRIGHT

 Copyright (c) 2007-2009
 Bridget T. McInnes, University of Minnesota
 bthomson at cs.umn.edu

 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu

 Siddharth Patwardhan, University of Utah, Salt Lake City
 sidd at cs.utah.edu

 Serguei Pakhomov, University of Minnesota Twin Cities
 pakh0002 at umn.edu

 Ying Liu, University of Minnesota Twin Cities
 liux0395 at umn.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to 

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.
