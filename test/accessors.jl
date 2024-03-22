import Dates
using Dates: Second, Millisecond

warsaw = first(compile("Europe/Warsaw", tzdata["europe"]))
fixed = FixedTimeZone("Fixed", -7200, 3600)

# ZonedDateTime accessors
zdt = ZonedDateTime(DateTime(2014,6,12,23,59,58,57), fixed)
@test timezone(zdt) === fixed

@test TimeZones.days(zdt) == 735396
@test TimeZones.hour(zdt) == 23
@test TimeZones.minute(zdt) == 59
@test TimeZones.second(zdt) == 58
@test TimeZones.millisecond(zdt) == 57

@test eps(zdt) == Millisecond(1)

# Make sure that Dates accessors work with ZonedDateTime.
@test Dates.year(zdt) == 2014
@test Dates.month(zdt) == 6
@test Dates.week(zdt) == 24
@test Dates.day(zdt) == 12
@test Dates.dayofmonth(zdt) == 12
@test Dates.yearmonth(zdt) == (2014, 6)
@test Dates.monthday(zdt) == (6, 12)
@test Dates.yearmonthday(zdt) == (2014, 6, 12)

# Vectorized accessors
# Note: fill is used to test for size and equality.
n = 10
arr = fill(zdt, n)
@test TimeZones.hour.(arr) == fill(23, n)
@test TimeZones.minute.(arr) == fill(59, n)
@test TimeZones.second.(arr) == fill(58, n)
@test TimeZones.millisecond.(arr) == fill(57, n)

@test Dates.year.(arr) == fill(2014, n)
@test Dates.month.(arr) == fill(6, n)
@test Dates.day.(arr) == fill(12, n)
@test Dates.dayofmonth.(arr) == fill(12, n)
@test Dates.yearmonth.(arr) == fill((2014, 6), n)
@test Dates.monthday.(arr) == fill((6, 12), n)
@test Dates.yearmonthday.(arr) == fill((2014, 6, 12), n)


@testset "DateTime from ZonedDateTime" begin
    # Construct a ZonedDateTime from a DateTime and the reverse
    dt = DateTime(2019, 4, 11, 0)
    zdt = ZonedDateTime(dt, warsaw)
    @test DateTime(zdt) == DateTime(2019, 4, 11, 0)
    @test DateTime(zdt, UTC) == DateTime(2019, 4, 10, 22)

    # Converting between ZonedDateTime and DateTime isn't possible as it is lossy.
    @test_throws MethodError convert(DateTime, zdt)
    @test_throws MethodError convert(ZonedDateTime, dt)
end

@testset "Date from ZonedDateTime" begin
    date = Date(2018, 6, 14)
    zdt = ZonedDateTime(date, warsaw)
    @test Date(zdt) == Date(2018, 6, 14)
    @test Date(zdt, UTC) == Date(2018, 6, 13)

    # Converting between ZonedDateTime and Date isn't possible as it is lossy.
    @test_throws MethodError convert(Date, zdt)
    @test_throws MethodError convert(ZonedDateTime, date)
end

@testset "Time from ZonedDateTime" begin
    zdt = ZonedDateTime(2017, 8, 21, 0, 12, warsaw)
    @test Time(zdt) == Time(0, 12)
    @test Time(zdt, UTC) == Time(22, 12)

    # Converting between ZonedDateTime and Time isn't possible as it is lossy.
    @test_throws MethodError convert(Time, zdt)
    @test_throws MethodError convert(ZonedDateTime, Time(0))
end

@testset "FixedTimeZone from ZonedDateTime" begin
    zdt1 = ZonedDateTime(2014, 1, 1, warsaw)
    zdt2 = ZonedDateTime(2014, 6, 1, warsaw)
    @test FixedTimeZone(zdt1) == FixedTimeZone("CET", Second(Hour(1)))
    @test FixedTimeZone(zdt1) === zdt1.zone
    @test FixedTimeZone(zdt2) == FixedTimeZone("CEST", Second(Hour(1)), Second(Hour(1)))
    @test FixedTimeZone(zdt2) === zdt2.zone
end

@testset "TimeZone from ZonedDateTime" begin
    zdt = ZonedDateTime(2014, 1, 1, warsaw)
    @test TimeZone(zdt) === warsaw
end
