#!/usr/bin/env ruby

require 'bio'

#hist = Hash.new(0)

query = "ITS2"
Bio::NCBI.default_email = 'eventer@jcvi.org'

Bio::PubMed.esearch( query, {'retmax'=> 500000} ).each do |id|
#    Bio::PubMed.efetch(id) =~ /JT\s+-\s+(.*)/
#    hist[ $1 ] += 1
    puts id
end

#sorted = hist.sort {|a,b| b[1]<=>a[1] }
#most = sorted[0]
#puts "Journal: #{most[0]} Count #{most[1]}"
