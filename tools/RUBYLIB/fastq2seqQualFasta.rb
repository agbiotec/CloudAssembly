#!/usr/local/devel/DAS/software/ruby1.9/bin/ruby
#!/usr/bin/env ruby

require 'Read'

if ARGV.length != 2
    puts "Usage: cmd <outputPrefix> <inputFastQ>

    Will create <outputPrefix>.fa and .qual files.
    "
    exit 1
end

prefix = ARGV.shift
fastqIn = ARGV.shift

seqOut = FastaWriter.new("#{prefix}.fa",false)
qualOut = FastaWriter.new("#{prefix}.qual",true)

input = FastqReader.new( fastqIn )

input.each do |seq|
    seqOut.write( seq )
    qualOut.write( seq )
end
