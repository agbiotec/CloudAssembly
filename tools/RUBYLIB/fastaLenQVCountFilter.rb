#!/usr/bin/env ruby

require 'Read'

fastaFile = ARGV.shift
qualFile  = ARGV.shift

LEN = 300
QV  = 20

fasta = FastaReader.readFiber(fastaFile)
qual  = FastaReader.readFiber(qualFile)

while read = fasta.resume do
    readLen = read.getRawLen
    next unless readLen >= LEN

    begin
        qv = qual.resume
    end until qv.id == read.id

    raise "QV not found for #{read.id}" unless qv.id == read.id
    
    goodQVs = qv.getRawQV.count {|q| q >= QV }
    next unless goodQVs >= LEN
    puts "#{read.id} #{readLen} #{goodQVs}"
end
