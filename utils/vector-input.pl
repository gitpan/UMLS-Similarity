#!/usr/local/bin/perl -w

=head1 NAME

vector-input.pl - This program builds the term index file and co-occrrence matrix for umls-similarity.pl to calculate the vector relatedness. 

=head1 SYNOPSIS

vector-input.pl takes the bigrams frequency input and build the index and the 
co-occurrence matrix.

=head1 DESCRIPTION

We build the index and co-occurrence matrix for the vector method of UMLS-Similarity.
The index file helps to locate each term's vector by recording the start position
and the length of its vector. The matrix file records every term's vector. 

See perldoc vector-input.pl

=head1 USAGE 

vector-input.pl INDEX MATRIX BIGRAMFILE 

example: vector-input.pl Index.txt Matrix.txt BigramsList.txt

=head1 INPUT

=head2 Required Arguments:

=head3 INDEX

output file of the vector-input.pl. It records the index of each term 
and the vector start position and length f the co-occurrence matrix.  

=head3 MATRIX 

output file of the vector-input.pl. Each line is a vector for the 
term and its co-occurrence term and their frequency. 

=head3 BIGRAMFILE 

Input to vector-input.pl should be a single flat file generated by huge-count.pl 
of Text-NSP package. If the bigrams list is generated by count.pl, pleasue use
count2huge.pl to convert the results to huge-count.pl. It sorts the bigrams in 
the alphabet order. When vector-input.pl generates the index and co-occurrence 
matrix file, it requires the bigrams which starts the same term t1 grouped together 
and lists next to each other. Because at this step, bigrams are not stored in
memory. If the first term of the bigrams changes, it prints the output and index
position of the vector for the term t1. Especially, if the bigrams are sorted in 
the alphabet order, it is faster for vector method of UMLS-Similarity to build the 
vector. Because for each concept, it searches the co-occurrence matrix to build 
the second order vector. If every term of the vector are sorted, the vector 
method can search the co-occurrence matrix from the beginning to the end by the 
index position and length. If the co-occurrence matrix is a huge file, it could 
save lots of execute time. 

=head3 Other Options:

=head4 --help

Displays the help information.

=head4 --version

Displays the version information.

=head1 AUTHOR

Ying Liu, liux0395 at umn.edu

=head1 SEE ALSO

home page: www.tc.umn.edu/~liux0395

=head1 COPYRIGHT

Copyright (C) 2010, Ying Liu

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=cut

###############################################################################

#-----------------------------------------------------------------------------
#                              Start of program
#-----------------------------------------------------------------------------

# we have to use commandline options, so use the necessary package!
use Getopt::Long;

