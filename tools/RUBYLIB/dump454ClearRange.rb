#!/usr/bin/env ruby

require 'Read'

input = FastaReader.new(ARGF)
input.each do |read|
    s = read.getRawSeq.reverse
    m = s.scan(/[a-z]+/)
    if m.size > 2
        raise "more then 2 blocks of lower case #{read.id}"
    end
    read.defline.match(/length=(\d+)/)
    len = $1.to_i
    beg = 1
    if m.size == 2
        beg += m[0].length
    end
    puts "#{read.id} #{beg} #{beg+len-1}"
end
