#!/usr/bin/perl 

=head1 NAME

umls-similarity.pl - This program returns a semantic similarity score between two concepts.

=head1 SYNOPSIS

This is a utility that takes as input either two terms (DEFAULT) 
or two CUIs and returns the similarity between the two.

=head1 USAGE

Usage: umls-similarity.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]

=head1 INPUT

=head3 [CUI1|TERM1] [CUI2|TERM2]

The input are two terms or two CUIs associated to concepts in the UMLS. 

=head2 Optional Arguments:

=head3 --inputfile FILE

A file containing pairs of concepts or terms in the following format:

    term1<>term2 
    
    or 

    cui1<>cui2

    or 

    cui1<>term2

    or 

    term1<>cui2

=head3 --username STRING

Username is required to access the umls database on MySql

=head3 --password STRING

Password is required to access the umls database on MySql

=head3 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head3 --database STRING        

Database contain UMLS DEFAULT: umls

=head3 --measure MEASURE

Use the MEASURE module to calculate the semantic similarity. The 
available measure are: 
    1. Leacock and Chodorow (1998) refered to as lch
    2. Wu and Palmer (1994) refered to as  wup
    3. The basic path measure refered to as path
    4. Rada, et. al. (1989) refered to as cdist
    5. Nguyan and Al-Mubaid (2006) refered to as nam

=head3 --precision N

Displays values upto N places of decimal.

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

=item * UMLS::Interface - http://search.cpan.org/dist/UMLS-Interface

=item * UMLS::Similarity - http://search.cpan.org/dist/UMLS-Similarity

=back

=head1 CONTACT US
   
  If you have any trouble installing and using UMLS-Similarity, 
  please contact us via the users mailing list :
    
      umls-similarity@yahoogroups.com
     
  You can join this group by going to:
    
      http://tech.groups.yahoo.com/group/umls-similarity/
     
  You may also contact us directly if you prefer :
    
      Bridget T. McInnes: bthomson at cs.umn.edu 

      Ted Pedersen : tpederse at d.umn.edu

=head1 AUTHOR

 Bridget T. McInnes, University of Minnesota

=head1 COPYRIGHT

Copyright (c) 2007-2009,

 Bridget T. McInnes, University of Minnesota
 bthomson at cs.umn.edu
    
 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu


 Siddharth Patwardhan, University of Utah, Salt Lake City
 sidd@cs.utah.edu
 
 Serguei Pakhomov, University of Minnesota Twin Cities
 pakh0002@umn.edu

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

use lib "/export/scratch/programs/lib/site_perl/5.8.7/";

use UMLS::Interface;
use UMLS::Similarity::lch;
use UMLS::Similarity::path;
use UMLS::Similarity::wup;
use UMLS::Similarity::cdist;
use UMLS::Similarity::nam;

use Getopt::Long;

GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "measure=s", "config=s", "infile=s", "precision=s");

my $debug = 0;

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
if( !(defined $opt_infile) and (scalar(@ARGV) < 2) ) {
    print STDERR "At least 2 terms or CUIs should be given on the \n";
    print STDERR "command line or use the --infile option\n";
    &minimalUsageNotes();
    exit;
}

#  initialize variables
my $precision   = "";
my $floatformat = "";
my $database    = "";
my $hostname    = "";
my $socket      = "";    
my $measure     = "";
my $umls        = "";
my $noscore     = "";
my $infile      = "";

my %input_hash  = ();

&setOptions         ();
&loadUMLS           ();

my $meas = &loadMeasures();

&loadInput          ();
&calculateSimilarity();

