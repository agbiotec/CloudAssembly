#!/usr/bin/env ruby

require 'Read.rb'

ARGV.each do |inFile|
    reader = FastaReader.new(inFile)
    sum = 0
    count = 0.0
    reader.each do |r|
#        if r.defline =~ /merged/
            sum += r.getClearLen
            count += 1.0
            if count % 10000 == 0
                puts "Num seqs #{count} bases #{sum}"
            end
#        end
    end

    printf "%s %.1f\n", inFile , sum / count
end

system "grep VmPeak /proc/#{$$}/status"
