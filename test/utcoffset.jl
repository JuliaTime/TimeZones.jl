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

@test sprint(show, UTCOffset(0, 0)) == "UTCOffset(Second(0), Second(0))"
@test sprint(show, UTCOffset(3600, 7200)) == "UTCOffset(Second(3600), Second(7200))"

@test sprint(show, MIME("text/plain"), UTCOffset(0, 0)) == "UTC+0/+0"
@test sprint(show, MIME("text/plain"), UTCOffset(3600, 7200)) == "UTC+1/+2"
