#!/usr/bin/env ruby

require 'test/unit'

require 'DNAProfile'

class DNAProfileTests < Test::Unit::TestCase

    def test_001_add
        a = DNAProfile.init
        a.profile << { 'A' => 10, 'G' => 15, 'T' => 20, 'C' => 25, '-' => 5} 
        b = DNAProfile.init
        b.profile << { 'A' => 10, 'G' => 15, 'T' => 20, 'C' => 25, '-' => 5} 

        c = a + b
        c.ref = "A"
        assert_equal(20, c.profile[1]['A'])
        assert_equal(30, c.profile[1]['G'])
        assert_equal(40, c.profile[1]['T'])
        assert_equal(50, c.profile[1]['C'])
        assert_equal(10, c.profile[1]['-'])

        assert_equal(10, a.profile[1]['A'])
        assert_equal(15, a.profile[1]['G'])
        assert_equal(20, a.profile[1]['T'])
        assert_equal(25, a.profile[1]['C'])
        assert_equal(5, a.profile[1]['-'])

        assert_equal(10, b.profile[1]['A'])
        assert_equal(15, b.profile[1]['G'])
        assert_equal(20, b.profile[1]['T'])
        assert_equal(25, b.profile[1]['C'])
        assert_equal(5, b.profile[1]['-'])
    end

    def test_002_aligned_seq
        refAln = 'ACGT--TGC'
        read   = 'A--TGCTGC'
        ref = refAln.tr '-','' 
        prof = DNAProfile.new(ref,20)
        prof.addAlignmentAt( 1, read, refAln, Array.new(ref.length,40))

        assert_equal( 7, prof.ref.length())
        assert_equal( 8, prof.profile.length())
        assert_equal( 1, prof.inserts.length())
        assert_equal( 1, prof.profile[1]['A'] ) 
        assert_equal( 0, prof.profile[1]['T'] ) 
        assert_equal( 0, prof.profile[1]['C'] ) 
        assert_equal( 0, prof.profile[1]['G'] ) 
        assert_equal( 0, prof.profile[1]['-'] ) 
        assert_equal( 1, prof.profile[2]['-'] ) 
        assert_equal( 1, prof.profile[3]['-'] ) 
        assert_equal( 1, prof.profile[4]['T'] ) 
        assert_equal( 1, prof.profile[5]['T'] ) 
        assert_equal( 1, prof.profile[6]['G'] ) 
        assert_equal( 1, prof.profile[7]['C'] ) 

