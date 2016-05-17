import TimeZones: UTCOffset, value, isdst

@test value(UTCOffset(0, 0)) == 0
@test value(UTCOffset(3600, 0)) == 3600
@test value(UTCOffset(0, 3600)) == 3600
@test value(UTCOffset(-7200, 3600)) == -3600

@test string(UTCOffset(0, 0)) == "+00:00"
@test string(UTCOffset(3600, 0)) == "+01:00"
@test string(UTCOffset(0, 3600)) == "+01:00"
@test string(UTCOffset(-7200, 3600)) == "-01:00"
@test string(UTCOffset(-3661)) == "-01:01:01"

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

buffer = IOBuffer()
show(buffer, UTCOffset(0, 0))
@test takebuf_string(buffer) == "UTC+0/+0"
show(buffer, UTCOffset(3600, 7200))
@test takebuf_string(buffer) == "UTC+1/+2"
