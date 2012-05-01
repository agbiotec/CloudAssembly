#!/usr/bin/env ruby

require 'Read.rb'

out = FastaWriter.new($stdout,false)

reader = FastaReader.new(ARGF)
reader.each do |r|
    r.sequence = r.getRawSeq().squeeze
    out.write( r )
end
