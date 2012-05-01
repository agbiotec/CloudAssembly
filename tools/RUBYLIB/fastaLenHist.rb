#!/usr/local/devel/DAS/software/ruby1.9/bin/ruby

require 'rsruby'
require 'Read'

# Need R_HOME and LD_LIBRARY_PATH set
# In testing I used
# R_HOME=/usr/local/packages/R-2.10.1/lib64/R
# LD_LIBRARY_PATH=$R_HOME/lib

lens = []
reader = FastaReader.new(ARGF)
reader.each do |read|
    lens << read.getClearLen()
end

R = RSRuby.instance
R.png("readLengthHist.png")
R.hist(lens, :xlab =>"Read Length",:main => "Read Length Histogram")
R.eval_R("dev.off()")
