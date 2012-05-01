#!/usr/bin/env ruby

require 'Read'

LEN = ARGV.shift.to_i

ARGV.each do |file|
    input = FastaReader.new(file)

    short = 0
    long  = 0
    input.each do |read|
        if read.getClearLen > LEN
            long += 1
        else
            short += 1
        end
    end
    tot = short + long
    puts "#{file} #{short} #{short*100/tot}% less then #{LEN}, #{long} #{long*100/tot}% greater then."
end
