#!/usr/local/devel/DAS/software/ruby1.9/bin/ruby
#!/usr/bin/env ruby

require 'set'
require 'Read'

if ARGV.length != 2
    puts "Usage: #{$0} seqIDFile fastQFiles > [filteredFastq]
    Outputs a sequence only if it's in the given list
    "
    exit 1
end

idFile = ARGV.shift
ids = Set.new()

IO.foreach(idFile) do |line|
    readId = line.chomp
    ids.add( readId )
end

input  = FastqReader.new( ARGF )
output = FastqWriter.new( STDOUT )

input.each do |seq|
    if ids.member? seq.id
        output.write( seq )
    end
end
