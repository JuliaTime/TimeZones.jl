import Compat.Dates: parse_components

@testset "parse" begin
    @test isequal(
        parse(ZonedDateTime, "2017-11-14 11:03:53 +0100", dateformat"yyyy-mm-dd HH:MM:SS zzzzz"),
        ZonedDateTime(2017, 11, 14, 11, 3, 53, tz"UTC+01"),
    )
    @test isequal(
        parse(ZonedDateTime, "2016-04-11 08:00 UTC", dateformat"yyyy-mm-dd HH:MM ZZZ"),
        ZonedDateTime(2016, 4, 11, 8, tz"UTC"),
    )
    @test_throws ArgumentError parse(ZonedDateTime, "2016-04-11 08:00 EST", dateformat"yyyy-mm-dd HH:MM zzz")
end

@testset "tryparse" begin
    @test isequal(
        tryparse(ZonedDateTime, "2013-03-20 11:00:00+04:00", dateformat"y-m-d H:M:SSz"),
        Nullable(ZonedDateTime(2013, 3, 20, 11, tz"UTC+04")),
    )
    @test isequal(
        tryparse(ZonedDateTime, "2016-04-11 08:00 EST", dateformat"yyyy-mm-dd HH:MM zzz"),
        Nullable{ZonedDateTime}(),
    )
end

@testset "parse components" begin
    test = ("2017-11-14 11:03:53 +0100", dateformat"yyyy-mm-dd HH:MM:SS zzzzz")
    expected = [
        Dates.Year(2017),
        Dates.Month(11),
        Dates.Day(14),
        Dates.Hour(11),
        Dates.Minute(3),
        Dates.Second(53),
        tz"UTC+01",
    ]
    @test parse_components(test...) == expected
end
