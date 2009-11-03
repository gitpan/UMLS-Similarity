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

=head3 --infile FILE

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

=head3 --info

Displays information about the concept if it doesn't
exist in the source.

=head3 --dbfile FILE

This is the Berkley DB file that contains the vector information to 
use with the vector measure. This is required if you specify vector 
with the --measure option.

=head3 --allsenses

This option prints out all the possible CUIs pairs and their semantic 
similarity score if one of the inputs is a term that maps to more than 
one CUI. Right now we just return the CUIs that are the most similar.

=head3 --forcerun

This option will bypass any command prompts such as asking 
if you would like to continue with the index creation. 

=head3 --verbose

This option will print out the table information to the 
config file that you specified.

=head3 --help

Displays the quick summary of program options.

=head3 --version

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
use Getopt::Long;

eval(GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "measure=s", "config=s", "infile=s", "dbfile=s", "precision=s", "info", "allsenses", "forcerun", "verbose")) or die ("Please check 
the above mentioned option(s).\n");


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

my @input_array = ();

&setOptions         ();
&loadUMLS           ();

my $meas = &loadMeasures();

&loadInput          ();
&calculateSimilarity();

sub calculateSimilarity {

    if($debug) { print STDERR "In calculateSimilarity\n"; }
    
    foreach my $input (@input_array) {
	my ($input1, $input2) = split/<>/, $input;
	
	if($debug) { print STDERR "INPUT=> $input1 : $input2\n"; }

	my @c1 = ();
	my @c2 = ();
	
	my $cui_flag1 = 0;
	my $cui_flag2 = 0;
	
	#  check if input contains cuis
	if($input1=~/C[0-9]+/) {
	    if($umls->checkConceptExists($input1)) {
		push @c1, $input1;
	    }
	    $cui_flag1 = 1;
	}
	else {
	    @c1 = $umls->getConceptList($input1); 
	    &errorCheck($umls);
	    
	}
	if($input2=~/C[0-9]+/) {
	    if($umls->checkConceptExists($input2)) {
		push @c2, $input2;
	    }
	    $cui_flag2 = 1;
	}
	else {
	    @c2 = $umls->getConceptList($input2); 
	    &errorCheck($umls);
	}

	my $t1 = $input1; my $t2 = $input2;
	
	if($cui_flag1) {
	    my @ts1 = $umls->getTermList($input1);
	    &errorCheck($umls);			
	    ($t1) = @ts1;
	}
	if($cui_flag2) {
	    my @ts2 = $umls->getTermList($input2);
	    &errorCheck($umls);
	    ($t2) = @ts2;
	}
	
	
	if($debug) {
	    print STDERR "$input1:$t1 (@c1)\n";
	    print STDERR "$input2:$t2 (@c2)\n";
	}
	
	my %similarityHash = ();

	#  get the similarity between the concepts
	foreach my $cc1 (@c1) {
	    foreach my $cc2 (@c2) {

		if($debug) { 
		    print STDERR "Obtaining similarity for $cc1 and $cc2\n";
		}
		
		my $score = "";
		$value = $meas->getRelatedness($cc1, $cc2, $t1, $t2);
		&errorCheck($meas);
		$score = sprintf $floatformat, $value;
		
		$similarityHash{$cc1}{$cc2} = $score;
	    }
	}
	
	#  find the maximum score
	#  find the minimum score
	my $max_cc1 = ""; my $max_cc2 = ""; my $max_score = 0;
	my $min_cc1 = ""; my $min_cc2 = ""; my $min_score = 999;
	foreach my $concept1 (sort keys %similarityHash) {
	    foreach my $concept2 (sort keys %{$similarityHash{$concept1}}) {
		if($max_score <= $similarityHash{$concept1}{$concept2}) {
		    $max_score = $similarityHash{$concept1}{$concept2};
		    $max_cc1 = $concept1;
		    $max_cc2 = $concept2;
		}
		if($min_score > $similarityHash{$concept1}{$concept2}) {
		    $min_score = $similarityHash{$concept1}{$concept2};
		    $min_cc1 = $concept1;
		    $min_cc2 = $concept2;
		}
	    }
	}
	
	my $score = 0; my $cc1 = ""; my $cc2 = "";
	if($measure eq "nam") {
	    $score = $min_score; 
	    $cc1   = $min_cc1;
	    $cc2   = $min_cc2;
	}
	else {
	    $score = $max_score;
	    $cc1   = $max_cc1;
	    $cc2   = $max_cc2;
	}
	
	#  print all the concepts and their scores
	if(defined $opt_allsenses) {
	    foreach my $cc1 (sort keys %similarityHash) {
		foreach my $cc2 (sort keys %{$similarityHash{$cc1}}) {
		    if($cui_flag1 and $cui_flag2) { print "$score<>$cc1($t1)<>$cc2($t2)\n";     }
		    elsif($cui_flag1)             { print "$score<>$t1($cc1)<>$input2($cc2)\n"; }
		    elsif($cui_flag2)             { print "$score<>$input1($cc1)<>$t2($cc2)\n"; }
		    else   			  { print "$score<>$input1($cc1)<>$input2($cc2)\n"; }
		}
	    }
	}
	#  print the most similar concepts and the score
	elsif($cc1 ne "" or $cc2 ne "") {
	    if($cui_flag1 and $cui_flag2) { print "$score<>$cc1($t1)<>$cc2($t2)\n";     }
	    elsif($cui_flag1)             { print "$score<>$t1($cc1)<>$input2($cc2)\n"; }
	    elsif($cui_flag2)             { print "$score<>$input1($cc1)<>$t2($cc2)\n"; }
	    else   			  { print "$score<>$input1($cc1)<>$input2($cc2)\n"; }
	}
	#  there were no concepts to print - one of them was missing a similarity score
	else {
	    if($#c1 > -1) {
		foreach my $cc1 (@c1) {
		    if($cuiflag1) { print "$noscore<>$cc1($t1)<>$input2\n"; }
		    else          { print "$noscore<>$t1($cc1)<>$input2\n"; }
		    if($opt_info) { print "    => $input2 does not exist\n"; }
		}
	    }
	    elsif($#c2 > -1) {
		foreach my $cc2 (@c2) {
		    if($cuiflag1) { print "$noscore<>$input1<>$cc2($t2)\n"; }
		    else          { print "$noscore<>$input1<>$t2($cc2)\n"; }
		    if($opt_info) { print "    => $input1 does not exist\n"; }
		}
	    }
	    else {
		print "$noscore<>$input1<>$input2\n";
		if($opt_info) { print "    => $input2 nor $input1 exist\n"; }
	    }		
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
		push @input_array, $_;
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

	my $input = "$i1<>$i2";
	push @input_array, $input;
    }
}

#  load the appropriate measure
sub loadMeasures {
    
    my $meas;

    if($measure eq "vector") {
	require "UMLS/Similarity/vector.pm";
	$meas = UMLS::Similarity::vector->new($umls, $opt_dbfile)
    }
    #  load the module implementing the Leacock and 
    #  Chodorow (1998) measure
    if($measure eq "lch") {
	use UMLS::Similarity::lch;	
	$meas = UMLS::Similarity::lch->new($umls);
    }
    #  loading the module implementing the Wu and 
    #  Palmer (1994) measure
    if($measure eq "wup") {
	use UMLS::Similarity::wup;	
	$meas = UMLS::Similarity::wup->new($umls);
    }    
    #  loading the module implementing the simple edge counting 
    #  measure of semantic relatedness.
    if($measure eq "path") {
	use UMLS::Similarity::path;
	$meas = UMLS::Similarity::path->new($umls);
    }
    #  load the module implementing the Rada, et. al.
    #  (1989) called the Conceptual Distance measure
    if($measure eq "cdist") {
	use UMLS::Similarity::cdist;
	$meas = UMLS::Similarity::cdist->new($umls);
    }
    #  load the module implementing the Nguyen and 
    #  Al-Mubaid (2006) measure
    if($measure eq "nam") {
	use UMLS::Similarity::nam;
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
 
    if(defined $opt_config) {
	$option_hash{"config"} = $opt_config;
    }
    if(defined $opt_forcerun) {
	$option_hash{"forcerun"} = $opt_forcerun;
    }
    if(defined $opt_verbose) {
	$option_hash{"verbose"} = $opt_verbose;
    }
    if(defined $opt_username and defined $opt_password) {
	$option_hash{"driver"}   = "mysql";
	$option_hash{"database"} = $database;
	$option_hash{"username"} = $opt_username;
	$option_hash{"password"} = $opt_password;
	$option_hash{"hostname"} = $hostname;
	$option_hash{"socket"}   = $socket;
    }
    
    $umls = UMLS::Interface->new(\%option_hash); 
    die "Unable to create UMLS::Interface object.\n" if(!$umls);
    ($errCode, $errString) = $umls->getError();
    die "$errString\n" if($errCode);
    
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

    if($measure=~/(path|wup|lch|cdist|nam|vector)/) {
	#  good to go
    }
    else {
	print STDERR "The measure ($opt_measure) is not defined for\n";
	print STDERR "the UMLS-Similarity package at this time.\n\n";
	&minimalUsageNotes();
	exit;
    }   

    # make certain the db file is specified if the vector measure 
    # is being used
    if($measure=~/vector/) {
	if(! (defined $opt_dbfile)) {
	    print "The --dbfile option must be specified when using\n";
	    print "the vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }
	  
    if(defined $opt_verbose) {
	$set .= "  --verbose\n";
    }

    if(defined $opt_info) {
	$set .= "  --verbose\n";
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

    print "--info                   Displays information about a concept if\n";
    print "                         it doesn't exist in the source.\n\n";

    print "--dbfile FILE            Berkely DB file containing the vector\n";
    print "                         information for the vector measure.\n\n";

    print "--allsenses              This option prints out all the possible\n";
    print "                         CUIs pairs and their semantic similarity\n"; 
    print "                         score if one of the inputs is a term that\n"; 
    print "                         maps to more than one CUI. Right now we \n"; 
    print "                         return the CUIs that are the most similar.\n\n";

    print "--forcerun               This option will bypass any command \n";
    print "                         prompts such as asking if you would \n";
    print "                         like to continue with the index \n";
    print "                         creation. \n\n";
    
    print "--verbose                This option prints out the path information\n";
    print "                         to a file in your config directory.\n\n";    
    
    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: umls-similarity.pl,v 1.3 2009/11/03 20:56:54 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type umls-similarity.pl --help for help.\n";
}
    
