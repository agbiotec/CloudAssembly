#!/usr/bin/env ruby1.9

require 'matrix'
require 'fiber'
require 'optparse'

require 'DNAProfile'
require 'Read'

args = { :ref => '', :readFQ => '', :primerPos => '', :min_cov => 40,
    :edge_cut => 5, :minQV => 29 }

opts = OptionParser.new do |opt|
    opt.banner = "Usage: #$0 <options> < razers.fa.result"
    opt.separator ''
    opt.separator 'Options:'

    opt.on('-r','--reference referenceFasta',
           'Fasta file of the reference sequence used to map to.'
          ) { |f| args[:ref] = f }

    opt.on('-f','--fastq <fastqFile>',
           'Fastq file of the sequences mapped.'
          ) { |f| args[:readFQ] = f }

    opt.on('-p','--primerPos <CSV FileName>',
           'This file has one pair of coordinates per line.
           No read edge occuring in one of these regions will contribute to the profile.'
          ) { |f| args[:primerPos] = f }

    opt.on('-c','--minCoverage <number>, default is 40',
           'Minimum bidirectional coverage required for the combined profile.'
          ) { |i| args[:min_cov] = i.to_i }

    opt.on('-e','--edgeCut <number>, default is 5',
           'Number of bases to trim from end of read.'
          ) { |i| args[:edge_cut] = i.to_i }

    opt.on('-q','--qvMinimum <number>, default is 29',
           'Minimum Quality Value of a base for it to be counted in the profiles.'
          ) { |i| args[:minQV] = i.to_i }

    opt.on_tail("-h","--help", "This help message") do
        puts opt
        exit
    end
end

opts.parse!(ARGV)

refFasta = args[:ref]
readFastq= args[:readFQ]
primerPos= args[:primerPos]

if refFasta == '' || readFastq == '' || primerPos == ''
    puts opts
    exit
end

BI_MIN_COV = args[:min_cov]
EDGE_CUT = args[:edge_cut]

ref = nil
refReader = FastaReader.new(refFasta)
refReader.each {|r| ref = r.getClearSeq }

readFQ = FastqReader.readFiber( readFastq )
fwdprofile = DNAProfile.new( ref, args[:minQV] )
revprofile = DNAProfile.new( ref, args[:minQV] )
allprofile = DNAProfile.new( ref, args[:minQV] )
fwdprofile.readMaskFile( primerPos )
revprofile.readMaskFile( primerPos )
allprofile.readMaskFile( primerPos )

ARGF.each_line do |line|
    id, rbeg, rend, dir, tigId, gbeg, gend, ident = line.split
    readLine   = ARGF.readline.chomp.split
    raise 'Not read line #{readLine}' unless readLine[0] == '#Read:'

    genomeLine = ARGF.readline.chomp.split
    raise 'Not genome line #{genomeLine}' unless genomeLine[0] == '#Genome:'

    qvRead = nil
    begin
        qvRead = readFQ.resume
    end until qvRead.id == id

    raise "QV not found for #{id}" unless qvRead.id == id

    rseq = readLine[1]
    gseq = genomeLine[1]
    qv   = qvRead.getClearQV
    # trim off the last 5 bases, due to frequent error or alignment artifacts
    if EDGE_CUT > 1
        gapC = rseq[-EDGE_CUT..-1].count('-')
        rseq = rseq[0...-EDGE_CUT]
        gseq = gseq[0...-EDGE_CUT]
        qv   =   qv[0...-EDGE_CUT+gapC]
    end

    # razers uses 0 based coords, profile uses 1 base based
    offset = gbeg.to_i + 1

    # razers result file shows the alignment on the read strand
    if dir == 'R'
        rseq.reverse!.tr! 'ACGT','TGCA'
        gseq.reverse!.tr! 'ACGT','TGCA'
        offset += EDGE_CUT
        revprofile.addAlignmentAt( offset, rseq, gseq, qv )
    else
        fwdprofile.addAlignmentAt( offset, rseq, gseq, qv )
    end
    allprofile.addAlignmentAt( offset, rseq, gseq, qv )

end

profbi = fwdprofile.sumAboveCov( revprofile, BI_MIN_COV )

File.open('fwddiffs','w') { |io| fwdprofile.referenceDiffs(io)}
File.open('revdiffs','w') { |io| revprofile.referenceDiffs(io)}

File.open('fwdprof','w') {|io| fwdprofile.print(io)}
File.open('revprof','w') {|io| revprofile.print(io)}
File.open('allprof','w') {|io| allprofile.print(io)}
File.open("prof.bi#{BI_MIN_COV}x",'w') {|io| profbi.print(io)}
