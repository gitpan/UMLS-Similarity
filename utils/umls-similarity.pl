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

=head2 General Options:

=head3 --config FILE

This is the configuration file. There are six configuration options 
that can be used depending on which measure you are using. The 
path, wup, lch, lin, jcn and res measures require the SAB and REL 
options to be set while the vector and lesk measures require the 
SABDEF and RELDEF options. 

The SAB and REL options are used to determine which sources and 
relations the path information is to be obtained from. The format 
of the configuration file is as follows:

SAB :: <include|exclude> <source1, source2, ... sourceN>

REL :: <include|exclude> <relation1, relation2, ... relationN>

For example, if we wanted to use the MSH vocabulary with only 
the RB/RN relations, the configuration file would be:

SAB :: include MSH
REL :: include RB, RN

or 

SAB :: include MSH
REL :: exclude PAR, CHD

The SABDEF and RELDEF options are used to determine the sources 
and relations the extended definition is to be obtained from. 
We call the definition used by the measure, the extended definition 
because this may include definitions from related concepts. 

The format of the configuration file is as follows:

SABDEF :: <include|exclude> <source1, source2, ... sourceN>

RELDEF :: <include|exclude> <relation1, relation2, ... relationN>

For example, if we wanted to use the definitions from MSH vocabulary 
and we only wanted the definition of the CUI and the definitions of the 
CUIs SIB relation, the configuration file would be:

SABDEF :: include MSH
RELDEF :: include CUI, SIB

Note: RELDEF takes any of MRREL relations and two special 'relations':

      1. CUI which refers to the CUIs definition

      2. TERM which refers to the terms associated with the CUI

If you go to the configuration file directory, there will 
be example configuration files for the different runs that 
you have performed.

For more information about the configuration options (including the 
RELA and RELADEF options) please see the README.

=head3 --realtime

This option will not create a database of the path information
for all of concepts in the specified set of sources and relations 
in the config file but obtain the information for just the 
input concept

=head3 --forcerun

This option will bypass any command prompts such as asking 
if you would like to continue with the index creation. 

=head3 --measure MEASURE

Use the MEASURE module to calculate the semantic similarity. The 
available measure are: 
    1. Leacock and Chodorow (1998) referred to as lch
    2. Wu and Palmer (1994) referred to as  wup
    3. The basic path measure referred to as path
    4. Rada, et. al. (1989) referred to as cdist
    5. Nguyan and Al-Mubaid (2006) referred to as nam
    6. Resnik (1996) referred to as res
    7. Lin (1988) referred to as lin
    8. Jiang and Conrath (1997) referred to as jcn
    9. The vector measure referred to as vector

=head3 --precision N

Displays values up to N places of decimal.

=head3 --allsenses

This option prints out all the possible CUIs pairs and their semantic 
similarity score if one of the inputs is a term that maps to more than 
one CUI. Right now we just return the CUIs that are the most similar.

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.

=head2 Input Options:

=head3 --infile FILE

A file containing pairs of concepts or terms in the following format:

    term1<>term2 
    
    or 

    cui1<>cui2

    or 

    cui1<>term2

    or 

    term1<>cui2

Unless the --matrix option is chosen then it is just a list of CUIS:
    cui1
    cui2
    cui3 
    ...


=head3 --matrix

This option returns a matrix of similarity scores given a file 
containing a list of CUIs. The file is passed using the --infile
option

=head2 Debug Options: 

=head3 --debug

Sets the UMLS-Interface debug flag on for testing

=head3 --info

Displays information about the concept if it doesn't
exist in the source.

=head3 --verbose

This option will print out the table information to the 
config file that you specified.


=head2 Database Options:

=head3 --username STRING

Username is required to access the umls database on mysql

=head3 --password STRING

Password is required to access the umls database on mysql

=head3 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head3 --database STRING        

Database contain UMLS DEFAULT: umls

=head2 IC Measure Options:

=head3 --icpropagation FILE

FILE containing the propagation counts of the CUIs. This file must be 
in the following format:

    CUI<>probability

where probability is the probability of the concept occurring. 

See create-icpropagation.pl for more information.

=head3 --icfrequency FILE

