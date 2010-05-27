#!/usr/bin/perl

=head1 NAME

create-icpropagation.pl - This program determines the probability 
of the CUIs in a specified set of sources and relations. 

=head1 SYNOPSIS

This program determines the probability of the CUIs in a 
specified set of sources and relations.

=head1 PROPAGATION

The Information Content (IC) is  defined as the negative log 
of the probability of a concept. The probability of a concept, 
c, is determine by summing the probability of the concept 
(P(c)) ocurring in some text plus the probability its decendants 
(P(d)) occuring in some text:

P(c*) = P(c) + \sum_{d\exists decendant(c)} P(d)

The initial probability of a concept (P(c)) and its decendants 
(P(d)) is obtained by dividing the number of times a concept is 
seen in the corpus (freq(d)) by the total number of concepts (N):

P(d) = freq(d) / N

Not all of the concepts in the taxonomy will be seen in the corpus. 
We have the option to use Laplace smoothing, where the frequency 
count of each of the concepts in the taxonomy is incremented by one. 
The advantage of doing this is that it avoides having a concept that 
has a probability of zero. The disadvantage is that it can shift the 
overall probability mass of the concepts from what is actually seen 
in the corpus. 

=head1 USAGE

Usage: create-icpropagation.pl [OPTIONS] OUTPUTFILE ICFREQUENCY_FILE


=head2 OUTPUTFILE

File in which the probability of the CUIs will be stored. 

The ouput file containing the probability of the CUIs has the 
following format: 

    SMOOTH :: <0|1>
    SAB :: <sources>
    REL :: <relations>
    RELA :: <relas>  <- if any are specified in the config
    CUI<>probability
    CUI<>probability
    ...

=head2 ICFREQUENCY FILE

File containing the icfrequency counts

The input file contains frequency counts for CUIs in the following 
format: 

    SAB :: <sources>
    CUI<>freq
    CUI<>freq
    ...

=head2 Optional Arguments:

=head3 --smooth 

Incorporate Laplace smoothing, where the frequency count of each of the 
concepts in the taxonomy is incremented by one. The advantage of 
doing this is that it avoides having a concept that has a probability 
of zero. The disadvantage is that it can shift the overall probability 
mass of the concepts from what is actually seen in the corpus. 

=head3 --config FILE

This is the configuration file. The format of the configuration 
file is as follows:

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

=head3 --disregardsab

This ignores the SAB configuration that the icfrequency 
file was created with

=head3 --precision N

Displays values upto N places of decimal.

=head3 --username STRING

Username is required to access the umls database on MySql

=head3 --password STRING

Password is required to access the umls database on MySql

=head3 --hostname STRING

Hostname where mysql is located. DEFAULT: localhost

=head3 --database STRING        

Database contain UMLS DEFAULT: umls

=head3 --debug

Sets the UMLS-Interface debug flag on for testing

=head3 --help

Displays the quick summary of program options.

=head3 --version

Displays the version information.

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

=item * UMLS::Interface - http://search.cpan.org/dist/UMLS-Interface

=item * UMLS::Similarity - http://search.cpan.org/dist/UMLS-Similarity

=item * Text::NSP - http://search.cpan.org/dist/Text-NSP

=item * MetaMap - http://mmtx.nlm.nih.gov/

=back

=head1 CONTACT US
   
  If you have any trouble installing and using CreatePropagationFile, 
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
use File::Path;

eval(GetOptions( "version", "help", "username=s", "password=s", "hostname=s", "database=s", "socket=s", "config=s", "debug", "t", "precision=s", "smooth", "disregardsab")) or die ("Please check the above mentioned option(s).\n");


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
if( scalar(@ARGV) < 2) { 
    print STDERR "At least 2 files should be specified on the command line.\n";
    &minimalUsageNotes();
    exit;
}

#  get the input and output files
my $outputfile = shift;
my $inputfile = shift;

# check to see if output file exists, and if so, if we should overwrite...
if ( -e $outputfile )
{
    print "Output file $outputfile already exists! Overwrite (Y/N)? ";
    $reply = <STDIN>;
    chomp $reply;
    $reply = uc $reply;
    exit 0 if ($reply ne "Y");
}

