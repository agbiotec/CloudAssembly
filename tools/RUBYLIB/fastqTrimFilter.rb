#!/usr/local/devel/DAS/software/ruby1.9/bin/ruby
#!/usr/bin/env ruby

require 'Read'

if ! [2,3].member? ARGV.length
    puts "Usage: cmd trimFile [id map file] < [Fastq2Trim] > [trimmedFastq]

    Will trim and filter the input fastq based on the trimFile.
    Trim file format follows, using space based coordinates:

    readId clearStart clearEnd

    "
    exit 1
end

trimFile = ARGV.shift
trimPoints = {}
idMap = {} # allow a file remapping the id's since fuzznuc truncates solexa IDs

if ARGV.length > 0
    idMapFile = ARGV.shift
    IO.foreach(idMapFile) do |line|
        num,id = line.chomp.split
        idMap[ num ] = id
    end
end

IO.foreach(trimFile) do |line|
    readId, clrBeg, clrEnd = line.split
    if idMap.has_key? readId
        readId = idMap[ readId ]
    end
    trimPoints[ readId ] = [ clrBeg.to_i, clrEnd.to_i ]
end

input  = FastqReader.new( ARGF )
output = FastqWriter.new( STDOUT )

input.each do |seq|
    if trimPoints.has_key? seq.id
        seq.clearBegin, seq.clearEnd = trimPoints[ seq.id ]
        output.write( seq )
    end
end
