
class ElandLine

    attr_accessor :readName, :seq, :qvList, :chrom, :offset, :strand, :filter


#    1                                5                                   10
#my( $MACHINE, $RUNNUM, $LANE, $TILE, $XC, $YC, $IDXSTR, $READNUM, $READ, $QV,
    # 11                           15                     17
#    $CHROM, $CTG, $BEG, $STRAND, $DESC, $SINGLESCORE, $PAIRSCORE,
    # 18                                   22
#    $PCHROM, $PCTG, $POFFSET, $PSTRAND, $FILTER  ) = ( 0 .. 21 );

    def initialize(line)
        cols = line.chomp.split "\t"
        name = [ cols[0], cols[2,4] ]
        @readName = name.flatten.join(':') + '#' + cols[6] + '/' + cols[ 7 ] 
        @seq    = cols[ 8 ]
        @qvList = cols[ 9 ].each_byte.map {|i| i - 64 }
        @chrom  = cols[ 10 ]
        @offset = cols[ 12 ].to_i
        @strand = cols[ 13 ]
        @filter = cols[ 21 ]
    end

    def isForward?()
        @strand == 'F'
    end

    def isReverse?()
        @strand == 'R'
    end

    def passed_filter?()
        @filter == 'Y'
    end

    # read failed to map due to N's
    def unmapped_Ns?()
        @chrom == 'QC'
    end

    def unmapped?()
        @chrom == 'NM'
    end

    def seqLen()
        @seq.length
    end

    #This function returns true if the read mapps uniquely to the reference
    #false otherwise.

    def mapsUnique?()
        return false unless passed_filter?
        return false if unmapped_Ns? || unmapped?
        if @chrom =~ /^\d+:\d+:\d+$/
            false
        else
            true
        end
    end

    # This method returns the QV at the given position for this read.
    def getQVat(start, stop)
        stop ||= start
        @qvList[ start .. stop ].join '_'
    end

end