sub calculateSimilarity {

    if($debug) { print STDERR "In calculateSimilarity\n"; }

    foreach my $input1 (sort keys %input_hash) {
	foreach my $input2 (sort keys %{$input_hash{$input1}}) {

	    if($debug) { print STDERR "INPUT=> $input1 : $input2\n"; }

	    my @c1 = ();
	    my @c2 = ();
	    
	    my $cui_flag1 = 0;
	    my $cui_flag2 = 0;

	    #  check if input contains cuis
	    if($input1=~/C[0-9]+/) {
		push @c1, $input1;
		$cui_flag1 = 1;
	    }
	    else {
		@c1 = $umls->getConceptList($input1); 
		&errorCheck($umls);
		
	    }
	    if($input2=~/C[0-9]+/) {
		push @c2, $input2;
		$cui_flag2 = 1;
	    }
	    else {
		@c2 = $umls->getConceptList($input2); 
		&errorCheck($umls);
	    }
	    
	    if($debug) {
		print STDERR "$input1 (@c1)\n";
		print STDERR "$input2 (@c2)\n";
	    }

	    #  get the similarity between the concepts
	    foreach $cc1 (@c1) {
		foreach $cc2 (@c2) {
		    
		    my $t1 = $input1; my $t2 = $input2;
		    if($cui_flag1) {
			my @ts1 = $umls->getTermList($cc1);
			&errorCheck($umls);			
			($t1) = @ts1;
		    }
		    if($cui_flag2) {
			my @ts2 = $umls->getTermList($cc2);
			&errorCheck($umls);
			($t2) = @ts2;
		    }
		    
		    if(! ($umls->checkConceptExists($cc1)) ) {
			if($cui_flag) { print "$noscore<>$t1<>$t2\n"; }
			else          { print "$noscore<>$input1<>$input2\n"; }
			$printFlag = 1;
			next;
		    }
		    if(! ($umls->checkConceptExists($cc2)) ) {
			if($cui_flag) { print "$noscore<>$t1<>$t2\n"; }
			else          { print "$noscore<>$input1<>$input2\n"; }
			$printFlag = 1;
			next;
		    }
		    
		    if($debug) { 
			print STDERR "Obtaining similarity for $cc1 and $cc2\n";
		    }
		    
		    my $score = "";
		    $value = $meas->getRelatedness($cc1, $cc2);
		    &errorCheck($meas);
		    $score = sprintf $floatformat, $value;
		    
		    if($cui_flag) { print "$score<>$t1($cc1)<>$t2($cc2)\n"; }
		    else          { print "$score<>$input1($cc1)<>$input2($cc2)\n"; }
		    
		    $printFlag = 1;
		}
	    }
	    
	    if(! ($printFlag)) {
		print "$noscore<>$input1<>$input2\n";
	    } $printFlag = 0;
	}
    }
}

sub loadInput {

    if($debug) { print STDERR "In loadInput\n"; }
    #  if file is defined get the terms or cuis from the input file
    if(defined $opt_infile) {

	if($debug) { print STDERR "FILE ($opt_infile) DEFINED\n"; }

	open(FILE, $infile) || die "Could not open file: $infile\n";
	my $linecounter = 1;
	while(<FILE>) {
	    chomp;
	    if($_=~/^\s*$/) { next; }
	    if($_=~/\<\>/) {
		my ($i1, $i2) = split/<>/;
		$input_hash{$i1}{$i2}++;
	    }
	    else {
		print STDERR "There is an error in the input file ($infile)\n";
		print STDERR "one line $linecounter. The input is not in the\n";
		print STDERR "correct format. Here is the input line:\n";
		print STDERR "$_\n\n";
		exit;
	    }
	}
    }
    # otherwise get them from the command line

    else {
	if($debug) { print STDERR "Command Line terms/cuis defined\n"; }
	
	my $i1 = shift @ARGV;
	my $i2 = shift @ARGV;

	if($debug) { print STDERR "INPUT:  $i1 $i2\n"; }

	$input_hash{$i1}{$i2}++;
    }
}

#  load the appropriate measure
sub loadMeasures {
    
    my $meas;

    #  load the module implementing the Leacock and 
    #  Chodorow (1998) measure
    if($measure eq "lch") {
	$meas = UMLS::Similarity::lch->new($umls);
    }
    #  loading the module implementing the Wu and 
    #  Palmer (1994) measure
    if($measure eq "wup") {
	$meas = UMLS::Similarity::wup->new($umls);
    }    
    #  loading the module implementing the simple edge counting 
    #  measure of semantic relatedness.
    if($measure eq "path") {
	$meas = UMLS::Similarity::path->new($umls);
    }
    #  load the module implementing the Rada, et. al.
    #  (1989) called the Conceptual Distance measure
    if($measure eq "cdist") {
	$meas = UMLS::Similarity::cdist->new($umls);
    }
    #  load the module implementing the Nguyen and 
    #  Al-Mubaid (2006) measure
    if($measure eq "nam") {
	$meas = UMLS::Similarity::nam->new($umls);
    }

    die "Unable to create measure object.\n" if(!$meas);
    ($errCode, $errString) = $meas->getError();
    die "$errString\n" if($errCode);
    $meas->{'trace'} = 1;
    
    return $meas;
}

