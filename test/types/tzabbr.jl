@testset "tz_abbr_encode" begin
    @test tz_abbr_encode('\0') == UInt8(0)
    @test tz_abbr_encode('A') == UInt8(1)
    @test tz_abbr_encode('Z') == UInt8(26)
    @test tz_abbr_encode('a') == UInt8(27)
    @test tz_abbr_encode('z') == UInt8(52)
    @test tz_abbr_encode('0') == UInt8(53)
    @test tz_abbr_encode('+') == UInt8(63)
    @test tz_abbr_encode('-') == UInt8(64)
    @test_throws ArgumentError tz_abbr_encode('?')
end

@testset "tz_abbr_decode" begin
    @test tz_abbr_decode(UInt8(0)) == '\0'
    @test tz_abbr_decode(UInt8(1)) == 'A'
    @test tz_abbr_decode(UInt8(26)) == 'Z'
    @test tz_abbr_decode(UInt8(27)) == 'a'
    @test tz_abbr_decode(UInt8(52)) == 'z'
    @test tz_abbr_decode(UInt8(53)) == '0'
    @test tz_abbr_decode(UInt8(63)) == '+'
    @test tz_abbr_decode(UInt8(64)) == '-'
    @test_throws ArgumentError tz_abbr_decode(UInt8(65))
end

@testset "TZAbbr" begin
    @testset "iteration" begin
        abbr = TZAbbr("X")

        x = iterate(abbr)
        @test x == ('X', 2)

        x = iterate(abbr, 2)
        @test x === nothing

        @test collect(TZAbbr("UTC")) == ['U', 'T', 'C']
    end

    @testset "codeunits" begin
        abbr = TZAbbr("UTC")

        @test ncodeunits(abbr) == 3
        @test codeunit(abbr) == UInt8
        @test codeunit(abbr, 1) == 'U'
    end

    @testset "getindex" begin
        abbr = TZAbbr("PDT")
        @test abbr[1] == 'P'
        @test abbr[2] == 'D'
        @test abbr[3] == 'T'
        @test_throws BoundsError abbr[4]
    end

    @testset "sizeof" begin
        @test sizeof(TZAbbr("")) == 6
        @test sizeof(TZAbbr("UTC")) == 6
        @test sizeof(TZAbbr("FOOBAR")) == 6
    end
end