FILE containing frequency counts of CUIs. This file must be in the following 
format: 

    CUI<>freq

where freq is the frequency in which the concept occurred in some text. 

See create-icfrequency.pl for more information.

=head3 --smooth

Incorporate Laplace smoothing, where the frequency count of each of the 
concepts in the taxonomy is incremented by one. The advantage of 
doing this is that it avoids having a concept that has a probability 
of zero. The disadvantage is that it can shift the overall probability 
mass of the concepts from what is actually seen in the corpus. 

This can only be used in conjunction with the --icfrequency options

=head2 Vector Measure Options:

=head3 --vectormatrix FILE

This is the matrix file that contains the vector information to 
use with the vector measure. This is required if you specify vector 
with the --measure option. 

This file is generated by the vector-input.pl program. An example 
of this file can be found in the samples/ directory and is called 
matrix.

=head3 --vectorindex FILE

This is the index file that contains the vector information to 
use with the vector measure. This is required if you specify vector 
with the --measure option.

This file is generated by the vector-input.pl program. An example 
of this file can be found in the samples/ directory and is called 
index.

=head3 --debugfile FILE

This prints the vector information to file, FILE, for debugging 
purposes.

=head3 --dictfile FILE

This is a dictionary file for the vector measure. It contains 
the 'definitions' of a concept (or term) which would be used 
rather than the definitions from the UMLS. 

The format of this file is:

CUI <definition>
CUI <definition>
TERM <definition> 
TERM <definition>

If using TERM, the term is mapped to concepts in the UMLS and 
the terms definition is used as their definitions. If more than 
one term in the dictfile maps to a concept, all of the definitions 
are used. 

Keep in mind, when using this file, if one of the CUIs that you 
are obtaining the similarity for does not exist in the file the 
vector will be empty which will lead to strange similarity scores.

An example of this file can be found in the samples/ directory and 
is called dictfile.


=head3 --defraw

This is a flag for the vector measures. The definitions 
used are 'cleaned'. If the --defraw flag is set they will not be 
cleaned. 

=head3 --stoplist FILE

A file containing a list of words to be excluded from the features 
in the vector method. The format required is one stopword per line, 
words are in the regular expression format. 
For example:

/\b[a-zA-Z]\b/
/\b[aA]board\b/
/\b[aA]bout\b/
/\b[aA]bove\b/
/\b[aA]cross\b/
/\b[aA]fter\b/
/\b[aA]gain\b/

The sample file, stoplist-nsp.regex, is under the samples directory.
...

=head3 --stem 

This is a flag for the vector and lesk method. If the --stem flag is set, 
words are stemmed. 


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

use UMLS::Interface;
use Getopt::Long;

eval(GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "measure=s", "config=s", "infile=s", "matrix", "dbfile=s", "precision=s", "info", "allsenses", "forcerun", "debug", "verbose", "icfrequency=s", "smooth", "icpropagation=s", "realtime", "stoplist=s", "stem", "debugfile=s", "vectormatrix=s", "vectorindex=s", "defraw", "dictfile=s", "t")) or die ("Please check the above mentioned option(s).\n");


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
my $icpropagation = "";
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

&checkOptions       ();
&setOptions         ();
&loadUMLS           ();

my $meas = &loadMeasures();

&loadInput          ();
&calculateSimilarity();