#  load the UMLS
sub loadUMLS {
 
    if(defined $opt_username and defined $opt_config) {
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
    elsif(defined $opt_username) {
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
}

#  set user input and default options
sub setOptions {

    if($debug) { print STDERR "In setOptions\n"; }

    my $default = "";
    my $set     = "";

    #  set file
    if(defined $opt_infile) {
	$infile = $opt_infile;
	$set   .= "  --infile $opt_infile\n";
    }

    if(defined $opt_config) {
	$config = $opt_config;
	$set   .= "  --config $config\n";
    }

    #  set precision
    $precision = 4;
    if(defined $opt_precision) {
	$precision = $opt_precision;
	$set       .= "  --precision $precision\n";
    }
    else {
	$precision = 4;
	$default  .= "  --precision $precision\n";
    }

    if ($precision !~ /^\d+$/) {
	print STDERR "Value for switch --precision should be integer >= 0. Using 4.\n";
	$precision = 4;
	$default  .= "  --precision $precision\n";
    }

    # create the floating point conversion format as required by sprintf!
    $floatformat = join '', '%', '.', $precision, 'f';

    #  set the zero score with appropriate precision
    $noscore = sprintf $floatformat, -1;

    #  set databasee options
    if(defined $opt_username) {

	if(defined $opt_username) {
	    $set     .= "  --username $opt_username\n";
	}
	if(defined $opt_password) {
	    $set     .= "  --password XXXXXXX\n";
	}
	if(defined $opt_database) {
	    $database = $opt_database;
	    $set     .= "  --database $database\n";
	}
	else {
	    $database = "umls";
	    $default .= "  --database $database\n";
	}

	if(defined $opt_hostname) {
	    $hostname = $opt_hostname;
	    $set     .= "  --hostname $hostname\n";
	}
	else {
	    $hostname = "localhost";
	    $default .= "  --hostname $hostname\n";
	}
	
	if(defined $opt_socket) {
	    $socket = $opt_socket;
	    $set   .= "  --socket $socket\n";
	}
	else {
	    $socket   = "/tmp/mysql.sock\n";
	    $default .= "  --socket $socket\n";
	}
    }
    
    #  set the semantic similarity measure to be used
    if(defined $opt_measure) {
	$measure = $opt_measure;
	$set    .= "  --measure $measure\n";
    }
    else {
	$measure  = "path";
	$default .= "  --measure $measure\n";
    }

    if($measure=~/(path|wup|lch|cdist|nam)/) {
	#  good to go
    }
    else {
	print STDERR "The measure ($opt_measure) is not defined for\n";
	print STDERR "the UMLS-Similarity package at this time.\n\n";
	&minimalUsageNotes();
	exit;
    }   

    #  check settings
    if($default eq "") { $default = "  No default settings\n"; }
    if($set     eq "") { $set     = "  No user defined settings\n"; }

    #  print options
    print STDERR "Default Settings:\n";
    print STDERR "$default\n";
    
    print STDERR "User Settings:\n";
    print STDERR "$set\n";
}

sub errorCheck {
    my $obj = shift;
    ($errCode, $errString) = $obj->getError();
    print STDERR "$errString\n" if($errCode);
    exit if($errCode > 1);
}


##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: umls-similarity.pl [OPTIONS] [TERM1 TERM2] [CUI1 CUI2]\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility that takes as input either two terms \n";
    print "or two CUIs from the command line or a file and returns \n";
    print "the similarity between the two using either Leacock and \n";
    print "Chodorow, 1998 (lch), Wu and Palmer, 1994 (wup) or the \n";
    print "basic path measure (path)\n\n";
  
    print "Usage: umls-similarity.pl [OPTIONS] TERM1 TERM2\n\n";

    print "Options:\n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";
        
    print "--infile FILE            File containing TERM or CUI pairs\n\n";
    
    print "--measure MEASURE        The measure to use to calculate the\n";
    print "                         semantic similarity. (DEFAULT: path)\n\n";

    print "--precision N            Displays values upto N places of decimal.\n\n";

    print "--version                Prints the version number\n\n";
 
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: umls-similarity.pl,v 1.22 2009/03/17 16:13:51 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type umls-similarity.pl --help for help.\n";
}
    
