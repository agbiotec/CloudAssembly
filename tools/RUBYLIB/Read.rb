class Read
    # only give write access, since read should go through getRaw or getClear
    attr_writer :sequence, :qv
    # clear range
    attr_accessor :id, :defline, :clearBegin, :clearEnd

    def initialize()
        @sequence = ''
        @qv = []
        @clearBegin = 0
        @clearEnd = 0
    end

    def getRawSeq()
        @sequence
    end

    def getRawQV()
        @qv
    end

    def getRawLen()
        @sequence.length
    end

    def getClearSeq()
        @sequence[ @clearBegin..@clearEnd-1 ] # space based coords
    end

    def getClearQV()
        @qv[ @clearBegin..@clearEnd-1 ] # space base coords
    end

    def getClearLen()
        @clearEnd - @clearBegin
    end

    def hasQV?()
        if @qv.length > 0
            true
        else
            false
        end
    end


    def merHist(merSize)
        seq = getRawSeq()
        hist = Hash.new(0)
        (seq.length-merSize+1).times { |i| hist[ seq[i,merSize] ] += 1 }
        hist
    end

    def reverseComplement()
        @qv.reverse!
        @sequence.reverse!
        @sequence.tr!('acgtACGT','tgcaTGCA')
    end
end

class FlatFileIO
    include Enumerable

    attr_reader :io, :path

    def initialize(fileName,mode='r')
        if fileName.is_a? String
            @path = fileName
            @io = File.open(fileName, mode)
        else
            @path = nil
            @io = fileName
        end
    end
    def close()
        @io.close
    end

    def FlatFileIO::readFiber(fileName)
        Fiber.new do
            file = new(fileName)
            file.each {|r| Fiber.yield r}
            file.close
        end
    end

end

class FastaReader < FlatFileIO
    def each()
        seq     = []
        lastdef = nil
        isQV = false
        @io.each do |line|
            if line =~ /^>/
                if seq.length > 0
                    yield fastaRecord( lastdef, seq, isQV )
                end
            lastdef = line
            seq = []
            else 
                isQV = true if !isQV && line =~ / /

                if isQV
                    seq.concat( line.split(' ').map {|c| c.to_i} )
                else
                    seq.push( line.chop )
                end
            end
        end
        yield fastaRecord( lastdef, seq, isQV )
    end

    def fastaRecord(line,seq,isQV)
        r = Read.new()
        if line =~ /^>(\S+)/
            r.id = $1
            r.defline = line.chomp[r.id.length+1..-1]
        else
            raise "Defline error: #{line}"
        end

        if isQV
            r.qv = seq
            r.clearEnd = seq.length + 1
        else
            s = seq.join ''
            r.sequence = s
            r.clearEnd = s.length + 1
        end
        r
    end
end

class FastaWriter < FlatFileIO

    attr_accessor :lineSize

    def initialize(file,wantQV=false)
        super(file,mode='w')
        @lineSize = 80
        @wantQV = wantQV
    end

    def write(read)
        @io.puts ">" + read.id + read.defline
        if @wantQV
            count = 0
            qv = read.getClearQV()
            while (count < qv.length)
                num = lineSize / 3
                @io.puts("#{qv[count,num].join ' '}")
                count += num
            end
        else
            seq = read.getClearSeq()
            0.step(seq.length, lineSize) {|i| @io.puts seq[i,lineSize]}
        end
    end

end

class FastqReader < FlatFileIO
    def each()
        seq     = []
        qv      = []
        lastdef = nil
        inQV    = false
        @io.each do |line|
            if inQV
                # Assume SANGER QVs
                qv.concat( line.chop.each_byte.map {|c| c - 33} )
                inQV = false
            elsif line =~ /^@/
                if seq.length > 0
                    yield fastqRecord( lastdef, seq, qv )
                end
                lastdef = line
                seq = []
                qv  = []
            elsif line =~ /^\+/ 
                inQV = true
            else
                seq.push( line.chop )
            end
        end
        yield fastqRecord( lastdef, seq, qv )
    end

    def fastqRecord(line,seq,qv)
        r = Read.new()
        if line =~ /^@(\S+)/
            r.id = $1
            r.defline = line.chomp[r.id.length+1..-1]
        else
            raise "Defline error: #{line}"
        end
        

        s = seq.join ''
        r.sequence = s
        r.clearEnd = s.length + 1
        r.qv = qv
        raise "length mismatch #{r.id}" if r.getRawLen() != r.getRawQV().length 
        r
    end
end

class FastqWriter < FlatFileIO

    attr_accessor :lineSize

    def initialize(fileHandle)
        super(fileHandle,mode='w')
        @lineSize = 200
    end

    def write(read)
        @io.puts "@#{read.id}"
        seq = read.getClearSeq()
        0.step(seq.length, lineSize) {|i| @io.puts seq[i,lineSize]}

        @io.puts "+"
        qv = read.getClearQV().map {|i| (i+64).chr }
        0.step(qv.length, lineSize) {|i| @io.puts qv[i,lineSize].join('')}
    end
end

class FrgReader < FlatFileIO
    def each()
        r = nil
        id = ''
        @io.each do |line|
            line.chop!
            case line[0,4]
            when 'acc:'
                r = Read.new()
                r.id = line[4..-1]
                r.defline = r.id

            when 'seq:'
                r.sequence = readSequence()

            when 'qlt:'
                # convert ASCII QV to int by subtracting ASCII 0 ie 48
                r.qv = readSequence().each_byte.map {|c| c - 48 }

            when 'clr:'
                r.clearBegin, r.clearEnd = line[4..-1].split(',').map {|i| i.to_i}
                yield r
            end

        end
    end

    def readSequence()
        seq = []
        @io.each do |s|
            s.chop!
            break if s == '.' 
            seq << s
        end
        seq.join ''
    end
end
