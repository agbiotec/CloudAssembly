#!/usr/bin/env ruby1.9

require 'test/unit'

require 'Read'

class BioReadTests < Test::Unit::TestCase

    def test_001_roundtrip_fasta
        assert_not_nil( FileTest.exists?( 't1.fa' ) )

        tout = 'tout.fa'
        reader = FastaReader.new('t1.fa')
        writer = FastaWriter.new(tout)
        reads = []
        reader.each_with_index do |read,i|
            writer.write( read )
            reads << read
            if i == 0
                assert_equal( 'id1', read.id )
                assert_equal( 'ACGTgcgtagctcgtctgct', read.getRawSeq )
            elsif i == 1
                assert_equal( 'id2', read.id )
                assert_equal( 'ATGCCgtagcatcTGCTtcgATgc', read.getRawSeq )
            else
                assert_equal( true, false)
            end

        end
        writer.close()
        reader = FastaReader.new(tout)
        reader.each_with_index do |read,i|
            assert_equal(reads[i].getRawSeq, read.getRawSeq)
            assert_equal(reads[i].id, read.id)
        end
        File.unlink(tout)
    end
    def test_002_read_qv_fasta
        assert_not_nil( FileTest.exists?( 't2.fa' ) )

        i = 0;
        reader = FastaReader.new('t2.fa')
        reader.each do |read|
            if i == 0
                assert_equal( 'id1', read.id )
                assert_equal( [10,3,5,40,20,30,5,43], read.getRawQV )
            end
            i+=1
        end
        assert_equal( i, 1 )
    end

    def test_003_fasta_read_lengths
        assert_not_nil( FileTest.exists?( 't1.fa' ) )

        reader = FastaReader.new('t1.fa')
        lens = reader.map { |read| read.getRawLen }
        assert_equal( 20, lens[0] )
        assert_equal( 24, lens[1] )
    end

    def test_004_frg_read_count
        assert_not_nil( FileTest.exists?( 't1.frg' ) )

        reader = FrgReader.new('t1.frg')
        i = 0
        reader.each {|r| i+= 1 }
        assert_equal( 3, i )
    end

    def test_005_frg_read_correct
        reader = FrgReader.new('t1.frg')
        i = 0
        reader.each do |r|
            case i
            when 0
                assert_equal('1106467263184', r.id)
                assert_equal("CTCAG",r.getRawSeq[0,5])
                assert_equal("GCCGA",r.getRawSeq[-5,5])
            when 1
                assert_equal('1106467263185', r.id)
                assert_equal("CTCCG",r.getRawSeq[0,5])

            when 2
                assert_equal('1106514380619', r.id)
                assert_equal("TTACGA",r.getRawSeq[0,6])
                assert_equal(54 - 48, r.getRawQV()[0] )
                assert_equal(57 - 48, r.getRawQV()[-1] )
                assert_equal( 22, r.clearBegin )
                assert_equal( 943, r.clearEnd )
                assert_equal( 943 - 22, r.getClearSeq.length )
            end
            i += 1
        end
    end

    def test_006_roundtrip_fastq
        assert_not_nil( FileTest.exists?( 't1.fq' ) )

        tout = 'tout.fq'
        reader = FastqReader.new('t1.fq')
        writer = FastqWriter.new(tout)
        reads = []
        reader.each_with_index do |read,i|
            writer.write(read)
            reads << read
            if i == 0
                assert_equal( 'SOLEXA1:5:1:15:1834#0/1', read.id )
                assert_equal( 'GGAAAAAGACAACAAAAAGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGAGAAAAAAAAAAAAAAAC',
                             read.getRawSeq )
                assert_equal( 14, read.getRawQV()[0] )
                assert_equal( 2, read.getRawQV()[read.getRawLen()-1] )
            elsif i == 1
                assert_equal( 'SOLEXA1:5:1:16:1956#0/1', read.id )
                assert_equal( 'AATTATCTTGATAAAGCAGGAATTACTACTGCTTGTTTATGAATTAAATTGAAGTGGACTGGGGGGGGGGAATGG',
                             read.getRawSeq )
                assert_equal( 33, read.getRawQV()[0] )
                assert_equal( 2, read.getRawQV()[read.getRawLen()-1] )
            else
                assert_equal( true, false)
            end
        end
        writer.close()
        reader = FastqReader.new(tout)
        reader.each_with_index do |read,i|
            assert_equal(reads[i].id, read.id)
            assert_equal(reads[i].getRawSeq, read.getRawSeq)
        end
        File.unlink(tout)
    end

    def test_007_read_clr
        seq = 'TATCTTGATAAAGCAGG' # 17 bases
        clr =    'CTTGATAAAG'
        clrCoords = [3,13] # space based coords
        read = Read.new()
        read.sequence = seq
        read.clearBegin,read.clearEnd = clrCoords
        assert_equal( clr, read.getClearSeq())
    end

    def test_008_fastq2fasta
        assert_not_nil( FileTest.exists?( 't1.fq' ) )

        tout = 'tout.fa'
        reader = FastqReader.new('t1.fq')
        writer = FastaWriter.new(tout)
        reads = []
        reader.each_with_index do |read,i|
            writer.write( read )
            reads << read
        end
        writer.close()
        reader = FastaReader.new(tout)
        reader.each_with_index do |read,i|
            assert_equal(reads[i].id, read.id)
            assert_equal(reads[i].getRawSeq, read.getRawSeq)
        end
        File.unlink(tout)
    end
end
