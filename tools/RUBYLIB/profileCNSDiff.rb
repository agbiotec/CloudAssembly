#!/usr/bin/env ruby

require 'DNAProfile'

inFile = ARGV.shift

prof = DNAProfile.init()
prof.read( inFile )

prof.profile.each_with_index do |p,i|
    next if i == 0
    max = p.max
#    depth = p.values.reduce {|s,v| s+=v}
    if prof.ref[ i-1 ] != max[0]
       puts "#{i} #{max[0]} #{max[1]}"
    end
end 
