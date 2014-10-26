#!/usr/bin/perl 

=head1 NAME

query-umls-similarity-webinterface.pl - This program returns a semantic similarity score between two concepts.

=head1 SYNOPSIS

This is a utility that takes as input either two terms (DEFAULT) 
or two CUIs and returns the similarity between the two.

=head1 USAGE

Usage: query-umls-similarity-webinterface.pl [OPTIONS] [CUI1|TERM1] [CUI2|TERM2]

=head1 INPUT

=head3 [CUI1|TERM1] [CUI2|TERM2]

The input are two terms or two CUIs associated to concepts in the UMLS. 

=head2 OPTIONS: 

=head3 --sab SOURCES

The UMLS source(s) used to obtain the similarity or relatedness values. 

Currently, for similarity the following sources are available through 
the web interface: MSH, OMIM, FMA or SNOMEDCT. For relatedness, the available
sources are: MSH, SNOMEDCT or UMLS_ALL (which refers to the entire umls). 

For example:
 
  --sab MSH
 
Note: In the UMLS::Similarity package, we differentiate between 
the sources used for relatendess and similarity measures the 
sabdef variable for relatedness and the sab variable for similarity
but to simplify things we only use hte rel variable right now. I 
hope this doesn't confuse anyone. 

For additional sources to be added please email me and we can see 
about adding them. Also note, that the UMLS::Similarity package 
allows for any combination of sources to be used. 

=head3 --rel RELATIONS

The UMLS relations used to obtain the similarity or relatedness values. 
Currently, for similarity following relations are available through the 
web interface: PAR/CHD or RB/RN. For relatedness: CUI/PAR/CHD/RB/RN or 
CUI. 

For example: 
  
  --rel PAR/CHD

Note: The relatedness measure use definition information and therefore 
CUI refers to using the definition of the concept itself while PAR, 
for example, refers to using the definition of the concepts parent 
relations. In the UMLS::Similarity package, we differentiate between 
these using the reldef and rel variables but to simplify things 
we only use hte rel variable right now. 

For additional relations to be added please email me and we can see 
about adding them. Also note, that the UMLS::Similarity package 
allows for any combination of sources/relations to be used. 

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

=head3 --infile FILE

A file containing pairs of concepts or terms in any of the following 
formats:

    term1<>term2     
    cui1<>cui2
    cui1<>term2
    term1<>cui2

=head1 SYSTEM REQUIREMENTS

=over

=item * Perl (version 5.8.5 or better) - http://www.perl.org

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

Copyright (c) 2007-2011,

 Bridget T. McInnes, University of Minnesota
 bthomson at cs.umn.edu
    
 Ted Pedersen, University of Minnesota Duluth
 tpederse at d.umn.edu

 Serguei Pakhomov, University of Minnesota Twin Cities
 pakh0002 at umn.edu

 Ying Liu, University of Minnesota Twin Cities
 liux at umn.edu

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

use Getopt::Long;
use URI::Escape;
use LWP; 

eval(GetOptions( "version", "help", "measure=s", "sab=s", "rel=s", "infile=s", "debug")) or die ("Please check the above mentioned option(s).\n");

# if debug is defined
my $debug = 0;
if(defined $opt_debug) { $debug = 1; }

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

#  set browser handler
my $browser = LWP::UserAgent->new;

#  initialize variables
my $rel      = "";
my $sab      = "";
my $reldef   = "";
my $sabdef   = "";
my $rmeasure = "";
my $smeasure = "";
my $button   = "";
my $measure  = "";

#  check the input options
&checkOptions();

#  set the options
&setOptions();

#  get the concept pairs
my $input = &loadInput();

