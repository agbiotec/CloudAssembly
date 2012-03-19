#!/usr/local/bin/perl

# AUTHOR: Joseph Fass
# LAST REVISED: January 2010
# 
# The Bioinformatics Core at UC Davis Genome Center
# http://bioinformatics.ucdavis.edu
# Copyright (c) 2010 The Regents of University of California, Davis Campus.
# All rights reserved.

use strict;
use Getopt::Std;

my $usage = "\nusage: cat original.fastq | $0 -q # -z # -m # > trimmed.fastq\n\n".
            "Trims fastq sequences a la Heng Li's bwa '-q' option.  ".
            "Sequences must be on one line each (no multi-line sequences).  ".
            "Use -z 33 for Sequences in Sanger fastq encoding ( phredScore = ord(Q)-33 )".
            "Use -z 64 (this is default) for Sequences in Illumina fastq encoding ( phredScore = ord(Q)-64 )".
            "Use -m # to prevent output of sequences less than # in size (default 1)".
            "Sequences trimmed down to zero length will have one base ('N') with quality 2 ('#').\n".
            "-q #          targets # as quality level (default 20) ... NOT A HARD cutoff! (see bwa's bwa_trim_read() function in bwaseqio.c)\n\n";
our($opt_q,$opt_z,$opt_m);
getopts('q:z:m:') or die $usage;
if (!defined($opt_q) or !($opt_q =~ m/^[0-9]+$/)) {$opt_q = 20;}
if (!defined($opt_z) or !($opt_z =~ m/^[0-9]+$/)) {$opt_z = 64;}
if (!defined($opt_m) or !($opt_m =~ m/^[0-9]+$/)) {$opt_m = 1;}

my $h1;  my $s;  my $h2;  my $q;
my $pos;  my $maxPos;  my $area;  my $maxArea;
while ($h1 = <>) {  # read first header
	$s = <>;  # read sequence
	chomp $s;
	$h2 = <>;  # read second header
	$q = <>;  # read quality scores
	chomp $q;
	$pos = length($q);
	$maxPos = $pos;
	$area = 0;
	$maxArea = 0;
	while ($pos>0 and $area>=0) {
		$area += $opt_q - (ord(substr($q,$pos-1,1))-$opt_z);
		if ($area > $maxArea) {
			$maxArea = $area;
			$maxPos = $pos;
		}
		$pos--;
	}
	if ($pos==0) { $s = "N\n";  $q = chr(2+$opt_z) . "\n" }  # scanned whole read and didn't integrate to zero?  replace with "empty" read ...
	else {  # integrated to zero?  trim before position where area reached a maximum (~where string of qualities were still below 20 ...)
		$s = substr($s,0,$maxPos)."\n";
		$q = substr($q,0,$maxPos)."\n";
	}
        if ( length($s) >= $opt_m ) {
		print $h1.$s.$h2.$q;
	}
}

