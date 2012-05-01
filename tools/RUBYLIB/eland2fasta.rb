#!/usr/bin/env ruby

require 'Read'
require 'ElandLine'

fastaOut = FastaWriter.new($stdout,false)

ARGF.each_line do |line|
    mapping = ElandLine.new(line)

    r   = Read.new()   
    r.id = mapping.readName
    r.sequence = mapping.seq
    
    fastaOut.write( r )
end
