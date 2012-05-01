#!/usr/bin/env ruby

require 'Read.rb'

hist = {}
ARGV.each do |inFile|
    reader = FastaReader.new(inFile)
    reader.each do |r|
        hist.merge!( r.merHist(17) ) {|k,o,n| o+n}
    end
end

sorted = hist.sort() {|a,b| a[1] <=> b[1]}
sorted.each {|p| puts "#{p[0]} #{p[1]}" if p[1] > 2 }

#system "grep VmPeak /proc/#{$$}/status"
puts IO.foreach("/proc/self/status").grep(/VmPeak/)
