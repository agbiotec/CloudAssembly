#!/usr/bin/env ruby

require 'Read'

barcodes = { 'ATCACG' => 'cov1', 'CGATGT' => 'cov2', 'TTAGGC' => 'cov3',
             'TGACCA' => 'cov4', 'ACAGTG' => 'cov5', 'GCCAAT' => 'cov6',
             'other' => 'other'
}

alpha = ['A','C','G','T','N']
oneOff = {}

barcodes.each do |barcode,name|
    name << '.fq'
    if File.exists?( name )
        raise "File already exists: #{name}"
    else
        barcodes[ barcode ] = FastqWriter.new(name)
    end
    next if barcode == 'other'
    # build table of all barcodes with 1 difference
    # not scalable much past a 7 sequence barcode
#    barcode.length.times do |i|
#        alpha.each do |a|
#            next if a == barcode[i,1]
#            one = barcode.dup
#            one[i] = a
#            oneOff[ one ] = barcode
#        end
#    end
end
        

ARGV.each do |file|
    reader = FastqReader.new(file)
    reader.each do |read|
        if read.id =~ /\d+#([ACGTN0]+)\//
            barcode = $1
            io = barcodes[ barcode ]
            io = barcodes[ oneOff[ barcode ] ] unless io
            io = barcodes[ 'other' ] unless io
            io.write( read )
        else
            puts "Couldn't parse read id: #{read.id}"
        end
    end
end
