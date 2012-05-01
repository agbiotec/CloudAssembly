#!/usr/bin/env ruby

require 'bio'

giFile = ARGV[0]

gis = []
IO.foreach(giFile) {|gi| gis << gi.chomp }

Bio::NCBI.default_email = 'eventer@jcvi.org'
ncbi = Bio::NCBI::REST::EFetch.new

gis.each_with_index do |gi,i|
    sleep 0.7 if i % 3 == 0
    puts ncbi.sequence(gi, 'gb')
end
