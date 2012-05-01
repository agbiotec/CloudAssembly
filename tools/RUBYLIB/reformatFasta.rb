#!/usr/bin/env ruby

require 'Read'

Defs = {}
if ARGV.size == 1
    IO.foreach(ARGV[0]) do |line|
        offset,readid,ggid = line.split 
        Defs[ggid] = readid
    end
end

out   = FastaWriter.new(STDOUT)
input = FastaReader.new(STDIN)
input.each do |read|
    if Defs.has_key? read.id
        read.defline += ' ' + read.id
        read.id = Defs[ read.id ]
    end
    out.write(read)
end
