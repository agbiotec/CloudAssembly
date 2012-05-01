#!/usr/bin/env ruby

require 'Read'

reader = FrgReader.new('t1.frg')
i = 0
reader.each do |r|
    case i
    when 0
        puts "bad1" unless '1106467263184' == r.id
        puts "bad2" unless "CTCAG" == r.getRawSeq[0,5]
        puts "bad3" unless "GCCGA" == r.getRawSeq[-5,5]
    when 2
        puts r.getClearSeq.length
    end
    i+=1
end
