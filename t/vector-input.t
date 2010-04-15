#!/usr/local/bin/perl -w 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl access.t'  
##################### We start with some black magic to print on failure.    
use strict;
use warnings;

use Test::More tests => 8;

BEGIN{ use_ok ('File::Spec') }
BEGIN{ use_ok ('File::Path') }                                    

#  set the key directory (create it if it doesn't exist)
my $keydir = File::Spec->catfile('t','key');
if(! (-e $keydir) ) 
{
    mkpath($keydir);
}

#  get the tests
my $input = File::Spec->catfile('t', 'tests', 'utils', 'bigrams');
my $output_index = File::Spec->catfile('t', 'key', 'static', 'index');
my $output_matrix = File::Spec->catfile('t', 'key', 'static', 'matrix');

my $perl     = $^X;
my $util_prg = File::Spec->catfile('utils','vector-input.pl');
my $test_index = File::Spec->catfile('t','output','index');
my $test_matrix = File::Spec->catfile('t','output','matrix');

system("$perl $util_prg $test_index $test_matrix $input");
   
if(-e $output_index) 
{
    ok (open KEY1, $output_index) or diag "Could not open $output_index: $!";
    my $key1 = "";
    while(<KEY1>) { $key1 .= $_; } close KEY1;
    
    ok (open KEY2, $test_index) or diag "Could not open $test_index: $!";
    my $key2 = "";
    while(<KEY2>) { $key2 .= $_; } close KEY2;
    cmp_ok($key1, 'eq', $key2);
}
else 
{
    ok(open OUTPUT, "$test_index") || diag "Could not open $test_index: $!";
    my $out = "";
    while(<OUTPUT>) { $out .= $_; } close OUTPUT;
    ok(open KEY, ">$output_index") || diag "Could not open $output_index: $!";
    print KEY "$out"; 
    close KEY;
  
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}

if(-e $output_matrix) 
{
    ok (open KEY3, $output_matrix) or diag "Could not open $output_matrix: $!";
    my $key3 = "";
    while(<KEY3>) { $key3 .= $_; } close KEY3;
    
    ok (open KEY4, $test_matrix) or diag "Could not open $test_matrix: $!";
    my $key4 = "";
    while(<KEY4>) { $key4 .= $_; } close KEY4;
    cmp_ok($key3, 'eq', $key4);
}
else 
{
    ok(open OUTPUT, "$test_matrix") || diag "Could not open $test_matrix: $!";
    my $out = "";
    while(<OUTPUT>) { $out .= $_; } close OUTPUT;
    ok(open KEY, ">$output_matrix") || diag "Could not open $output_matrix: $!";
    print KEY "$out"; 
    close KEY;
  
  SKIP: {
      skip ("Generating key, no need to run test", 1);
    }
}

#  remove the index and matrix files
File::Path->rmtree($test_index);
File::Path->rmtree($test_matrix);
