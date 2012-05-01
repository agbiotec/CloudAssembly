#!/usr/bin/env ruby

require 'Read'

input = FastaReader.new(ARGF)
seq   = FastaWriter.new(STDOUT,false)
qv   = FastaWriter.new(STDOUT,true)
input.each do |read|
    read.reverseComplement()
    if read.hasQV?
        qv.write(read)
    else
        seq.write(read)
    end
end
