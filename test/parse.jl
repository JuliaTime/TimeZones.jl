import Compat.Dates: parse_components, default_format

@testset "parse" begin
    @test isequal(
        parse(ZonedDateTime, "2017-11-14 11:03:53 +0100", dateformat"yyyy-mm-dd HH:MM:SS zzzzz"),
        ZonedDateTime(2017, 11, 14, 11, 3, 53, tz"UTC+01"),
    )
    @test isequal(
        parse(ZonedDateTime, "2016-04-11 08:00 UTC", dateformat"yyyy-mm-dd HH:MM ZZZ"),
        ZonedDateTime(2016, 4, 11, 8, tz"UTC"),
    )
    # two-digit time zone
    @test isequal(
        parse(ZonedDateTime, "2000+00", dateformat"yyyyz"),
        ZonedDateTime(2000, tz"UTC"),
    )
    @test_throws ArgumentError parse(ZonedDateTime, "2016-04-11 08:00 EST", dateformat"yyyy-mm-dd HH:MM zzz")
    # test AbstractString
    @test isequal(
        parse(ZonedDateTime, Test.GenericString("2018-01-01 00:00 UTC"), dateformat"yyyy-mm-dd HH:MM ZZZ"),
        ZonedDateTime(2018, 1, 1, 0, tz"UTC"),
    )

end

@testset "tryparse" begin
    @test isequal(
        tryparse(ZonedDateTime, "2013-03-20 11:00:00+04:00", dateformat"y-m-d H:M:SSz"),
        TimeZones.nullable(ZonedDateTime, ZonedDateTime(2013, 3, 20, 11, tz"UTC+04")),
    )
    @test isequal(
        tryparse(ZonedDateTime, "2016-04-11 08:00 EST", dateformat"yyyy-mm-dd HH:MM zzz"),
        TimeZones.nullable(ZonedDateTime, nothing),
    )
end

@testset "parse components" begin
    local test = ("2017-11-14 11:03:53 +0100", dateformat"yyyy-mm-dd HH:MM:SS zzzzz")
    local expected = [
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

@testset "default format" begin
    @test default_format(ZonedDateTime) === TimeZones.ISOZonedDateTimeFormat
end