#  initialize variables
my $database    = "";
my $hostname    = "";
my $socket      = "";    
my $umls        = "";
my $floatformat = "";
my $smooth      = 0;

#  check the options 
&checkOptions       ();
&setOptions         ();

#  load the UMLS
&loadUMLS           ();

my $sabstring = $umls->getSabString();
my $relstring = $umls->getRelString();
my $relastring = $umls->getRelaString();

#  get the frequency counts
my $cuiHash = &getTermCounts($inputfile);

#  propagate the counts
my $propagationHash = $umls->propagateCounts($cuiHash);

#  print out the propagation counts
open(OUTPUT, ">$outputfile") || die "Could not open $outputfile\n";
print OUTPUT "SMOOTH: $smooth\n";
print OUTPUT "$sabstring\n";
print OUTPUT "$relstring\n";
print OUTPUT "$relastring\n";
foreach my $cui (sort keys %{$propagationHash}) {
    my $freq = ${$propagationHash}{$cui};

    #  check if precision needs to be set
    if(defined $opt_precision) {
	$freq = sprintf $floatformat, $freq;
    }
    
    print OUTPUT "$cui<>$freq\n";
}
close OUTPUT;

sub getFileCounts {

    my $file = shift;
    
    #  open the file
    open(FILE, $file) || die "Could not open --icfrequency file : $file\n";

    #  check to make certain the source is correct
    my $fsabstring = <FILE>; chomp $fsabstring;
    if(!$opt_disregardsab) {
	if($fsabstring ne $sabstring) {
	    print STDERR "The icfrequency file was created using the\n";
	    print STDERR "following configuration:\n";
	    print STDERR "    $sabstring\n";
	    print STDERR "Please modify your configuration file\n\n";
	    exit;
	}
    }
    
    my %hash = ();
    while(<FILE>) {
	chomp;
	my ($cui, $freq) = split/<>/;
	if(exists $cuiHash{$cui}) { 
	    $hash{$cui} += $freq; 
	}
	else {
	    $hash{$cui} = $freq; 
	}
    }
    close FILE;
    
    return \%hash;
}

sub getTermCounts {

    my $text = shift;
    
    my $countfile = "tmp.count";
    
    system "count.pl --ngram 1 $countfile $text";
    
    open(COUNT, $countfile) || die "Could not open the count file : $countfile\n";
    my %hash = ();

    my $header = <COUNT>;
    while(<COUNT>) {
	chomp;
	my ($term, $freq) = split/<>/;
	
	my @cuis = $umls->getConceptList($term); 

	foreach my $cui (@cuis) {
	    if(exists $hash{$cui}) {
		$hash{$cui} += $freq;
	    }
	    else { $hash{$cui} = $freq; }
	    
	}
    }
    close COUNT;

    File::Path->remove_tree("tmp.count");
    	
    return \%hash;
}