#        prof.insertGaps()
#        assert_equal( 10, prof.profile.length())
#        assert_equal( 1, prof.profile[1]['A'] ) 
#        assert_equal( 1, prof.profile[2]['-'] ) 
#        assert_equal( 1, prof.profile[3]['-'] ) 

    end

    def test_003_mask_seq
        ref  = 'ACGTTGC'
        read = 'ATGCTGC'
        prof = DNAProfile.new(ref,20)
        prof.masks << [ 1,3 ]
        prof.addSequenceAt( 1, read, Array.new(ref.length,40))

        assert_equal( 7, prof.ref.length())
        assert_equal( 8, prof.profile.length())
        assert_equal( 0, prof.inserts.length())
        assert_equal( 0, prof.profile[1]['A'] ) 
        assert_equal( 0, prof.profile[1]['T'] ) 
        assert_equal( 0, prof.profile[1]['C'] ) 
        assert_equal( 0, prof.profile[1]['G'] ) 
        assert_equal( 0, prof.profile[1]['-'] ) 

        assert_equal( 0, prof.profile[2]['A'] ) 
        assert_equal( 0, prof.profile[2]['T'] ) 
        assert_equal( 0, prof.profile[2]['C'] ) 
        assert_equal( 0, prof.profile[2]['G'] ) 
        assert_equal( 0, prof.profile[2]['-'] ) 

        assert_equal( 0, prof.profile[3]['A'] ) 
        assert_equal( 0, prof.profile[3]['T'] ) 
        assert_equal( 0, prof.profile[3]['C'] ) 
        assert_equal( 0, prof.profile[3]['G'] ) 
        assert_equal( 0, prof.profile[3]['-'] ) 

        assert_equal( 0, prof.profile[4]['A'] ) 
        assert_equal( 0, prof.profile[4]['T'] ) 
        assert_equal( 1, prof.profile[4]['C'] ) 
        assert_equal( 0, prof.profile[4]['G'] ) 
        assert_equal( 0, prof.profile[4]['-'] ) 

        assert_equal( 0, prof.profile[5]['A'] ) 
        assert_equal( 1, prof.profile[5]['T'] ) 
        assert_equal( 0, prof.profile[5]['C'] ) 
        assert_equal( 0, prof.profile[5]['G'] ) 
        assert_equal( 0, prof.profile[5]['-'] ) 

        assert_equal( 0, prof.profile[6]['A'] ) 
        assert_equal( 0, prof.profile[6]['T'] ) 
        assert_equal( 0, prof.profile[6]['C'] ) 
        assert_equal( 1, prof.profile[6]['G'] ) 
        assert_equal( 0, prof.profile[6]['-'] ) 

        assert_equal( 0, prof.profile[7]['A'] ) 
        assert_equal( 0, prof.profile[7]['T'] ) 
        assert_equal( 1, prof.profile[7]['C'] ) 
        assert_equal( 0, prof.profile[7]['G'] ) 
        assert_equal( 0, prof.profile[7]['-'] ) 
    end

    def test_004_mask_align_seq
        refAln = 'ACGT--TGC'
        read   = 'A--TGCTGC'
        ref = refAln.tr '-','' 
        prof = DNAProfile.new(ref,20)
        prof.masks << [ 6,7 ]
        prof.addAlignmentAt( 1, read, refAln, Array.new(ref.length,40))

        assert_equal( 7, prof.ref.length())
        assert_equal( 8, prof.profile.length())
        assert_equal( 1, prof.inserts.length())
        assert_equal( 1, prof.profile[1]['A'] ) 
        assert_equal( 0, prof.profile[1]['T'] ) 
        assert_equal( 0, prof.profile[1]['C'] ) 
        assert_equal( 0, prof.profile[1]['G'] ) 
        assert_equal( 0, prof.profile[1]['-'] ) 

        assert_equal( 1, prof.profile[2]['-'] ) 
        assert_equal( 1, prof.profile[3]['-'] ) 
        assert_equal( 1, prof.profile[4]['T'] ) 
        assert_equal( 1, prof.profile[5]['T'] ) 
        assert_equal( 0, prof.profile[6]['G'] ) 
        assert_equal( 0, prof.profile[7]['C'] ) 
    end

    def test_005_mask_readgap_align_seq
        refAln = 'ACGT--TGC'
        read   = 'A--TGCTGC'
        ref = refAln.tr '-','' 
        prof = DNAProfile.new(ref,20)
        prof.masks << [ 1,2 ]
        prof.addAlignmentAt( 1, read, refAln, Array.new(ref.length,40))

        assert_equal( 7, prof.ref.length())
        assert_equal( 8, prof.profile.length())
        assert_equal( 1, prof.inserts.length())
        assert_equal( 0, prof.profile[1]['A'] ) 
        assert_equal( 0, prof.profile[1]['T'] ) 
        assert_equal( 0, prof.profile[1]['C'] ) 
        assert_equal( 0, prof.profile[1]['G'] ) 
        assert_equal( 0, prof.profile[1]['-'] ) 

        assert_equal( 0, prof.profile[2]['-'] ) 
        assert_equal( 1, prof.profile[3]['-'] ) 
        assert_equal( 1, prof.profile[4]['T'] ) 
        assert_equal( 1, prof.profile[5]['T'] ) 
        assert_equal( 1, prof.profile[6]['G'] ) 
        assert_equal( 1, prof.profile[7]['C'] ) 
    end

    def test_006_mask_refgap_align_seq
        ref    = 'TCACGTTGCTG'
        refAln =   'ACGTT-GC'
        read   =   'ATGCTAGC'
        prof = DNAProfile.new(ref,20)
        prof.masks << [ 8,11 ]
        prof.addAlignmentAt( 3, read, refAln, Array.new(read.length,40))

        assert_equal( 11, prof.ref.length())
        assert_equal( 12, prof.profile.length())
        assert_equal( 1, prof.inserts.length())

        assert_equal( 0, prof.profile[1]['A'] ) 
        assert_equal( 0, prof.profile[1]['T'] ) 
        assert_equal( 0, prof.profile[1]['C'] ) 
        assert_equal( 0, prof.profile[1]['G'] ) 
        assert_equal( 0, prof.profile[1]['-'] ) 

        assert_equal( 0, prof.profile[2]['A'] ) 
        assert_equal( 0, prof.profile[2]['T'] ) 
        assert_equal( 0, prof.profile[2]['C'] ) 
        assert_equal( 0, prof.profile[2]['G'] ) 
        assert_equal( 0, prof.profile[2]['-'] ) 

        assert_equal( 1, prof.profile[3]['A'] ) 
        assert_equal( 0, prof.profile[3]['T'] ) 
        assert_equal( 0, prof.profile[3]['C'] ) 
        assert_equal( 0, prof.profile[3]['G'] ) 
        assert_equal( 0, prof.profile[3]['-'] ) 

        assert_equal( 0, prof.profile[4]['A'] ) 
        assert_equal( 1, prof.profile[4]['T'] ) 
        assert_equal( 0, prof.profile[4]['C'] ) 
        assert_equal( 0, prof.profile[4]['G'] ) 
        assert_equal( 0, prof.profile[4]['-'] ) 

        assert_equal( 0, prof.profile[5]['A'] ) 
        assert_equal( 0, prof.profile[5]['T'] ) 
        assert_equal( 0, prof.profile[5]['C'] ) 
        assert_equal( 1, prof.profile[5]['G'] ) 
        assert_equal( 0, prof.profile[5]['-'] ) 

        assert_equal( 0, prof.profile[6]['A'] ) 
        assert_equal( 0, prof.profile[6]['T'] ) 
        assert_equal( 1, prof.profile[6]['C'] ) 
        assert_equal( 0, prof.profile[6]['G'] ) 
        assert_equal( 0, prof.profile[6]['-'] ) 

        assert_equal( 0, prof.profile[7]['A'] ) 
        assert_equal( 1, prof.profile[7]['T'] ) 
        assert_equal( 0, prof.profile[7]['C'] ) 
        assert_equal( 0, prof.profile[7]['G'] ) 
        assert_equal( 0, prof.profile[7]['-'] ) 

        assert_equal( 0, prof.profile[8]['A'] ) 
        assert_equal( 0, prof.profile[8]['T'] ) 
        assert_equal( 0, prof.profile[8]['C'] ) 
        assert_equal( 0, prof.profile[8]['G'] ) 
        assert_equal( 0, prof.profile[8]['-'] ) 

        assert_equal( 0, prof.profile[9]['A'] ) 
        assert_equal( 0, prof.profile[9]['T'] ) 
        assert_equal( 0, prof.profile[9]['C'] ) 
        assert_equal( 0, prof.profile[9]['G'] ) 
        assert_equal( 0, prof.profile[9]['-'] ) 

        assert_equal( 0, prof.profile[10]['A'] ) 
        assert_equal( 0, prof.profile[10]['T'] ) 
        assert_equal( 0, prof.profile[10]['C'] ) 
        assert_equal( 0, prof.profile[10]['G'] ) 
        assert_equal( 0, prof.profile[10]['-'] ) 

        assert_equal( 0, prof.profile[11]['A'] ) 
        assert_equal( 0, prof.profile[11]['T'] ) 
        assert_equal( 0, prof.profile[11]['C'] ) 
        assert_equal( 0, prof.profile[11]['G'] ) 
        assert_equal( 0, prof.profile[11]['-'] ) 
    end

    def test_007_sumAboveCov
        ref    = 'TCACGTTGCTG'
        refAln =   'ACGTT-GC'
        read   =   'ATGCTAGC'
        prof = DNAProfile.new(ref,20)
        prof.masks << [ 8,11 ]
        qv = Array.new(read.length,40)
        prof.addAlignmentAt( 3, read, refAln, qv)
        prof.addAlignmentAt( 3, read, refAln, qv)
        prof.addAlignmentAt( 3, read, refAln, qv)

        qv = Array.new(ref.length,40)
        prof.addAlignmentAt( 1, ref, ref, qv)

        prof2 = DNAProfile.new(ref,20)
        prof2.addAlignmentAt( 1, ref, ref, qv)
        prof2.addAlignmentAt( 1, ref, ref, qv)
        prof2.addAlignmentAt( 1, ref, ref, qv)

        sum = prof.sumAboveCov( prof2, 3 )

        assert_equal( 0, sum.profile[1]['A'] ) 
        assert_equal( 0, sum.profile[1]['T'] ) 
        assert_equal( 0, sum.profile[1]['C'] ) 
        assert_equal( 0, sum.profile[1]['G'] ) 
        assert_equal( 0, sum.profile[1]['-'] ) 

        assert_equal( 0, sum.profile[2]['A'] ) 
        assert_equal( 0, sum.profile[2]['T'] ) 
        assert_equal( 0, sum.profile[2]['C'] ) 
        assert_equal( 0, sum.profile[2]['G'] ) 
        assert_equal( 0, sum.profile[2]['-'] ) 

        assert_equal( 7, sum.profile[3]['A'] ) 
        assert_equal( 0, sum.profile[3]['T'] ) 
        assert_equal( 0, sum.profile[3]['C'] ) 
        assert_equal( 0, sum.profile[3]['G'] ) 
        assert_equal( 0, sum.profile[3]['-'] ) 

        assert_equal( 0, sum.profile[4]['A'] ) 
        assert_equal( 3, sum.profile[4]['T'] ) 
        assert_equal( 4, sum.profile[4]['C'] ) 
        assert_equal( 0, sum.profile[4]['G'] ) 
        assert_equal( 0, sum.profile[4]['-'] ) 

        assert_equal( 0, sum.profile[5]['A'] ) 
        assert_equal( 0, sum.profile[5]['T'] ) 
        assert_equal( 0, sum.profile[5]['C'] ) 
        assert_equal( 7, sum.profile[5]['G'] ) 
        assert_equal( 0, sum.profile[5]['-'] ) 

        assert_equal( 0, sum.profile[6]['A'] ) 
        assert_equal( 4, sum.profile[6]['T'] ) 
        assert_equal( 3, sum.profile[6]['C'] ) 
        assert_equal( 0, sum.profile[6]['G'] ) 
        assert_equal( 0, sum.profile[6]['-'] ) 

        assert_equal( 0, sum.profile[7]['A'] ) 
        assert_equal( 7, sum.profile[7]['T'] ) 
        assert_equal( 0, sum.profile[7]['C'] ) 
        assert_equal( 0, sum.profile[7]['G'] ) 
        assert_equal( 0, sum.profile[7]['-'] ) 

        assert_equal( 0, sum.profile[8]['A'] ) 
        assert_equal( 0, sum.profile[8]['T'] ) 
        assert_equal( 0, sum.profile[8]['C'] ) 
        assert_equal( 0, sum.profile[8]['G'] ) 
        assert_equal( 0, sum.profile[8]['-'] ) 

        assert_equal( 0, sum.profile[9]['A'] ) 
        assert_equal( 0, sum.profile[9]['T'] ) 
        assert_equal( 0, sum.profile[9]['C'] ) 
        assert_equal( 0, sum.profile[9]['G'] ) 
        assert_equal( 0, sum.profile[9]['-'] ) 

        assert_equal( 0, sum.profile[10]['A'] ) 
        assert_equal( 0, sum.profile[10]['T'] ) 
        assert_equal( 0, sum.profile[10]['C'] ) 
        assert_equal( 0, sum.profile[10]['G'] ) 
        assert_equal( 0, sum.profile[10]['-'] ) 

        assert_equal( 0, sum.profile[11]['A'] ) 
        assert_equal( 0, sum.profile[11]['T'] ) 
        assert_equal( 0, sum.profile[11]['C'] ) 
        assert_equal( 0, sum.profile[11]['G'] ) 
        assert_equal( 0, sum.profile[11]['-'] ) 
    end

end