sub calculateSimilarity {

    if($debug) { print STDERR "In calculateSimilarity\n"; }
    
    if(defined $opt_matrix) { print "@input_array\n"; }

    my @secondary_array = @input_array;
    foreach my $input1 (@input_array) {
	

	if(! (defined $opt_matrix) ) {
	    my ($i1, $i2) = split/<>/, $input1;
	    $i1=~s/^\s+//g;	    $i2=~s/\s+$//g;
	    $i1=~s/^\s+//g;	    $i2=~s/\s+$//g;

	    $input1 = $i1;
	    @secondary_array = ();
	    push @secondary_array, $i2;
	}
	else {
	    print "$input1 ";
	}

	foreach $input2 (@secondary_array) {	
	    if($debug) { print STDERR "INPUT=> $input1 : $input2\n"; }
	    
	    my @c1 = ();
	    my @c2 = ();
	    
	    my $cui_flag1 = 0;
	    my $cui_flag2 = 0;
	    
	    #  check if input contains cuis
	    if($input1=~/C[0-9]+/) {
		if($umls->exists($input1)) {
		    push @c1, $input1;
		}
		$cui_flag1 = 1;
	    }
	    else {
		@c1 = $umls->getConceptList($input1); 
	    }
	    if($input2=~/C[0-9]+/) {
		if($umls->exists($input2)) {
		    push @c2, $input2;
		}
		$cui_flag2 = 1;
	    }
	    else {
		@c2 = $umls->getConceptList($input2); 
	    }
	    
	    my $t1 = $input1; my $t2 = $input2;
	    
	    if($cui_flag1) {
		my @ts1 = $umls->getTermList($input1);
		($t1) = @ts1;
	    }
	    if($cui_flag2) {
		my @ts2 = $umls->getTermList($input2);
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

	    #  print the matrix
	    if(defined $opt_matrix) { print "$score "; }
	    #  print all the concepts and their scores
	    elsif(defined $opt_allsenses) {
		foreach my $cc1 (sort keys %similarityHash) {
		    foreach my $cc2 (sort keys %{$similarityHash{$cc1}}) {
			if($cui_flag1 and $cui_flag2) { print "$score<>$cc1($t1)<>$cc2($t2)\n";     }
			elsif($cui_flag1)             { print "$score<>$t1($cc1)<>$input2($cc2)\n"; }
			elsif($cui_flag2)             { print "$score<>$input1($cc1)<>$t2($cc2)\n"; }
			else      		      { print "$score<>$input1($cc1)<>$input2($cc2)\n"; }
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
	#  if the matrix is defined - print a new line
	if(defined $opt_matrix) { print "\n"; }
    }
   
}

sub loadInput {
    
    if($debug) { print STDERR "In loadInput\n"; }
    
    #  if file and matrix is defined get the cuis from the input file
    if( (defined $opt_infile) && (defined $opt_matrix) ) {

	if($debug) { print STDERR "FILE ($opt_infile) DEFINED\n"; }

	open(FILE, $infile) || die "Could not open file: $infile\n";
	my $linecounter = 1;
	while(<FILE>) {
	    chomp;
	    if($_=~/^\s*$/) { next; }
	    if($_=~/C[0-9]+/) {
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
    
    #  if file is defined get the terms or cuis from the input file
    elsif(defined $opt_infile) {

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

	my %vectoroptions = ();
	
	if(defined $opt_dictfile) {
	    $vectoroptions{"dictfile"} = $opt_dictfile;
	}
	if(defined $opt_vectorindex) {
	    $vectoroptions{"vectorindex"} = $opt_vectorindex;
	}
	if(defined $opt_debugfile) {
	    $vectoroptions{"debugfile"} = $opt_debugfile;
	}
	if(defined $opt_vectormatrix) {
	    $vectoroptions{"vectormatrix"} = $opt_vectormatrix;
	}
	if(defined $opt_config) {
	    $vectoroptions{"config"} = $opt_config;
	}
	if(defined $opt_defraw) { 
	    $vectoroptions{"defraw"} = $opt_defraw;
	}
	if(defined $opt_stoplist) {
	    $vectoroptions{"stoplist"} = $opt_stoplist;
	}
	if(defined $opt_stem) {
	    $vectoroptions{"stem"} = $opt_stem;
	}

	$meas = UMLS::Similarity::vector->new($umls,\%vectoroptions);
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
    #  load the module implementing the Resnik (1995) measure
    if($measure eq "res") {
	use UMLS::Similarity::res;
	$meas = UMLS::Similarity::res->new($umls);
    }
    #  load the module implementing the Jiang and Conrath 
    #  (1997) measure
    if($measure eq "jcn") {
	use UMLS::Similarity::jcn;
	$meas = UMLS::Similarity::jcn->new($umls);
    }
    #  load the module implementing the Lin (1998) measure
    if($measure eq "lin") {
	use UMLS::Similarity::lin;
	$meas = UMLS::Similarity::lin->new($umls);
    }
    #  load the module implementing the random measure
    if($measure eq "random") {
	use UMLS::Similarity::random;
	$meas = UMLS::Similarity::random->new($umls);
    }
    
    #  load the module implementing the lesk measure

    if($measure eq "lesk") {
	use UMLS::Similarity::lesk;
	my %leskoptions = ();
	
	if(defined $opt_stoplist) {
	    $leskoptions{"stoplist"} = $opt_stoplist;
	}
	if(defined $opt_stem) {
	    $leskoptions{"stem"} = $opt_stem;
	}
	if(defined $opt_debugfile) {
	    $leskoptions{"debugfile"} = $opt_debugfile;
	}
	
	if(defined $opt_defraw) { 
	    $leskoptions{"defraw"} = $opt_defraw;
	}
	if(defined $opt_dictfile) {
	    $leskoptions{"dictfile"} = $opt_dictfile;
	}
	
        $meas = UMLS::Similarity::lesk->new($umls,\%leskoptions);  
    }


    die "Unable to create measure object.\n" if(!$meas);

    return $meas;
}

#  load the UMLS
sub loadUMLS {
 
    if(defined $opt_t) { 
	$option_hash{"t"} = 1;
    }
    if(defined $opt_config) {
	$option_hash{"config"} = $opt_config;
    }
    if(defined $opt_debug) {
	$option_hash{"debug"} = $opt_debug;
    }
    if(defined $opt_forcerun) {
	$option_hash{"forcerun"} = $opt_forcerun;
    }
    if(defined $opt_realtime) {
	$option_hash{"realtime"} = $opt_realtime;
    }
    if(defined $opt_verbose) {
	$option_hash{"verbose"} = $opt_verbose;
    }
    if(defined $opt_icpropagation) {
	$option_hash{"icpropagation"} = $opt_icpropagation;
    }
    if(defined $opt_icfrequency) { 
	$option_hash{"icfrequency"} = $opt_icfrequency;
    }
    if(defined $opt_smooth) { 
	$option_hash{"smooth"} = $opt_smooth;
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
}

#  checks the user input options
sub checkOptions {

    if( (defined $opt_matrix) && !(defined $opt_infile)) {
	print STDERR "The file must be specified using the --infile option\n";
	&minimalUsageNotes();
	exit;
    }

    if(defined $opt_measure) {
	if($opt_measure=~/\b(path|wup|lch|cdist|nam|vector|res|lin|random|jcn|lesk)\b/) {
	    #  good to go
	}
	else {
	    print STDERR "The measure ($opt_measure) is not defined for\n";
	    print STDERR "the UMLS-Similarity package at this time.\n\n";
	    &minimalUsageNotes();
	    exit;
	}   
    }
	
    #  the random measure does not require the configuration file
    #  if it is set exit since it could mean they don't know what
    #  the random measure is
    if( (defined $opt_config) && ($opt_measure=~/random/) ) {
	print STDERR "The --config option is not required for the random\n";
	print STDERR "measure. The random measure just assigns a random\n";
	print STDERR "number as the similarity score.\n\n";
	&minimalUsageNotes();
	exit;
    }   
	
    # make certain the db file is specified if the vector measure 
    # is being used
    if($opt_measure=~/vector/) {
	if(! (defined $opt_vectorindex)) {
	    print STDERR "The --vectorindex and --vectormatrix option must be\n";
	    print STDERR "specified when using the vector measure. An example\n";
	    print STDERR "of the matrix and index files can be seen in the \n";
	    print STDERR "samples/ directory.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
	if(! (defined $opt_vectormatrix)) {
	    print STDERR "The --vectorindex and --vectormatrix option must be\n";
	    print STDERR "specified when using the vector measure.An example\n";
	    print STDERR "of the index and matrix files can be seen in the\n";
	    print STDERR "samples/ directory. The vector-input.pl program can\n";
	    print STDERR "generate these files given your specific text. \n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }
 
    if(defined $opt_stoplist) { 
	if(! ($opt_measure=~/vector|lesk/) ) {
	    print STDERR "The --stoplist option is only available\n";
	    print STDERR "when using the lesk or vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    

    if(defined $opt_stem) { 
	if(! ($opt_measure=~/vector|lesk/) ) {
	    print STDERR "The --stem option is only available\n";
	    print STDERR "when using the lesk or vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    

    if(defined $opt_dictfile) { 
	if(! ($opt_measure=~/vector|lesk/) ) {
	    print STDERR "The --dictfile option is only available\n";
	    print STDERR "when using the lesk or vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    

    if(defined $opt_debugfile) { 
	if(! ($opt_measure=~/(vector|lesk)/) ) {
	    print STDERR "The --debugfile option is only available\n";
	    print STDERR "when using the lesk or vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    
   
    if(defined $opt_vectormatrix and defined $opt_vectorindex) { 
	if(! ($opt_measure=~/vector/) ) {
	    print STDERR "The --vectormatrix and --vectorindex options are only\n";
	    print STDERR "available when using the vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    
    
    if(defined $opt_vectormatrix) { 
	if(! ($opt_measure=~/vector/) ) {
	    print STDERR "The --vectormatrix option is only available\n";
	    print STDERR "when using the vector measure. \n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    

    if(defined $opt_vectorindex) { 
	if(! ($opt_measure=~/vector/) ) {
	    print STDERR "The --vectorindex option is only available\n";
	    print STDERR "when using the vector measure.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    
    
	    
	  
    #  make certain the propagation file is specified if the resnik, 
    #  jcn, or lin measure is being used
    if($opt_measure=~/(res|lin|jcn)/) {
	if(! (defined $opt_icpropagation) and !(defined $opt_icfrequency) ) {
	    print STDERR "The --icpropagation or --icfrequency option must be\n";
	    print STDERR "specified when using the res, lin or jcn measures.\n";
	    print STDERR "An example of the propagation file can be seen in\n";
	    print STDERR "the samples/ directory.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    } 

    #  the --smooth option can only be used with the icfrequency options
    if(defined $opt_smooth) {
	if(!defined $opt_icfrequency) {
	    print STDERR "The --smooth option can only be used with the\n";
	    print STDERR "--icfrequency option.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }
    
    #  the icpropagation and icfrequency options can only be used 
    #  with specific measures
    if(defined $opt_icpropagation || defined $opt_icfrequency) { 
	if( !($opt_measure=~/(res|lin|jcn)/) ) {
	    print STDERR "The --icpropagation or --icfrequency options\n";
            print STDERR "may only be specified when using the res, lin\n";
	    print STDERR "or jcn measures.\n\n";
	    &minimalUsageNotes();
	    exit;
	}
    }    


    if(defined $opt_icpropagation and defined $opt_icfrequency) { 
	print STDERR "You can specify both the --icpropagation and\n";
	print STDERR "--icfrequency options at the same time.\n\n";
	&minimalUsageNotes();
	exit;
    }    
    
    if(defined $opt_precision) {
	if ($opt_precision !~ /^\d+$/) {
	    print STDERR "Value for switch --precision should be integer >= 0\n";
	    &minimalUsageNotes();
	    exit;
	}
    }
}

#  set user input and default options
sub setOptions {

    if($debug) { print STDERR "In setOptions\n"; }

    my $default = "";
    my $set     = "";

    if(defined $opt_icpropagation) {
	$set .= "  --icpropagation $opt_icpropagation\n";
    }

    if(defined $opt_icfrequency) {
	$set .= "  --icfrequency $opt_icfrequency\n";
    }
    
    if(defined $opt_smooth) {
	$set .= "  --smooth\n";
    }

    if(defined $opt_debugfile) { 
	$set .= "  --debugfile $opt_debugfile\n";
    }
    if(defined $opt_vectormatrix) { 
	$set .= "  --vectormatrix $opt_vectormatrix\n";
    }
    
    if(defined $opt_vectorindex) { 
	$set .= "  --vectorindex $opt_vectorindex\n";
    }
    
    if(defined $opt_dictfile) {
	$set .= "  --dictfile $opt_dictfile\n";
    }
    
    if(defined $opt_defraw) { 
	$set .= "  --defraw\n";
    }
    
    if(defined $opt_stoplist) {
	$set .= "  --stoplist $opt_stoplist\n";
    }
    
    #  check config file
    if(defined $opt_config) {
	$config = $opt_config;
	$set .= "  --config $config\n";
    }

    #  set file
    if(defined $opt_infile) {
	$infile = $opt_infile;
	$set .= "  --infile $opt_infile\n";
    }
    
    #  set matrix
    if(defined $opt_matrix) {
	$set .= "  --matrix\n";
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

    if(defined $opt_realtime) {
	$set .= "  --realtime\n";
    }
    
    if(defined $opt_debug) { 
	$set .= "  --debug\n";
    }
    
    if(defined $opt_verbose) {
	$set .= "  --verbose\n";
    }

    if(defined $opt_info) {
	$set .= "  --info\n";
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

    print "General Options:\n\n";

    print "--config FILE            Configuration file\n\n";
        
    
    print "--realtime               This option finds the path and propagation\n";
    print "                         information for relevant measures in realtime\n";
    print "                         rather than building an index\n\n";

    print "--forcerun               This option will bypass any command \n";
    print "                         prompts such as asking if you would \n";
    print "                         like to continue with the index \n";
    print "                         creation. \n\n";

    print "--measure MEASURE        The measure to use to calculate the\n";
    print "                         semantic similarity. (DEFAULT: path)\n\n";

    print "--precision N            Displays values upto N places of decimal.\n\n";

    print "--allsenses              This option prints out all the possible\n";
    print "                         CUIs pairs and their semantic similarity\n"; 
    print "                         score if one of the inputs is a term that\n"; 
    print "                         maps to more than one CUI. Right now we \n"; 
    print "                         return the CUIs that are the most similar.\n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";

    print "\n\nInput Options: \n\n";

    print "--infile FILE            File containing TERM or CUI pairs\n\n";    

    print "--matrix                 This option returns a matrix of similarity\n";
    print "                         scores given a file containing a list of \n";
    print "                         CUIs. File is specified using --infile.\n\n";
    
    print "\n\nDebug Options:\n\n";

    print "--debug                  Sets the UMLS-Interface debug flag on\n";
    print "                         for testing purposes\n\n";

    print "--verbose                This option prints out the path information\n";
    print "                         to a file in your config directory.\n\n";    

    print "--info                   Displays information about a concept if\n";
    print "                         it doesn't exist in the source.\n\n";
    
    print "\n\nDatabase Options: \n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";
    
    print "\n\nIC Measure Options:\n\n";

    print "--icpropagation FILE     File containing the information content\n";
    print "                         of the CUIs.\n\n";

    print "--icfrequency FILE       File containing the frequency counts\n";
    print "                         of the CUIs.\n\n";

    print "--smooth                 Incorporate LaPlace smoothing. Can only\n";
    print "                         be used with the --icfrequency option\n\n";
    
    print "\n\nVector and Lesk Measure Options:\n\n";

    print "--vectormatrix FILE        The matrix file containing the vector\n";
    print "                         information for the vector measure.\n\n";

    print "--vectorindex FILE         The index file containing the vector\n";
    print "                         information for the vector measure.\n\n";

    print "--debugfile FILE         This prints the vector or lesk information to file,\n";
    print "                         FILE, for debugging purposes.\n\n";

    print "--dictfile FILE          This is a dictionary file for the vector and lesk\n";
    print "                         measure. It contains the 'definitions' of a concept\n";
    print "                         which would be used rather than the definitions from\n";
    print "                         the UMLS\n\n";

    print "--stoplist FILE          A file containing a list of words to be excluded\n";
    print "                         from the features in the vector and lesk method.\n\n";

    print "--stem                   This is a flag for the vector and lesk method. \n";
    print "                         If the --stem flag is set, words are stemmed. \n\n";

    print "--defraw                 This is a flag for the vector or lesk measure. The \n";
    print "                         definitions used are 'cleaned'. If the --defraw\n";
    print "                         flag is set they will not be cleaned. \n\n";

    print "\n\nLesk Measure Options:\n\n";




}
##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: umls-similarity.pl,v 1.47 2010/06/25 17:49:54 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type umls-similarity.pl --help for help.\n";
}
    
