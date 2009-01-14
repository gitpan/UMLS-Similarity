#!/usr/bin/perl 

=head1 NAME

queryUMLS.pl - this program returns a semantic similarity score between two concepts

=head1 SYNOPSIS

This is a utility that takes as input either two terms (DEFAULT) 
or two CUIs and returns the similarity between the two.

=head1 USAGE

Usage: queryUMLS.pl [OPTIONS] TERM1 TERM2

=head1 INPUT

=head2 Optional Arguments:

=head3 --cui

The input for TERM1 and TERM2 are actually CUIs rather than terms

=head3 --username STRING

Username is required to access the umls database on MySql

=head3 --password STRING

Password is required to access the umls database on MySql

=head3 --lch 

Use the module implementing the Leacock and Chodorow (1998) measure

=head3 --path

Use the module implementing the simple edge counting measure of 
semantic relatedness (DEFAULT).

=head3 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head3 --database STRING        

Database contain UMLS DEFAULT: umls

=head4 --help

Displays the quick summary of program options.

=head4 --version

Displays the version information.

=head1 OUTPUT

disambiguate.pl creates two directories. One containing the arff files
and the other containing the weka files. In the weka directory, the 
overall averages are stored in the OverallAverage file.

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=item * UMLS::Interface - http://search.cpan.org/dist/UMLS-Query

=item * UMLS::Similarity - http://search.cpan.org/dist/UMLS-Query

=back

=head1 AUTHOR

 Bridget T. McInnes, University of Minnesota

=head1 COPYRIGHT

Copyright (c) 2007-2008,

 Bridget T. McInnes, University of Minnesota
 bthomson at cs.umn.edu
    
 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to:

 The Free Software Foundation, Inc.,
 59 Temple Place - Suite 330,
 Boston, MA  02111-1307, USA.

=cut

###############################################################################

#                               THE CODE STARTS HERE
###############################################################################

#                           ================================
#                            COMMAND LINE OPTIONS AND USAGE
#                           ================================


use UMLS::Interface;
use UMLS::Similarity::lch;
use UMLS::Similarity::path;

use Getopt::Long;

GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "cui", "lch", "config=s");


#  if help is defined, print out help
if( defined $opt_help ) {
    $opt_help = 1;
    &showHelp();
    exit;
}

#  if version is requested, show version
if( defined $opt_version ) {
    $opt_version = 1;
    &showVersion();
    exit;
}

# At least 2 terms should be given on the command line.
if(scalar(@ARGV) < 2)
{
    print STDERR "At least 2 terms or CUIs should be given on the command line.\n";
    &minimalUsageNotes();
    exit;
}
my $database = "umls";
my $hostname = "localhost";
my $socket   = "/tmp/mysql.sock";

if(defined $opt_database) {
    $database = $opt_database;
}

if(defined $opt_hostname) {
    $hostname = $opt_hostname;
}

if(defined $opt_socket) {
    $socket = $opt_socket;
}

my $measure = "path";
if(defined $opt_lch) {
    $measure = "lch";
}

my $umls = "";
my $lch  = "";
my $path = "";

my @c1 = ();
my @c2 = ();


#  Loading the UMLS

if(defined $opt_username and defined $opt_password and defined $opt_config) {
    $umls = UMLS::Interface->new({"driver" => "mysql", 
				  "database" => "$database", 
				  "username" => "$opt_username",  
				  "password" => "$opt_password", 
				  "hostname" => "$hostname", 
				  "socket"   => "$socket",
			          "config"   => "$opt_config"}); 
    die "Unable to create UMLS::Interface object.\n" if(!$umls);
    ($errCode, $errString) = $umls->getError();
    die "$errString\n" if($errCode);
}
elsif(defined $opt_username and defined $opt_password) {
    $umls = UMLS::Interface->new({"driver" => "mysql", 
				  "database" => "$database", 
				  "username" => "$opt_username",  
				  "password" => "$opt_password", 
				  "hostname" => "$hostname", 
				  "socket"   => "$socket"}); 
    die "Unable to create UMLS::Interface object.\n" if(!$umls);
    ($errCode, $errString) = $umls->getError();
    die "$errString\n" if($errCode);
}
elsif(defined $opt_config) {
    $umls = UMLS::Interface->new({"config" => "$opt_config"});
    die "Unable to create UMLS::Interface object.\n" if(!$umls);
    ($errCode, $errString) = $umls->getError();
    die "$errString\n" if($errCode);
}
else {
    $umls = UMLS::Interface->new(); 
    die "Unable to create UMLS::Interface object.\n" if(!$umls);
    ($errCode, $errString) = $umls->getError();
    die "$errString\n" if($errCode);
}

