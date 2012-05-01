class DNAProfile
    attr_accessor :ref, :profile, :minQV, :inserts, :masks

    EMPTY_PROF = { 'A' => 0, 'C' => 0, 'G' => 0, 'T' => 0, '-' => 0}

    def initialize( refSequence, minQV )
        @minQV = minQV
        # ref goes from 0..N-1
        @ref = refSequence
        # profile goes from 1..N
        @profile = [nil]
        @ref.length.times do |i|
            @profile << EMPTY_PROF.dup
        end
        @inserts = {}
        @masks = []
    end

    def DNAProfile.init()
        new( '', 0 )
    end

    def deep_copy()
        Marshal.load(Marshal.dump(self))
    end

    def +(other)
        raise "Length mismatch" unless @profile.length == other.profile.length
        newProf = other.deep_copy()
        @profile.each_with_index do |p,i|
            next if i == 0
            p.each_pair {|k,v| newProf.profile[i][k] += v}
        end
        newProf
    end

    def depthAt( i )
        @profile[i].reduce {|a,b| [a[0]+b[0], a[1]+b[1]] }[1]
    end

    def sumAboveCov(other,minCov)
        raise "Length mismatch" unless @profile.length == other.profile.length
        newProf = DNAProfile.new( @ref, @minQV )
        @profile.length.times do |i|
            next if i == 0
            c1 =  self.depthAt( i )
            c2 = other.depthAt( i )
            if c1 >= minCov && c2 >= minCov
                newProf.profile[i] = @profile[i].merge(other.profile[i]) {|k,n,o| o+n}
            end
        end
        newProf
    end

    def incrProf( prof, base, qv )
        return if qv < @minQV

        if base == 'N'
            ['A','C','G','T'].each {|c| prof[c] += 0.25 }
        else
            prof[base] += 1
        end
    end

    # This method takes a read already aligned to the reference
    # it's quality values, and the reference start base of the alignment
    # and updates the profile with the reads bases, filtering out lowQV
    # bases
    #
    def addSequenceAt( start, seq, qv )
        # truncate sequence if start is before 1
        if start < 1
            startbase = 1 - start
            seq = seq[ startbase..-1 ]
            qv  =  qv[ startbase..-1 ]
            start = 1
        end

        if (mask = checkMask( start )) # start of read needs masking
            trimLen = mask[1] - start + 1
            start += trimLen
            seq = seq[ trimLen .. -1 ]
            qv =  qv[ trimLen .. -1 ]
        else # check end of read for masking
            refEnd = start + seq.length - 1
            if mask = checkMask( refEnd )
                trimLen = refEnd - mask[0] + 1
                goodLen = seq.length - trimLen
                seq = seq[ 0, goodLen ]
                qv =  qv[ 0, goodLen ]
            end
        end

        return unless seq

        seq.length.times do |i|
            # stop profile at end of reference
            return if i + start > @ref.length

            incrProf( @profile[i + start], seq[i,1], qv[i])
        end
    end

    def addInsert( insertAt, insertSeq, qv )
        gapSize = insertSeq.length
        # Make sure the profile's gap is a big as this gap
        if ! @inserts.has_key?( insertAt )
            @inserts[ insertAt ] = Array.new( gapSize ){ EMPTY_PROF.dup }

        elsif @inserts[ insertAt ].length < gapSize
            gapIncrease = gapSize - @inserts[ insertAt ].length
            gapIncrease.times {|c|  @inserts[ insertAt ] << EMPTY_PROF.dup }
        end
        gapSize.times { |i| incrProf( @inserts[insertAt][i], insertSeq[i,1], qv[i]) }
    end

    # This method takes takes the two equal length gapped seqs from a pairwise
    # alignment between a seq and the ref, and updates the profile at the
    # specified reference start base of the alignment
    #
    def addAlignmentAt( start, seq, refAlign, ungappedQv )
        raise "Length mismatch at #{start}" if seq.length != refAlign.length

        uQV = Array.new( ungappedQv )

        sl, sc, qvl = seq.length, seq.count('-'), uQV.length
        if sl - sc != qvl
            p refAlign
            p seq
            p uQV
            raise "QV Length mismatch at #{start} sl #{sl} sc #{sc} qvl #{qvl}"
        end

        qv = []
        seq.each_char do |base|
            if base == '-'
                qv << 66
            else
                qv << uQV.shift
            end
        end
        refCnt  = 0
        readCnt = 0
        seqChars = []
        refAlign.split(/(-+)/).each do |refChunk|
            ckSize = refChunk.length

            if refChunk[0,1] == '-'
                # a gap chunk, store the read bases in @inserts profiles
                addInsert( start + refCnt, seq[ readCnt, ckSize ],qv)
            else
                addSequenceAt( start + refCnt, seq[ readCnt, ckSize], qv)
                refCnt += ckSize
            end
            readCnt += ckSize
        end
    end

    def profLine( io, prof, refbase )
        hist = []
        max = 0
        maxBase = '' # dominant base at position
        # kelvin's profile order
        ['A','T','G','C','-'].each do |c|
            hist << prof[c]
            if prof[c] > max
                maxBase = c
                max = prof[c]
            end
        end
        maxBase = refbase if maxBase == ''
        io.puts "#{maxBase}\t#{hist.join("\t")}"
    end

    def print(io)
        @ref.length.times do |i|
            if @inserts.has_key? i+1
                @inserts[i+1].each {|p| profLine( io, p, @ref[i]) }
            end
            profLine( io, @profile[i+1], @ref[i] )
        end
    end

    def read(fileName)
        
        ref = []
        IO.foreach(fileName) do |line|
            con, a, t, g, c, gap = line.chomp.split "\t"
            ref << con
            @profile << { 'A' => a.to_f, 'T' => t.to_f, 'G' => g.to_f, 'C' => c.to_f, '-' => gap.to_i }
        end
        @ref = ref.join ''
    end

    def readMaskFile(fileName)
        IO.foreach( fileName ) do |line|
            fb,fe,rb,re = line.split(/[-,]/).map {|i| i.to_i}
            unless fe.between?( fb, rb) && rb.between?( fe, re)
                raise "Bad numerical ordering #{fb} #{fe} #{rb} #{re}"
            end
            @masks << [ fb, fe ]
            @masks << [ rb, re ]
        end

        @masks.sort! {|x,y| x[0] <=> y[0] }
    end

    def checkMask(position)
        @masks.each do |pair|
            return false if pair[ 0 ] > position

            if position.between?( pair[0], pair[1] )
                return [ pair[0], pair[1] ]
            end
        end
        false
    end

    def referenceDiffs(io)
        @ref.length.times do |i|
            rbase = @ref[i]
            p = i + 1
            if ! @profile[p]
                io.puts "#{p} #{rbase} - 0 0 0"
                next
            end
            agree = @profile[p][rbase] 
            disagree=0
            maxCnt = 0
            maxBase = ''
            @profile[p].each_pair do |k,v|
                if k != rbase
                    disagree += v
                    if v > maxCnt
                        maxBase = k
                        maxCnt = v
                    end
                end
            end
            if maxCnt > 3 && maxCnt >= 0.05 * agree # Go down to a 5% SNP
              io.puts "#{p} #{rbase} #{maxBase} #{maxCnt} #{agree} #{disagree}"
            end
            if @inserts.has_key?( p )
                j = 1
                @inserts[p].each do |prof|
                    sum = 0
                    maxCnt = 0
                    maxBase = ''
                    prof.each_pair do |base,cnt|
                        sum += cnt
                        if cnt > maxCnt
                            maxBase = base
                            maxCnt = cnt
                        end
                    end
                    if maxCnt > 19
                        io.puts "#{p}.#{j} - #{maxBase} #{maxCnt} 0 #{sum}"
                        j += 1
                    end
                end
            end
        end
    end

    private :profLine, :addInsert, :incrProf
end
