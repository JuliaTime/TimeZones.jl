using Dates: Dates, Second, Millisecond

warsaw = first(compile("Europe/Warsaw", tzdata["europe"]))
fixed = FixedTimeZone("Fixed", -7200, 3600)

# ZonedDateTime accessors
zdt = ZonedDateTime(DateTime(2014,6,12,23,59,58,57), fixed)
@test timezone(zdt) === fixed

@test eps(zdt) == Millisecond(1)

# Ensure changes to Dates.jl don't break support for ZonedDateTime
@testset "accessors" begin
    # Dates.jl accessors heavily rely on using `days`.
    @test Dates.days(zdt) == 735396

    @test Dates.year(zdt) == 2014
    @test Dates.quarterofyear(zdt) == 2
    @test Dates.month(zdt) == 6
    @test Dates.week(zdt) == 24
    @test Dates.day(zdt) == 12
    @test Dates.hour(zdt) == 23
    @test Dates.minute(zdt) == 59
    @test Dates.second(zdt) == 58
    @test Dates.millisecond(zdt) == 57

    @test Dates.dayofmonth(zdt) == 12
    @test Dates.yearmonth(zdt) == (2014, 6)
    @test Dates.monthday(zdt) == (6, 12)
    @test Dates.yearmonthday(zdt) == (2014, 6, 12)
end

@testset "Period constructors" begin
    @test Dates.Year(zdt) == Dates.Year(2014)
    @test Dates.Quarter(zdt) == Dates.Quarter(2)
    @test Dates.Month(zdt) == Dates.Month(6)
    @test Dates.Week(zdt) == Dates.Week(24)
    @test Dates.Day(zdt) == Dates.Day(12)
    @test Dates.Hour(zdt) == Dates.Hour(23)
    @test Dates.Minute(zdt) == Dates.Minute(59)
    @test Dates.Second(zdt) == Dates.Second(58)
    @test Dates.Millisecond(zdt) == Dates.Millisecond(57)
end

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
