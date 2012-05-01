#!/usr/bin/env ruby

require 'Read'

ARGV.each do |file|
    input = FastaReader.new(file)
    input.each {|read| puts "#{read.getClearLen} #{read.id}" }
end
