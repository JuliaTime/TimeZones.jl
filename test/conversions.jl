import Dates
using Mocking

utc = FixedTimeZone("UTC")
warsaw = first(compile("Europe/Warsaw", tzdata["europe"]))
apia = first(compile("Pacific/Apia", tzdata["australasia"]))
midway = first(compile("Pacific/Midway", tzdata["australasia"]))

# Converting a ZonedDateTime into a DateTime
dt = DateTime(2015, 1, 1, 0)
zdt = ZonedDateTime(dt, warsaw)
@test DateTime(zdt) == dt

# Converting from ZonedDateTime to DateTime isn't possible as it is always inexact.
@test_throws MethodError convert(DateTime, zdt)

# Vectorized accessors
n = 10
arr = fill(zdt, n)
@test DateTime.(arr) == fill(dt, n)

# now function
dt = now(Dates.UTC)::DateTime
zdt = now(warsaw)
@test zdt.timezone == warsaw
@test datetime2unix(TimeZones.utc(zdt)) ≈ datetime2unix(dt)

# today function
@test abs(today() - today(warsaw)) <= Dates.Day(1)
@test today(apia) - today(midway) == Dates.Day(1)

@testset "todayat" begin
    @testset "current time" begin
        local zdt = now(warsaw)
        now_time = Time(TimeZones.localtime(zdt))
        @test todayat(now_time, warsaw) == zdt
    end

    @testset "ambiguous" begin
        local patch = @patch today(tz::TimeZone) = Date(1916, 10, 1)
        apply(patch) do
            @test_throws AmbiguousTimeError todayat(Time(0), warsaw)
            @test todayat(Time(0), warsaw, 1) == ZonedDateTime(1916, 10, 1, 0, warsaw, 1)
            @test todayat(Time(0), warsaw, 2) == ZonedDateTime(1916, 10, 1, 0, warsaw, 2)
        end
    end
end

# Changing time zones
dt = DateTime(2015, 1, 1, 0)
zdt_utc = ZonedDateTime(dt, utc; from_utc=true)
zdt_warsaw = ZonedDateTime(dt, warsaw; from_utc=true)

# Identical since ZonedDateTime is immutable
@test astimezone(zdt_utc, warsaw) === zdt_warsaw
@test astimezone(zdt_warsaw, utc) === zdt_utc

# ZonedDateTime to Unix timestamp (and vice versa)
@test datetime2unix(ZonedDateTime(1970, utc)) == 0
@test unix2datetime(0) == ZonedDateTime(1970, utc)

for dt in (DateTime(2013, 2, 13), DateTime(2016, 8, 11))
    local dt
    local zdt = ZonedDateTime(dt, warsaw)
    offset = TimeZones.value(zdt.zone.offset)   # Total offset in seconds
    @test datetime2unix(zdt) == datetime2unix(dt) - offset
end

@test isa(datetime2unix(ZonedDateTime(1970, utc)), Float64)
@test isa(datetime2unix(Float32, ZonedDateTime(1970, utc)), Float32)
@test isa(datetime2unix(Int64, ZonedDateTime(1970, utc)), Int64)
@test isa(datetime2unix(Int32, ZonedDateTime(1970, utc)), Int32)

@test datetime2unix(ZonedDateTime(1970, 1, 1, 0, 0, 0, 750, utc)) == 0.75
@test datetime2unix(Float32, ZonedDateTime(1970, 1, 1, 0, 0, 0, 750, utc)) == 0.75
@test datetime2unix(Int64, ZonedDateTime(1970, 1, 1, 0, 0, 0, 750, utc)) == 0
@test datetime2unix(Int32, ZonedDateTime(1970, 1, 1, 0, 0, 0, 750, utc)) == 0

# round-trip
zdt = ZonedDateTime(2010, 1, 2, 3, 4, 5, 999, utc)
round_trip = unix2datetime(datetime2unix(zdt))
@test round_trip == zdt

# millisecond loss
zdt = ZonedDateTime(2010, 1, 2, 3, 4, 5, 999, utc)
round_trip = unix2datetime(datetime2unix(Int64, zdt))
@test round_trip != zdt
@test round_trip == floor(zdt, Dates.Second(1))

# timezone loss
zdt = ZonedDateTime(2010, 1, 2, 3, 4, 5, warsaw)
round_trip = unix2datetime(datetime2unix(Int64, zdt))
@test round_trip == zdt
@test timezone(round_trip) != timezone(zdt)

# Julian dates
jd = 2457241.855
jd_zdt = ZonedDateTime(julian2datetime(jd), warsaw, from_utc=true)
@test datetime2julian(jd_zdt) == jd
@test datetime2julian(Int, jd_zdt) === floor(Int, jd)
@test datetime2julian(Float64, jd_zdt) === jd
@test datetime2julian(jd) == jd_zdt
