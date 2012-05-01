#!/usr/bin/env ruby

require 'set'
require 'Read'
require 'ElandLine'
require 'DNAProfile'

refFasta  = ARGV.shift
primerPos = ARGV.shift
excludes  = ARGV.shift

fasta = FastaReader.new( refFasta )
refRec = nil

excludeId = Set.new
IO.foreach(excludes) {|id| excludeId << id.chomp }

# only 1 sequence in ref fasta file
fasta.each {|read| refRec = read }

prof = DNAProfile.new( refRec.getRawSeq(), 29 )
revprof = DNAProfile.new( refRec.getRawSeq(), 29 )

prof.readMaskFile( primerPos )
revprof.readMaskFile( primerPos )

# try cutting off last 5 bases, to reduce noise
EDGE_CUT = 5

ARGF.each_line do |line|
    mapping = ElandLine.new(line)
    next unless mapping.mapsUnique? && !excludeId.include?( mapping.readName )

    seq    = mapping.seq
    qv     = mapping.qvList
    offset = mapping.offset

    seq.slice!(-EDGE_CUT..-1)
    qv.slice!( -EDGE_CUT..-1)

    if mapping.isReverse?
        offset += EDGE_CUT
        seq.reverse!.tr! 'ATGC','TACG'
        qv.reverse!
    end

    if mapping.isReverse?
        revprof.addSequenceAt( offset, seq, qv )
    else
        prof.addSequenceAt( offset, seq, qv )
    end
end

File.open('revdiffs','w') {|out| revprof.referenceDiffs( out ) }
File.open('fwddiffs','w') {|out|    prof.referenceDiffs( out ) }
File.open('revprof','w') {|out| revprof.print( out ) }
File.open('fwdprof','w') {|out|    prof.print( out ) }

combined = prof + revprof
File.open('bothprof','w') {|out| combined.print( out ) }
