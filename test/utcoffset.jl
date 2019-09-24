using TimeZones: UTCOffset, value, isdst

@test value(UTCOffset(0, 0)) == 0
@test value(UTCOffset(3600, 0)) == 3600
@test value(UTCOffset(0, 3600)) == 3600
@test value(UTCOffset(-7200, 3600)) == -3600

@test string(UTCOffset(0, 0)) == "+00:00"
@test string(UTCOffset(3600, 0)) == "+01:00"
@test string(UTCOffset(0, 3600)) == "+01:00"
@test string(UTCOffset(-7200, 3600)) == "-01:00"
@test string(UTCOffset(-3661)) == "-01:01:01"
@test string(UTCOffset( 1800)) == "+00:30"
@test string(UTCOffset(-1800)) == "-00:30"

@test !isdst(UTCOffset(0))
@test !isdst(UTCOffset(0, 0))
@test isdst(UTCOffset(0, 3600))
@test isdst(UTCOffset(0, 7200))

# Arithmetic
dt = DateTime(2015, 1, 1)
@test dt + UTCOffset(7200, -3600) == dt + Hour(1)
@test dt - UTCOffset(7200, -3600) == dt - Hour(1)

# Comparisons
let a = UTCOffset(0, 0), b = UTCOffset(0, 0)
    @test a == b
    @test isequal(a, b)
end

let a = UTCOffset(0, 3600), b = UTCOffset(3600, 0)
    @test a != b
    @test !isequal(a, b)
end

let a = UTCOffset(7200, 3600), b = UTCOffset(3600, 7200)
    @test a != b

    # Treated as equal since some time zone representations adjust the standard
    # offset when dealing with midsummer time.
    @test isequal(a, b)
end

@test sprint(show_compact, UTCOffset(0, 0)) == "UTC+0/+0"
@test sprint(show_compact, UTCOffset(3600, 7200)) == "UTC+1/+2"

# Added: https://github.com/JuliaLang/julia/pull/30817
# Reverted for v1.2.0-rc1: https://github.com/JuliaLang/julia/pull/31727
# Reverted for v1.3.0-rc2: https://github.com/JuliaLang/julia/pull/32973
# Active discussion: https://github.com/JuliaLang/julia/pull/33178
if v"1.2.0-DEV.223" <= VERSION < v"1.2.0-pre.39" || v"1.3-DEV" <= VERSION < v"1.3.0-rc1.33" || v"1.4-DEV" <= VERSION
    @test sprint(show, UTCOffset(0, 0)) == "UTCOffset(Second(0), Second(0))"
    @test sprint(show, UTCOffset(3600, 7200)) == "UTCOffset(Second(3600), Second(7200))"
else
    @test sprint(show, UTCOffset(0, 0)) == "UTCOffset(0 seconds, 0 seconds)"
    @test sprint(show, UTCOffset(3600, 7200)) == "UTCOffset(3600 seconds, 7200 seconds)"
end

@test sprint(show, MIME("text/plain"), UTCOffset(0, 0)) == "UTC+0/+0"
@test sprint(show, MIME("text/plain"), UTCOffset(3600, 7200)) == "UTC+1/+2"
