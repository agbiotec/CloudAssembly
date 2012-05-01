#!/usr/bin/env ruby

# == Synopsis
# Dumps a seq and qv clear range fasta from a frg file.
#
# == Usage
# frg2fasta.rb inputFrgFile outSeqFasta outQVFasta
#

require 'Read'
#require 'rdoc/usage'

#RDoc::usage() if 3 != ARGV.length()

frgFile = ARGV.shift
fastaOut = ARGV.shift
qvFstOut = ARGV.shift

input = FrgReader.new(frgFile)
fastaOut = FastaWriter.new(File.open(fastaOut,'w'),false)
qvOut    = FastaWriter.new(File.open(qvFstOut,'w'),true)

input.each do |read|
    fastaOut.write( read )
    qvOut.write( read )
end