#  get the similarity for each input pair
foreach my $pair (@{$input}) { 
    my ($input1, $input2)  = split/<>/, $pair;
    
    if($debug) { 
	print STDERR "$input1 : $input2\n";
	print STDERR "SAB: $sab\n";
	print STDERR "REL: $rel\n";
	print STDERR "SABDEF: $sabdef\n";
	print STDERR "RELDEF: $reldef\n";
	print STDERR "BUTTON: $button\n";
	print STDERR "MEASURES: $rmeasure $smeasure\n";
    }

    #  query the web interface
    my $page = &queryWebInterface($input1, $input2);
    
    #  extract the similarity information
    my $output = &extractInformation($page);
    
    #  print output
    print "$output\n";

    for my $i (0..10000000) { ; }
}

sub extractInformation
{
    my $page = shift;
    
    $page=~/<p class=\"results\">The (similarity|relatedness) of (.*?) \(<a href=\"\#\" onclick=\"showWindow \(\'umls\_wps\.cgi\?wps=(C[0-9]+)(|.*?\')?\, \'\'\); return false;\">(C[0-9]+)<\/a> \) and (.*?) \(<a href=\"\#\" onclick=\"showWindow \(\'umls\_wps\.cgi\?wps=(C[0-9]+)(|.*?\')\, \'\'\); return false;\">(C[0-9]+)<\/a> \) using (.*?) \(.*?\) is (.*?)\.<\/p>/;
    
    my $word1 = $2;
    my $cui1  = $3;
    
    my $word2 = $6;
    my $cui2  = $7;
    
    my $score = $11;
    
    return "$score<>$word1($cui1)<>$word2($cui2)";
    
}
    

sub queryWebInterface
{
    my $i1   = shift;
    my $i2   = shift;
    
    if($debug) { print STDERR "In queryWebInterface($i1, $i2)\n"; }
    
    my $url = "http://134.84.248.51/cgi-bin/umls_similarity.cgi?word1=$i1&word2=$i2&sab=$sab&rel=$rel&similarity=$smeasure&button=$button&sabdef=$sabdef&reldef=$reldef&relatedness=$rmeasure";

    my $resp = $browser->get($url);   
    if ($resp->is_success) { }   
    else { print $resp->status_line, "$url \n"; }
    
    my $webpage = $resp->content;    
    
    return $webpage;
}

