#!/usr/local/devel/DAS/software/ruby1.9/bin/ruby
#!/usr/bin/env ruby

require 'Read'


input  = FastqReader.new( ARGF )
input.each do |seq|
    puts seq.getClearQV().join ' '
end