sub getMetaMapCounts {

    my $text = shift;
    open(TEXT, $text) || die "Could not open $text for processing\n";
    
    my %hash = ();
    while(<TEXT>) {
	chomp;
	my $output = &callMetaMap($_);
	
	my %temp = ();
	while($output=~/\'(C[0-9]+)\'\,(.*?)\,(.*?)\,/g) {
	    my $cui = $1; my $str = $3;
	    $str=~s/[\'\"]//g;
	    $temp{$cui}++;
	    $strings{$cui} = $str;
	}
	foreach my $cui (sort keys %temp) {
	    $hash{$cui}++;			
	}
    }
    
    return \%hash;
}

sub callMetaMap 
{
    my $line = shift;
    
    my $output = "";
	
    my $timestamp = &timeStamp();
    my $metamapInput  = "tmp.metamap.input.$timestamp";
    my $metamapOutput = "tmp.metamap.output.$timestamp";
    
    open(METAMAP_INPUT, ">$metamapInput") || die "Could not open file: $metamapInput\n";
    
    print METAMAP_INPUT "$line\n"; 
    close METAMAP_INPUT;
    
    print "metamap09 -q $metamapInput $metamapOutput\n";
    system("metamap09 -q $metamapInput $metamapOutput");

    open(METAMAP_OUTPUT, $metamapOutput) || die "Could not open file: $metamapOutput\n";
    
    while(<METAMAP_OUTPUT>) { 
	if($_=~/mappings\(/) {
	    $output .= $_; 
	}
    }
    close METAMAP_OUTPUT;
    
    File::Path->remove_tree($metamapInput);
    File::Path->remove_tree($metamapOutput);

    return $output;
}
sub timeStamp {
    my ($stamp);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    
    $year += 1900;
    $mon++;
    $d = sprintf("%4d%2.2d%2.2d",$year,$mon,$mday);
    $t = sprintf("%2.2d%2.2d%2.2d",$hour,$min,$sec);
    
    $stamp = $d . $t;
    return($stamp);
}

#  checks the user input options
sub checkOptions {

    if( (defined  $opt_username && !defined $opt_password) || 
	(!defined $opt_username && defined  $opt_password) ) {
	print STDERR "The --username and --password options\n";
	print STDERR "must both be specified if you are using\n";
	print STDERR "one of them.\n\n";
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

    #  check config file
    if(defined $opt_config) {
	$config = $opt_config;
	$set .= "  --config $config\n";
    }

    if(defined $opt_disregardsab) { 
	$set .= "  --disregardsab\n";
    }

    if(defined $opt_smooth) {
	$set .= "  --smooth";
	$smooth = 1;
    }
	
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
    
    if(defined $opt_precision) {

	# create the floating point conversion format as required by sprintf!
	$floatformat = join '', '%', '.', $opt_precision, 'f';
       
	#  set the output information
	$set .= "  --precision $opt_precision";	
    } 
    
        
    if(defined $opt_debug) { 
	$set .= "  --debug\n";
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
    if(defined $opt_smooth) {
	$option_hash{"smooth"} = 1;
    }
    if(defined $opt_username and defined $opt_password) {
	$option_hash{"driver"}   = "mysql";
	$option_hash{"database"} = $database;
	$option_hash{"username"} = $opt_username;
	$option_hash{"password"} = $opt_password;
	$option_hash{"hostname"} = $hostname;
	$option_hash{"socket"}   = $socket;
    }
    
    $option_hash{"realtime"} = 1;

    $umls = UMLS::Interface->new(\%option_hash); 
    die "Unable to create UMLS::Interface object.\n" if(!$umls);
}

##############################################################################
#  function to output minimal usage notes
##############################################################################
sub minimalUsageNotes {
    
    print "Usage: create-icpropagation.pl [OPTIONS] OUTPUTFILE INPUTFILE\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility that takes as input an output and input\n";
    print "file and determines the propagation counts of the CUIs in\n";
    print "a specified set of sources and relation using the frequency\n";
    print "information from the inputfile\n\n";
  
    print "Usage: create-icpropagation.pl [OPTIONS] OUTPUTFILE INPUTFILE\n\n";

    print "Options:\n\n";

    print "--config FILE            Configuration file\n\n";

    print "--smooth                 Incorporate LaPlace smoothing\n\n";

    print "--term                   Calculates the frequency counts using\n";
    print "                         the words in the input file. (DEFAULT)\n\n";

    print "--metamap                Calculates the frequency counts using\n";
    print "                         the CUIs assigned to terms by MetaMap.\n\n";

    print "--precision N            Displays values upto N places of decimal.\n\n";

    print "--icfrequency            The input file contains frequency counts\n";
    print "                         for CUIs rather than plain text\n\n";

    print "--username STRING        Username required to access mysql\n\n";

    print "--password STRING        Password required to access mysql\n\n";

    print "--hostname STRING        Hostname for mysql (DEFAULT: localhost)\n\n";

    print "--database STRING        Database contain UMLS (DEFAULT: umls)\n\n";

    print "--debug                  Sets the UMLS-Interface debug flag on\n";
    print "                         for testing purposes\n\n";

    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";
}

##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: create-icpropagation.pl,v 1.2 2010/05/26 21:56:24 btmcinnes Exp $';
    print "\nCopyright (c) 2008, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type create-icpropagation.pl --help for help.\n";
}