# first check if no commandline options have been provided... in which case
# print out the usage notes!
if ( $#ARGV == -1 )
{
    &minimalUsageNotes();
    exit;
}

# now get the options!
GetOptions( "version", "help" );

# if help has been requested, print out help!
if ( defined $opt_help )
{
    $opt_help = 1;
    &showHelp();
    exit;
}

# if version has been requested, show version!
if ( defined $opt_version )
{
    $opt_version = 1;
    &showVersion();
    exit;
}


my $start_bigram = time();

my $index_file = $ARGV[0];
# check to see if a destination has been supplied at all...
if ( !($index_file ) )
{
    print STDERR "No output file (INDEX) supplied.\n";
    askHelp();
    exit;
}
if (-e $index_file)
{
    print "Output file $index_file already exists! Overwrite (Y/N)? ";
    my $reply = <STDIN>;
    chomp $reply;
    $reply = uc $reply;
    exit 0 if ($reply ne "Y");
}
open(INDX, ">$index_file") 
        or die("Error: cannot open file '$index_file' for output index.\n");


my $matrix_file = $ARGV[1];
# check to see if a destination has been supplied at all...
if ( !($matrix_file ) )
{
    print STDERR "No output file (MATRIX) supplied.\n";
    askHelp();
    exit;
}
if (-e $matrix_file)
{
    print "Output file $matrix_file already exists! Overwrite (Y/N)? ";
    my $reply = <STDIN>;
    chomp $reply;
    $reply = uc $reply;
    exit 0 if ($reply ne "Y");
}
open(MATX, ">$matrix_file") 
        or die("Error: cannot open file '$matrix_file' for output index.\n");


$bigrams_file = $ARGV[2];
# check to see if a source has been supplied at all...
if ( !($bigrams_file ) )
{
    print STDERR "No output file (BIGRAMFILE) supplied.\n";
    askHelp();
    exit;
}
open(BIGM, "<$bigrams_file") 
        or die("Error: cannot open file '$bigrams_file' for output index.\n");

# read in the bigrams file
my %index;
my $index_num1 = 1;
my $total = <BIGM>;
while (my $line = <BIGM>)
{
	chomp($line);
	my @terms = split('<>', $line);

	# index every term of the bigram list
	if(!defined $index{$terms[0]})
	{
		$index{$terms[0]} = $index_num1;
		$index_num1++;
	}
	if(!defined $index{$terms[1]})
	{
		$index{$terms[1]} = $index_num1;
		$index_num1++;
	}	
}


# sort the index terms of %index and 
# initilize the position length array 
my $index_num2 = 1;
my @position_length;
$position_length[0] = 0; #index starts from 1
foreach my $t (sort (keys %index))
{
	$index{$t} = $index_num2;
	$position_length[$index_num2] = 0;
	$index_num2++;
}

# go the beginning of the bigrams file
seek BIGM, 0, 0 or die $!;
my $word = "";
my $position = 0;
my $bigrams = "";
$total = <BIGM>;
while (my $line = <BIGM>)
{
	chomp($line);
	my @terms = split('<>', $line);
	my @freqs = split (' ', $terms[2]);	

	# if it is still the same term. 	
	# print out the vector to the matrix file 
	if( $word eq $terms[0] )
	{
		#print "word: $word\n";
		$bigrams .= "$index{$terms[1]} $freqs[0] ";
		printf MATX "$index{$terms[1]} $freqs[0] ";	
	}
	else
	{
		# the first term of the bigrams changes, record 
		# the vector position and length of the term


        if ($word ne "")
        {
			$bigrams .= "\n";
           	my $length = length($bigrams);
            $position_length[$index{$word}] = "$position" . " $length";
           	$position += $length;
            $bigrams = "";
			printf MATX "\n";
        }

		# for a new term, print the term and its first bigrams frequency
		$word = $terms[0];
		$bigrams .= "$index{$word}: $index{$terms[1]} $freqs[0] ";
		printf MATX "$index{$word}: $index{$terms[1]} $freqs[0] ";
	}
		# reach the end of the bigrams file, record the 
		# vector position and length of the last term.	
		if (eof(BIGM))
		{
			$bigrams .= "\n";
           	my $length = length($bigrams);
            $position_length[$index{$word}] = "$position" . " $length";
			printf MATX "\n";
		}

}
close MATX;
close BIGM;

# out put the index file 
foreach my $t (sort (keys %index))
{
	printf INDX "$t $index{$t} $position_length[$index{$t}]\n"
}
close INDX;


#-----------------------------------------------------------------------------
#                       User Defined Function Definitions
#-----------------------------------------------------------------------------

# function to output a minimal usage note when the user has not provided any
# commandline options
sub minimalUsageNotes
{
    print STDERR "Usage: vector-input.pl INDEX MATRIX BIGRAMFILE\n";
    askHelp();
}

# function to output "ask for help" message when the user's goofed up!
sub askHelp
{
    print STDERR "Type vector-input.pl --help for help.\n";
}

# function to output help messages for this program
sub showHelp
{
    print "\n";
    print "Usage: vector-input.pl INDEX MATRIX BIGRAMFILE\n\n";

    print "build the index file for each term of the bigrams file and\n";
    print "create the co-occurence matrix.INDEX is the output index file.\n";
    print "MATRIX is the output matrix file. BIGRAMFILE is the output of\n"; 
	print "huge-count.pl of Text-NSP. \n\n";
    
    print "OPTIONS:\n\n";

    print "  --version          Prints the version number.\n\n";

    print "  --help             Prints this help message.\n\n";
}

# function to output the version number
sub showVersion
{
    print STDERR "vector-input.pl      -        version 0.02\n";
    print STDERR "Copyright (C) 2009, Ying Liu\n";
    print STDERR "Date of Last Update 03/23/10\n";

}




