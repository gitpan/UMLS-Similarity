#!/usr/local/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/lch.t'

# A script to test whether 
#  1. UMLS-Interface can be loaded
#  2. DBI can access the umls database in mysql
#  3. Information (Table names) can be accessed 
#  4. MRREL table exists 
#  5. MRCONSO table exists
#  6. MRSAB table exists
#  7. MRDOC table exists
#  8. MRDOC table can be accessed


BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}

use UMLS::Interface;
use UMLS::Similarity::lch;
use UMLS::Similarity::path;
$loaded = 1;
print "ok 1\n";

use strict;
use warnings;

my $umls = UMLS::Interface->new(); 
if(!$umls) { 
    print "not ok 2\n";
}
else {
    print "ok 2\n";
}

my $lch = UMLS::Similarity::lch->new($umls);
if(!$lch) {
    print "not ok 3\n";
}
else {
    print "ok 3\n";
}
    

my $path = UMLS::Similarity::path->new($umls);
if(!$path) {
    print "not ok 4\n";
}
else {
    print "ok 4\n";
}