sub loadInput {
    
    if($debug) { print STDERR "In loadInput\n"; }

    my @input_array = ();

    #  if file is defined get the terms or cuis from the input file
    if(defined $opt_infile) {

	if($debug) { print STDERR "FILE ($opt_infile) DEFINED\n"; }

	open(FILE, $infile) || die "Could not open file: $infile\n";
	my $linecounter = 1;
	while(<FILE>) {
	    chomp;
	    if($_=~/^\s*$/) { next; }
	    if($_=~/\<\>/) {
		#  escape the ' character on input if it exists
		if(! ($_=~/\\\'/)) { $_=~s/'/\\'/g; }

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

	#  escape the ' character on input if it exists
	if(! ($i1=~/\\\'/)) { $i1=~s/'/\\'/g; }
	if(! ($i2=~/\\\'/)) { $i2=~s/'/\\'/g; }

	if($debug) { print STDERR "INPUT:  $i1 $i2\n"; }
	
	my $input = "$i1<>$i2";
	push @input_array, $input;
    }
    
    return \@input_array;
}

#  checks the user input options
sub checkOptions {
    
    if($debug) { print STDERR "In checkOptions\n"; }

    if(defined $opt_measure) {
	if(! ($opt_measure=~/\b(path|wup|lch|cdist|nam|vector|res|lin|random|jcn|lesk)\b/)) {
	    print STDERR "The measure ($opt_measure) is not defined for\n";
	    print STDERR "the UMLS-Similarity package at this time.\n\n";
	    &minimalUsageNotes();
	    exit;
	}   
    }	
    if(defined $opt_sab) { 
	
	if(defined $opt_measure && $opt_measure=~/lesk|vector/) { 
	    if(! ($opt_sab=~/MSH|SNOMEDCT|UMLS_ALL/) ) {
		print STDERR "The --sab $opt_sab is currently not available through the web interface\n";
		print STDERR "for the relatedness measure ($opt_measure)\n";
		&minimalUsageNotes();
		exit;
	    }
	}
	else {
	    if(! ($opt_sab=~/MSH|OMIM|SNOMEDCT|FMA/) ) {
		print STDERR "The --sab $opt_sab is currently not available through the web interface\n";
		print STDERR "for the similarity measure (";
		if(defined $opt_measure) { print STDERR "$opt_measure)\n"; }
		else                     { print STDERR "path)\n";         }
		&minimalUsageNotes();
		exit;
	    }
	}
    }
    
    if(defined $opt_rel) { 
	
	my @rels = split/\//, $opt_rel;
	my $cui = 0; my $p = 0; my $c = 0; my $rb = 0 ; my $rn = 0;
	foreach my $rel (@rels) { 
	    if($rel=~/PAR/) { $p++;  }
	    elsif($rel=~/CHD/) { $c++;  }
	    elsif($rel=~/RN/)  { $rn++; }
	    elsif($rel=~/RB/)  { $rb++; }
	    elsif($rel=~/CUI/) { $cui++; }
	    else {
		print STDERR "The relation $rel is not available in the webinterface.\n";
		&minimalUsageNotes();
		exit;
	    }
	}
	
	if(defined $opt_measure && $opt_measure=~/lesk|vector/) { 
	    if(! (($cui > 0 && $p > 0 && $c > 0 && $rb > 0 && $rn  > 0) ||
	          ($cui > 0 && $p < 1 && $c < 1 && $rb < 1 && $rn  < 1)) ) {
		print STDERR "The --rel $opt_rel is currently not available through the web interface\n";
		print STDERR "for the relatedness measure ($opt_measure).\n";
		&minimalUsageNotes();
		exit;
	    }
	}
	else {
	    if($cui > 0) { 
		print STDERR "The CUI relation is only available for the relatedness measures.\n\n";
		&minimalUsageNotes();
		exit;
	    }	
	    if($p > 0 && $c > 0 && $rb > 0 && $rn > 0) { 
		print STDERR "The options PAR/CHD/RB/RN is currently not available\n";
		&minimalUsageNotes();
		exit;
	    }

	    if($p > 0 && $c < 1) { 
		print STDERR "Missing CHD option in PAR/CHD\n";
		&minimalUsageNotes();
		exit;
	    }
	    if($p < 1 && $c > 0) { 
		print STDERR "Missing PAR option in PAR/CHD\n";
		&minimalUsageNotes();
		exit;
	    }
	    if($rb > 0 && $rn < 1) { 
		print STDERR "Missing RN option in RB/RN\n";
		&minimalUsageNotes();
		exit;
	    }
	    if($rb < 1 && $rn > 0) { 
		print STDERR "Missing RB option in RB/RN\n";
		&minimalUsageNotes();
		exit;
	    }
	}
    }
}



#  set user input and default options
sub setOptions {

    if($debug) { print STDERR "In setOptions\n"; }

    my $default = "";
    my $set     = "";

    #  set file
    if(defined $opt_infile) {
	$infile = $opt_infile;
	$set .= "  --infile $opt_infile\n";
    }
    
    #  set the measures
    $smeasure = "path";
    $rmeasure = "vector";
    $measure  = "similarity";
    if(defined $opt_measure) {
	$set    .= "  --measure $opt_measure\n";
	if($opt_measure=~/lesk|vector/) { 
	    $button   = "Compute+Relatedness"; 
	    $rmeasure = $opt_measure;
	    $measure  = "relatedness";
	}	
	else { 
	    $button   = "Compute+Similarity";  
	    $smeasure = $opt_measure;
	}
    }
    else {
	$button   = "Compute+Similarity"; 
	$default .= "  --measure $smeasure\n";
    }
    
    $sab = "MSH";
    $sabdef = "UMLS_ALL";
    if(defined $opt_sab) { 
	if($measure eq "similarity") { $sab    = $opt_sab; }
	else                         { $sabdef = $opt_sab; }
    }
    else {
	if($measure eq "similarity") { 	$default .= "  --sab $sab\n";    }
	else                         { 	$default .= "  --sab $sabdef\n"; }
    }
    
    #  get the relation options for similarity and relatedness
    $reldef = "CUI/PAR/CHD/RB/RN";
    $rel    = "PAR/CHD";
    if(defined $opt_rel) { 
	my @rels = split/\//, $opt_rel;
	my $cui = 0; my $p = 0; my $c = 0; my $rb = 0 ; my $rn = 0;
	foreach my $rel (@rels) { 
	    if($rel=~/PAR/) { $p++;  }
	    if($rel=~/CHD/) { $c++;  }
	    if($rel=~/RN/)  { $rn++; }
	    if($rel=~/RB/)  { $rb++; }
	    if($rel=~/CUI/) { $cui++; }
	}
	
	if($cui > 0 && $p > 0 && $c > 0 && $rb > 0 && $rn  > 0) { $reldef = "CUI/PAR/CHD/RB%2fRN"; }
	if($cui > 0 && $p < 1 && $c < 1 && $rb < 1 && $rn  < 1) { $reldef = "CUI"; }
	
	if($p > 0  && $c > 0)  { $rel = "PAR/CHD"; }
	if($rb > 0 && $rn > 0) { $rel = "RB/RN";   }
	
	$set .= "  --rel $opt_rel\n";
    }
    else {
	if($measure eq "similarity") { $default .= "  --rel PAR/CHD";           }
	else                         { $default .= "  --rel CUI/PAR/CHD/RB/RN"; }
	    
    }
    
    #  set the relation options for the web browser
    $reldef=~s/\//%2F/g;
    $rel=~s/\//%2F/g;
    
    
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
    
    print "Usage: query-umls-similarity-webinterface.pl [OPTIONS] [TERM1 TERM2] [CUI1 CUI2]\n";
    &askHelp();
    exit;
}

##############################################################################
#  function to output help messages for this program
##############################################################################
sub showHelp() {
        
    print "This is a utility that takes as input either two terms \n";
    print "or two CUIs from the command line or a file and returns \n";
    print "the similarity between the two using the UMLS-Similarity\n";
    print "web interface\n";
  
    print "Usage: query-umls-similarity-webinterface.pl [OPTIONS] TERM1 TERM2\n\n";

    print "General Options:\n\n";

    print "--measure MEASURE        The measure to use to calculate the\n";
    print "                         semantic similarity. (DEFAULT: path)\n\n";

    print "--sab SOURCE(s)          Source(s) used to obtain similarity score.\n";
    print "                         Similarity DEFAULT: MSH\n";
    print "                         Relatedness DEFAULT: UMLS_ALL\n\n";
    
    print "--rel RELATION(s)        Relation(s) used to obtain similarity score.\n";
    print "                         Similarity DEFAULT: PAR/CHD\n";
    print "                         Relatedness DEFAULT: CUI/PAR/CHD/RB/RN\n\n";
    
    print "--version                Prints the version number\n\n";
    
    print "--help                   Prints this help message.\n\n";

 
    print "--infile FILE            File containing TERM or CUI pairs\n\n";    

}
##############################################################################
#  function to output the version number
##############################################################################
sub showVersion {
    print '$Id: query-umls-similarity-webinterface.pl,v 1.5 2011/05/04 12:06:42 btmcinnes Exp $';
    print "\nCopyright (c) 2011, Ted Pedersen & Bridget McInnes\n";
}

##############################################################################
#  function to output "ask for help" message when user's goofed
##############################################################################
sub askHelp {
    print STDERR "Type query-umls-similarity-webinterface.pl --help for help.\n";
}
    
