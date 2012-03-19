#!/usr/local/bin/perl

use strict;
use warnings;

my $count = 0;
while (<>) {
    chomp;
    if ($count++ % 4 == 3) { tr/\x40-\x7e/\x21-\x5f/; }
    print "$_\n";
}