&errorCheck($umls);

#  Loading the module implementing the Leacock and 
#  Chodorow (1998) measure
$lch = UMLS::Similarity::lch->new($umls);
die "Unable to create measure object.\n" if(!$lch);

($errCode, $errString) = $lch->getError();
die "$errString\n" if($errCode);

$lch->{'trace'} = 1;

#  Loading the module implementing the simple edge counting 
#  measure of semantic relatedness.
$path = UMLS::Similarity::path->new($umls);
die "Unable to create measure object.\n" if(!$path);
($errCode, $errString) = $path->getError();
die "$errString\n" if($errCode);
$path->{'trace'} = 1;

my $input1 = shift;
my $input2 = shift;

#  check if the input are CUIs or terms
if(defined $opt_cui) {
    push @c1, $input1;
    push @c2, $input2;
}
elsif( ($input1=~/C[0-9]+/) || ($input1=~/C[0-9]+/) ) {
    
    print "The input appear to be CUIs. Is this true (y/n)?\n";
    my $answer = <STDIN>; chomp $answer;
    if($answer=~/y/) {
	print "Please specify the --cui option next time.\n";
	push @c1, $input1;
	push @c2, $input2;
    }
    else {
	@c1 = $umls->getConceptList($input1); 
	&errorCheck($umls);
	@c2 = $umls->getConceptList($input2); 
	&errorCheck($umls);
    }
}
else {
    @c1 = $umls->getConceptList($input1); 
    &errorCheck($umls);
    @c2 = $umls->getConceptList($input2); 
    &errorCheck($umls);
}

foreach $cc1 (@c1)
{
    foreach $cc2 (@c2)
    {
	@ts1 = $umls->getTermList($cc1);
	&errorCheck($umls);
	@ts2 = $umls->getTermList($cc2);
	&errorCheck($umls);
	
	($t1) = @ts1;
	($t2) = @ts2;

	my $score = "";
	if($measure eq "lch") {
	    $score = $lch->getRelatedness($cc1, $cc2);
	    &errorCheck($lch);
	}
	else {
	    $score = $path->getRelatedness($cc1, $cc2);
	    &errorCheck($path);
	}

	print "Similarity ($measure) between $cc1 ($t1) and $cc2 ($t2) :  $score\n";
	$printFlag = 1;
    }
}

if(! ($printFlag)) {
    print "The Similarity ($measure) between $input1 and $input2 can\n";
    print "not be calculated given the current view of the UMLS\n\n";
}

sub errorCheck
{
    my $obj = shift;
    ($errCode, $errString) = $obj->getError();
    print STDERR "$errString\n" if($errCode);
    exit if($errCode > 1);
}


##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: queryUMLS.pl [OPTIONS] TERM1 TERM2\n\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {

        
    print "This is a utility that takes as input either two terms (DEFAULT)\n";
    print "or two CUIs and returns the similarity between the two.\n\n";
  
    print "Usage: queryUMLS.pl [OPTIONS] TERM1 TERM2\n\n";

    print "Options:\n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";
    
    print "--cui                    Input are CUIs rather than TERMS\n";
    
    print "--lch                    Use the module implementing the Leacock and\n";
    print "                         Chodorow (1998) measure\n\n";
    
    print "--path                   Use the module implementing the simple edge\n";
    print "                         counting measure of semantic relatedness\n";
    print "                         (DEFAULT).\n\n";

    print "--version                Prints the version number\n\n";
 
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: queryUMLS.pl,v 1.11 2009/01/13 22:20:50 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type queryUMLS.pl --help for help.\n";
}
    
