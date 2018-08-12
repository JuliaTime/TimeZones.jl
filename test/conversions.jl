import Compat.Dates
using Mocking

utc = FixedTimeZone("UTC")
warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)
apia = resolve("Pacific/Apia", tzdata["australasia"]...)
midway = resolve("Pacific/Midway", tzdata["australasia"]...)

# Converting a Localized into a DateTime
dt = DateTime(2015, 1, 1, 0)
ldt = Localized(dt, warsaw)
@test DateTime(ldt) == dt

# Converting from Localized to DateTime isn't possible as it is always inexact.
@test_throws MethodError convert(DateTime, ldt)

# Vectorized accessors
n = 10
arr = fill(ldt, n)
@test Dates.DateTime.(arr) == fill(dt, n)

# now function
dt = now(Dates.UTC)::DateTime
ldt = now(warsaw)
@test ldt.timezone == warsaw
@test Dates.datetime2unix(TimeZones.utc(ldt)) ≈ Dates.datetime2unix(dt)

# today function
@test abs(today() - today(warsaw)) <= Dates.Day(1)
@test today(apia) - today(midway) == Dates.Day(1)

@testset "todayat" begin
    @testset "current time" begin
        local ldt = now(warsaw)
        now_time = Time(TimeZones.localtime(ldt))
        @test todayat(now_time, warsaw) == ldt
    end

    @testset "ambiguous" begin
        if !compiled_modules_enabled
            local patch = @patch today(tz::TimeZone) = Date(1916, 10, 1)
            apply(patch) do
                @test_throws AmbiguousTimeError todayat(Time(0), warsaw)
                @test todayat(Time(0), warsaw, 1) == Localized(1916, 10, 1, 0, warsaw, 1)
                @test todayat(Time(0), warsaw, 2) == Localized(1916, 10, 1, 0, warsaw, 2)
            end
        end
    end
end

# Changing time zones
dt = DateTime(2015, 1, 1, 0)
loc_utc = Localized(dt, utc; from_utc=true)
loc_warsaw = Localized(dt, warsaw; from_utc=true)

# Identical since Localized is immutable
@test astimezone(loc_utc, warsaw) === loc_warsaw
@test astimezone(loc_warsaw, utc) === loc_utc

# Localized to Unix timestamp (and vice versa)
@test TimeZones.localized2unix(Localized(1970, utc)) == 0
@test TimeZones.unix2localized(0) == Localized(1970, utc)

for dt in (DateTime(2013, 2, 13), DateTime(2016, 8, 11))
    local dt
    local ldt = Localized(dt, warsaw)
    offset = TimeZones.value(ldt.zone.offset)   # Total offset in seconds
    @test TimeZones.localized2unix(ldt) == datetime2unix(dt) - offset
end

@test isa(TimeZones.localized2unix(Localized(1970, utc)), Float64)
@test isa(TimeZones.localized2unix(Float32, Localized(1970, utc)), Float32)
@test isa(TimeZones.localized2unix(Int64, Localized(1970, utc)), Int64)
@test isa(TimeZones.localized2unix(Int32, Localized(1970, utc)), Int32)

@test TimeZones.localized2unix(Localized(1970, 1, 1, 0, 0, 0, 750, utc)) == 0.75
@test TimeZones.localized2unix(Float32, Localized(1970, 1, 1, 0, 0, 0, 750, utc)) == 0.75
@test TimeZones.localized2unix(Int64, Localized(1970, 1, 1, 0, 0, 0, 750, utc)) == 0
@test TimeZones.localized2unix(Int32, Localized(1970, 1, 1, 0, 0, 0, 750, utc)) == 0

# round-trip
ldt = Localized(2010, 1, 2, 3, 4, 5, 999, utc)
round_trip = TimeZones.unix2localized(TimeZones.localized2unix(ldt))
@test round_trip == ldt

# millisecond loss
ldt = Localized(2010, 1, 2, 3, 4, 5, 999, utc)
round_trip = TimeZones.unix2localized(TimeZones.localized2unix(Int64, ldt))
@test round_trip != ldt
@test round_trip == floor(ldt, Dates.Second(1))

# timezone loss
ldt = Localized(2010, 1, 2, 3, 4, 5, warsaw)
round_trip = TimeZones.unix2localized(TimeZones.localized2unix(Int64, ldt))
@test round_trip == ldt
@test !isequal(round_trip, ldt)

# restrict vs relax
relaxed_ldt = TimeZones.relax(ldt)
ambiguous = Localized(DateTime(2015, 10, 25, 2), warsaw; strict=false)   # Ambiguous hour in Warsaw
nonexistent = Localized(DateTime(2014, 3, 30, 2), warsaw; strict=false)  # Non-existent hour in Warsaw

@test !TimeZones.isstrict(relaxed_ldt)
@test_throws AmbiguousTimeError TimeZones.restrict(ambiguous)
@test_throws NonExistentTimeError TimeZones.restrict(nonexistent)

# Julian dates
jd = 2457241.855
jd_loc = Localized(Dates.julian2datetime(jd), warsaw, from_utc=true)
@test TimeZones.localized2julian(jd_loc) == jd
@test TimeZones.localized2julian(Int, jd_loc) === floor(Int, jd)
@test TimeZones.localized2julian(Float64, jd_loc) === jd
@test TimeZones.julian2localized(jd) == jd_loc
