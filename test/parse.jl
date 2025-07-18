using Dates: parse_components
using TimeZones: ParseNextError, _parsesub_tzabbr, _parsesub_offset, _parsesub_time, _parsesub_tzdate, _parsesub_tz

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
        ZonedDateTime(2013, 3, 20, 11, tz"UTC+04"),
    )
    @test isequal(
        tryparse(ZonedDateTime, "2016-04-11 08:00 EST", dateformat"yyyy-mm-dd HH:MM zzz"),
        nothing,
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

@testset "parse constructor" begin
    @test isequal(
        ZonedDateTime("2000-01-02T03:04:05.006+0700"),
        ZonedDateTime(2000, 1, 2, 3, 4, 5, 6, tz"UTC+07")
    )
    @test isequal(
        ZonedDateTime("2000-01-02T03:04:05.006Z"),
        ZonedDateTime(2000, 1, 2, 3, 4, 5, 6, tz"UTC+00")
    )
    @test isequal(
        ZonedDateTime("2018-11-01-0600", dateformat"yyyy-mm-ddzzzz"),
        ZonedDateTime(2018, 11, 1, tz"UTC-06"),
    )
end

@testset "self parseable" begin
    zdt_args = Iterators.product(
        [0, 1, 10, 100, 1000, 2025, 10000],  # Year
        [1, 12],  # Month
        [3, 31],  # Day
        [0, 4, 23],  # Hour
        [0, 5, 55],  # Minute
        [0, 6, 56],  # Seconds
        [0, 7, 50, 77, 777],  # Milliseconds
        [tz"UTC-06", tz"UTC", tz"UTC+08:45", tz"UTC+14"],  # Time zones
    )
    for args in zdt_args
        zdt = ZonedDateTime(args...)
        @test zdt == parse(ZonedDateTime, string(zdt))
        @test zdt == ZonedDateTime(string(zdt))
    end
end

# Validate that error message contains the original string and the format used
@testset "contextual error" begin
    str = "2018-11-01"

    try
        parse(ZonedDateTime, str)
        @test false
    catch e
        @test e isa ArgumentError
        @test occursin(str, e.msg)
        @test occursin(string(TimeZones.ISOZonedDateTimeNoMillisecondFormat), e.msg)
    end

    try
        ZonedDateTime(str)
        @test false
    catch e
        @test e isa ArgumentError
        @test occursin(str, e.msg)
        @test occursin(string(TimeZones.ISOZonedDateTimeNoMillisecondFormat), e.msg)
    end
end

@testset "tryparsenext_fixedtz" begin
    using TimeZones: tryparsenext_fixedtz

    @testset "valid" begin
        @test tryparsenext_fixedtz("9959", 1, 4) == ("9959", 5)
        @test tryparsenext_fixedtz("99:59", 1, 5) == ("99:59", 6)

        @test tryparsenext_fixedtz("-99", 1, 3) == ("-99", 4)
        @test tryparsenext_fixedtz("-99:59", 1, 6) == ("-99:59", 7)

        @test tryparsenext_fixedtz("+99", 1, 3) == ("+99", 4)
        @test tryparsenext_fixedtz("+9959", 1, 5) == ("+9959", 6)
        @test tryparsenext_fixedtz("+99:59", 1, 6) == ("+99:59", 7)

        @test tryparsenext_fixedtz("Z", 1, 1) == ("Z", 2)
    end

    # We should probably restrict minute to be between "00" and "59" but if we do these
    # should still parse to `UTC+99:00` (truncating minutes). As truncating could lead to
    # more confusion we'll allow "99:99" which translates to `UTC+100:39`.
    @testset "99 minutes" begin
        @test tryparsenext_fixedtz("9999", 1, 4) == ("9999", 5)
        @test tryparsenext_fixedtz("99:99", 1, 5) == ("99:99", 6)
        @test tryparsenext_fixedtz("-99:99", 1, 6) == ("-99:99", 7)
        @test tryparsenext_fixedtz("+99:99", 1, 6) == ("+99:99", 7)
    end

    @testset "automatic stop" begin
        @test tryparsenext_fixedtz("1230abc", 1, 7) == ("1230", 5)
        @test tryparsenext_fixedtz("12300", 1, 5) == ("1230", 5)
        @test tryparsenext_fixedtz("12:300", 1, 6) == ("12:30", 6)

        @test tryparsenext_fixedtz("-1230abc", 1, 7) == ("-1230", 6)
        @test tryparsenext_fixedtz("-12300", 1, 6) == ("-1230", 6)
        @test tryparsenext_fixedtz("-12:300", 1, 7) == ("-12:30", 7)
        @test tryparsenext_fixedtz("-123", 1, 4) == ("-12", 4)
        @test tryparsenext_fixedtz("-12:3", 1, 5) == ("-12", 4)

        @test tryparsenext_fixedtz("+1230abc", 1, 7) == ("+1230", 6)
        @test tryparsenext_fixedtz("+12300", 1, 6) == ("+1230", 6)
        @test tryparsenext_fixedtz("+12:300", 1, 7) == ("+12:30", 7)
        @test tryparsenext_fixedtz("+123", 1, 4) == ("+12", 4)
        @test tryparsenext_fixedtz("+12:3", 1, 5) == ("+12", 4)

        @test tryparsenext_fixedtz("Zabc", 1, 4) == ("Z", 2)
        @test tryparsenext_fixedtz("Z+12:30", 1, 7) == ("Z", 2)
    end

    @testset "min width" begin
        @test tryparsenext_fixedtz("1230", 1, 4, 5, 0) === nothing
        @test tryparsenext_fixedtz("+1230", 1, 5, 5, 0) == ("+1230", 6)
        @test tryparsenext_fixedtz("Z+12:30", 1, 7, 2, 0) === nothing
    end

    @testset "max width" begin
        @test tryparsenext_fixedtz("+12301999", 1, 9, 1, 5) == ("+1230", 6)
        @test tryparsenext_fixedtz("+12301999", 1, 9, 1, 3) == ("+12", 4)
        @test tryparsenext_fixedtz("Z+12:30", 1, 7, 1, 5) == ("Z", 2)
    end

    @testset "invalid" begin
        @test tryparsenext_fixedtz("1", 1, 1) === nothing
        @test tryparsenext_fixedtz("12", 1, 2) === nothing
        @test tryparsenext_fixedtz("123", 1, 3) === nothing
        @test tryparsenext_fixedtz("1:", 1, 2) === nothing
        @test tryparsenext_fixedtz("1:30", 1, 4) === nothing
        @test tryparsenext_fixedtz("12:", 1, 3) === nothing
        @test tryparsenext_fixedtz("12:3", 1, 4) === nothing
        @test tryparsenext_fixedtz("12::30", 1, 4) === nothing

        @test tryparsenext_fixedtz("-", 1, 1) === nothing
        @test tryparsenext_fixedtz("-1", 1, 2) === nothing
        @test tryparsenext_fixedtz("-1:", 1, 3) === nothing
        @test tryparsenext_fixedtz("-1:30", 1, 5) === nothing
        @test tryparsenext_fixedtz("--12", 1, 4) === nothing

        @test tryparsenext_fixedtz("+", 1, 1) === nothing
        @test tryparsenext_fixedtz("+1", 1, 2) === nothing
        @test tryparsenext_fixedtz("+1:", 1, 3) === nothing
        @test tryparsenext_fixedtz("+1:30", 1, 5) === nothing
        @test tryparsenext_fixedtz("++12", 1, 4) === nothing
    end
end

@testset "tryparsenext_tz" begin
    using TimeZones: tryparsenext_tz

    @testset "valid" begin
        @test tryparsenext_tz("Europe/Warsaw", 1, 13) == ("Europe/Warsaw", 14)
        @test tryparsenext_tz("America/New_York", 1, 16) == ("America/New_York", 17)
        @test tryparsenext_tz("America/Port-au-Prince", 1, 22) == ("America/Port-au-Prince", 23)
        @test tryparsenext_tz("America/Argentina/Buenos_Aires", 1, 30) == ("America/Argentina/Buenos_Aires", 31)
        @test tryparsenext_tz("Antarctica/McMurdo", 1, 18) == ("Antarctica/McMurdo", 19)
        @test tryparsenext_tz("Europe/Isle_of_Man", 1, 18) == ("Europe/Isle_of_Man", 19)
        @test tryparsenext_tz("Etc/GMT-14", 1, 10) == ("Etc/GMT-14", 11)
        @test tryparsenext_tz("Etc/GMT+9", 1, 9) == ("Etc/GMT+9", 10)
        @test tryparsenext_tz("UTC", 1, 3) == ("UTC", 4)
        @test tryparsenext_tz("GMT", 1, 3) == ("GMT", 4)

        # As these aren't ambiguous we can probably support these
        @test_broken tryparsenext_tz("GMT0", 1, 4) == ("GMT0", 5)
        @test_broken tryparsenext_tz("Etc/GMT0", 1, 8) == ("Etc/GMT0", 9)
    end

    @testset "automatic stop" begin
        @test tryparsenext_tz("Europe/Warsaw:Extra", 1, 19) == ("Europe/Warsaw", 14)
        @test tryparsenext_tz("Europe/Warsaw//Extra", 1, 20) == ("Europe/Warsaw", 14)

        # Maximum of two sequential digits
        @test tryparsenext_tz("Etc/GMT-100", 1, 11) == ("Etc/GMT-10", 11)
    end

    @testset "min width" begin
        @test tryparsenext_tz("UTC", 1, 3, 6, 0) === nothing
        @test tryparsenext_tz("Europe/Warsaw", 1, 13, 6, 0) == ("Europe/Warsaw", 14)
    end

    @testset "max width" begin
        @test tryparsenext_tz("Europe/Warsaw/Extra", 1, 19, 1, 13) == ("Europe/Warsaw", 14)
    end

    @testset "invalid" begin
        @test tryparsenext_tz("//", 1, 2) === nothing
        @test tryparsenext_tz("__", 1, 2) === nothing
        @test tryparsenext_tz("--", 1, 2) === nothing
        @test tryparsenext_tz("123", 1, 2) === nothing  # Cannot contain only numbers

        # Treat most abbreviations as invalid since they are often ambiguous
        @test tryparsenext_tz("MST", 1, 3) === nothing
    end

    # Validate we can parse all of the supported time zone names.
    @testset "all time zone names" begin
        function test_tryparsenext_tz(tz_name)
            expected = if tz_name == "Etc/GMT0"
                ("Etc/GMT", 8)
            elseif tz_name == "GMT" || tz_name == "GMT0"
                ("GMT", 4)
            elseif tz_name == "UTC"
                ("UTC", 4)
            elseif contains(tz_name, '/')
                (tz_name, length(tz_name) + 1)
            else
                nothing
            end

            @test tryparsenext_tz(tz_name, 1, length(tz_name)) == expected
        end

        for tz_name in timezone_names()
            @static if VERSION >= v"1.9"
                @testset let tz_name = tz_name
                    test_tryparsenext_tz(tz_name)
                end
            else
                @testset "$tz_name" begin
                    test_tryparsenext_tz(tz_name)
                end
            end
        end
    end
end

@testset "_parsesub_tzabbr" begin
    empty_msg = "Time zone abbreviation must start with a letter or the less-than (<) character"
    not_closed_msg = "Expected expanded time zone abbreviation end with the greater-than sign (>)"
    three_char_sim_msg = "Time zone abbreviation must be at least three alphabetic characters"
    three_char_exp_msg = "Time zone abbreviation must be at least three characters which are either alphanumeric, the plus sign (+), or the minus sign (-)"

    @test _parsesub_tzabbr("") == ParseNextError(empty_msg, "", 1, 0)
    @test _parsesub_tzabbr("&") == ParseNextError(empty_msg, "&", 1, 1)
    @test _parsesub_tzabbr("FOO") == ("FOO", 4)
    @test _parsesub_tzabbr("FOO&") == ("FOO", 4)
    @test _parsesub_tzabbr("FOO+1") == ("FOO", 4)
    @test _parsesub_tzabbr("<FOO+1>") == ("FOO+1", 8)
    @test _parsesub_tzabbr("<FOO+1") == ParseNextError(not_closed_msg, "<FOO+1", 1, 7)
    @test _parsesub_tzabbr("<") == ParseNextError(not_closed_msg, "<", 1, 2)
    @test _parsesub_tzabbr(">") == ParseNextError(empty_msg, ">", 1, 1)
    @test _parsesub_tzabbr("AB") == ParseNextError(three_char_sim_msg, "AB", 1, 2)
    @test _parsesub_tzabbr("<>") == ParseNextError(three_char_exp_msg, "<>", 2, 1)
    @test _parsesub_tzabbr("αβc") == ParseNextError(empty_msg, "αβc", 1, 1)
end

@testset "_parsesub_offset" begin
    end_of_string_msg = "Expected offset and instead found end of string"
    missing_hours_msg = "Expected offset hour digits"
    hours_range_msg = "Hours outside of expected range [0, 24]"
    minutes_range_msg = "Minutes outside of expected range [0, 59]"
    minutes_digits_msg = "Expected offset minute digits after colon delimiter"
    seconds_range_msg = "Seconds outside of expected range [0, 59]"
    seconds_digits_msg = "Expected offset second digits after colon delimiter"

    @testset "sign" begin
        @test _parsesub_offset("") == ParseNextError(end_of_string_msg, "", 1, 0)
        @test _parsesub_offset("&") == ParseNextError(missing_hours_msg, "&", 1, 1)
        @test _parsesub_offset("-") == ParseNextError("Offset sign (-) is not followed by a value", "-", 1, 1)
        @test _parsesub_offset("+") == ParseNextError("Offset sign (+) is not followed by a value", "+", 1, 1)
    end

    @testset "hours" begin
        @test _parsesub_offset("0") == (0, 2)
        @test _parsesub_offset("0&") == (0, 2)

        @test _parsesub_offset("1")   == ( 1 * 3600, 2)
        @test _parsesub_offset("-1")  == (-1 * 3600, 3)
        @test _parsesub_offset("+1")  == (+1 * 3600, 3)
        @test _parsesub_offset("-24") == (-24 * 3600, 4)
        @test _parsesub_offset("+24") == (+24 * 3600, 4)

        @test _parsesub_offset("-25") == ParseNextError(hours_range_msg, "-25", 2, 3)
        @test _parsesub_offset("+25") == ParseNextError(hours_range_msg, "+25", 2, 3)
    end

    @testset "minutes" begin
        @test _parsesub_offset("0:59")  == ( 59 * 60, 5)
        @test _parsesub_offset("-0:59") == (-59 * 60, 6)
        @test _parsesub_offset("+0:59") == (+59 * 60, 6)

        @test _parsesub_offset("-0:60") == ParseNextError(minutes_range_msg, "-0:60", 4, 5)
        @test _parsesub_offset("+0:60") == ParseNextError(minutes_range_msg, "+0:60", 4, 5)
        @test _parsesub_offset("0:") == ParseNextError(minutes_digits_msg, "0:", 3, 2)
        @test _parsesub_offset("0:-1") == ParseNextError(minutes_digits_msg, "0:-1", 3, 3)
    end

    @testset "seconds" begin
        @test _parsesub_offset("0:0:59")  == ( 59, 7)
        @test _parsesub_offset("-0:0:59") == (-59, 8)
        @test _parsesub_offset("+0:0:59") == (+59, 8)
        @test _parsesub_offset("0:0:59:") == ( 59, 7)

        @test _parsesub_offset("-0:0:60") == ParseNextError(seconds_range_msg, "-0:0:60", 6, 7)
        @test _parsesub_offset("+0:0:60") == ParseNextError(seconds_range_msg, "+0:0:60", 6, 7)
        @test _parsesub_offset("0:0:") == ParseNextError(seconds_digits_msg, "0:0:", 5, 4)
        @test _parsesub_offset("0:0:-1") == ParseNextError(seconds_digits_msg, "0:0:-1", 5, 5)
    end
end

@testset "_parsesub_time" begin
    # Note: `_parsesub_time` primarily makes use of `_parsesub_offset`. Additional tests
    # should be added here if that is no longer the case.
    @test _parsesub_time("1") == (3600, 2)
    @test _parsesub_time("-1") == ParseNextError("Time should not have a sign", "-1", 1, 1)
    @test _parsesub_time("+1") == ParseNextError("Time should not have a sign", "+1", 1, 1)
end

@testset "_parsesub_tzdate" begin
    @testset "Julian day" begin
        # Note: Hard-coding years in tests below make failed testsets easier to read

        # Non-leap year
        for d in [1; 59:61; 365]
            f, i = TimeZones._parsesub_tzdate("J$d")
            @test f(2019) == Date(2019) + Day(d - 1)
            @test dayofyear(f(2019)) == d
        end

        # Leap year
        for (j, d) in zip([1; 59:61; 365], [1; 59; 61:62; 366])
            f, i = TimeZones._parsesub_tzdate("J$j")
            @test f(2020) == Date(2020) + Day(d - 1)
            @test dayofyear(f(2020)) == d
        end
    end

    @testset "zero-based Julian day" begin
        # Note: Hard-coding years in tests below make failed testsets easier to read

        # Non-leap year
        # Note: For non-leap years day 365 is actually the first day of the next year which
        # is why the test for `dayofyear` requires mod 365.
        for d in [0; 58:60; 365]
            f, i = _parsesub_tzdate("$d")
            @test f(2019) == Date(2019) + Day(d)
            @test dayofyear(f(2019)) == (d % 365) + 1
        end

        # Leap year
        for d in [0; 58:60; 365]
            f, i = _parsesub_tzdate("$d")
            @test f(2020) == Date(2020) + Day(d)
            @test dayofyear(f(2020)) == d + 1
        end
    end

    @testset "month, week-of-month, day-of-week" begin
        @testset "First Sunday in October" begin
            f, i = _parsesub_tzdate("M10.1.0")
            @test f(2020) == Date(2020, 10, 4)
            @test f(2019) == Date(2019, 10, 6)
            @test f(2018) == Date(2018, 10, 7)
            @test f(2017) == Date(2017, 10, 1)
            @test i == 8
        end

        @testset "Third Sunday in March" begin
            f, i = _parsesub_tzdate("M3.3.0")
            @test f(2020) == Date(2020, 3, 15)
            @test f(2019) == Date(2019, 3, 17)
            @test f(2018) == Date(2018, 3, 18)
            @test f(2017) == Date(2017, 3, 19)
            @test i == 7
        end

        @testset "Last Saturday in January" begin
            # Note: 2017 - 2020 only have 4 Saturdays in January
            f1, i = _parsesub_tzdate("M1.5.6")
            @test i == 7

            f2, i = _parsesub_tzdate("M1.4.6")
            @test i == 7

            @test f1(2020) == f1(2020) == Date(2020, 1, 25)
            @test f1(2019) == f2(2019) == Date(2019, 1, 26)
            @test f1(2018) == f2(2018) == Date(2018, 1, 27)
            @test f1(2017) == f2(2017) == Date(2017, 1, 28)
        end
    end
end

@testset "_parsesub_tz" begin
    dst_start_date_msg = "Unable to parse daylight saving start date. Expected date and instead found end of string"
    dst_start_time_msg = "Expected daylight saving start time and instead found end of string"
    dst_end_missing_msg = "Expected to find daylight saving end and instead found end of string"
    dst_end_date_msg = "Unable to parse daylight saving end date. Expected date and instead found end of string"

    @testset "empty" begin
        @test _parsesub_tz("") == (FixedTimeZone("UTC"), 1)
    end

    @testset "standard time only" begin
        @test _parsesub_tz("FOO") == ParseNextError("Expected standard offset and instead found end of string", "FOO", 4, 3)
        @test _parsesub_tz("FOO+1") == (FixedTimeZone("FOO", -3600), 6)
        @test _parsesub_tz("<FOO+1>-1") == (FixedTimeZone("FOO+1", 3600), 10)
    end

    @testset "standard/daylight saving time" begin
        tz, i = _parsesub_tz("FOO+0BAR")
        bar, foo = filter(t -> year(t.utc_datetime) == 2020, tz.transitions)
        @test foo == Transition(DateTime(2020, 11, 1, 1), FixedTimeZone("FOO", 0))
        @test bar == Transition(DateTime(2020, 3, 8, 2), FixedTimeZone("BAR", 0, 3600))
        @test i == 9

        tz, i = _parsesub_tz("FOO+0BAR+1")
        bar, foo = filter(t -> year(t.utc_datetime) == 2020, tz.transitions)
        @test foo == Transition(DateTime(2020, 11, 1, 3), FixedTimeZone("FOO", 0))
        @test bar == Transition(DateTime(2020, 3, 8, 2), FixedTimeZone("BAR", 0, -3600))
        @test i == 11
    end

    @testset "transition dates" begin
        @test _parsesub_tz("FOO+0BAR+0,") == ParseNextError(dst_start_date_msg, "FOO+0BAR+0,", 12, 11)
        @test _parsesub_tz("FOO+0BAR+0,0") == ParseNextError(dst_end_missing_msg, "FOO+0BAR+0,0", 13, 12)
        @test _parsesub_tz("FOO+0BAR+0,0,") == ParseNextError(dst_end_date_msg, "FOO+0BAR+0,0,", 14, 13)

        tz, i = _parsesub_tz("FOO+0BAR+0,0,1")
        bar, foo = filter(t -> year(t.utc_datetime) == 2020, tz.transitions)
        @test foo == Transition(DateTime(2020, 1, 2, 2), FixedTimeZone("FOO", 0))
        @test bar == Transition(DateTime(2020, 1, 1, 2), FixedTimeZone("BAR", 0))
        @test i == 15
    end

    @testset "transition times" begin
        @test _parsesub_tz("FOO+0BAR+0,0/") == ParseNextError(dst_start_time_msg, "FOO+0BAR+0,0/", 14, 13)
        @test _parsesub_tz("FOO+0BAR+0,0/0") == ParseNextError(dst_end_missing_msg, "FOO+0BAR+0,0/0", 15, 14)
        @test _parsesub_tz("FOO+0BAR+0,0/0,") == ParseNextError(dst_end_date_msg, "FOO+0BAR+0,0/0,", 16, 15)

        tz, i = _parsesub_tz("FOO+0BAR+0,0/3,1/4")
        bar, foo = filter(t -> year(t.utc_datetime) == 2020, tz.transitions)
        @test foo == Transition(DateTime(2020, 1, 2, 4), FixedTimeZone("FOO", 0))
        @test bar == Transition(DateTime(2020, 1, 1, 3), FixedTimeZone("BAR", 0))
        @test i == 19

        # Times beyond 24-hours
        # - Linux clamps hours when beyond 24.
        # - macOS falls back to UTC hours beyond 167.
        @test _parsesub_tz("FOO+0BAR+0,0/25,1/720") == ParseNextError("Hours outside of expected range [0, 24]", "FOO+0BAR+0,0/25,1/720", 14, 15)

        # - Linux parses +/- times succesfully but clamps negative times to zero.
        # - macOS fails to parse +/- times.
        @test _parsesub_tz("FOO+0BAR+0,0/+1,1/1") == ParseNextError("Daylight saving start time should not have a sign", "FOO+0BAR+0,0/+1,1/1", 14)
        @test _parsesub_tz("FOO+0BAR+0,0/1,1/+1") == ParseNextError("Daylight saving end time should not have a sign", "FOO+0BAR+0,0/1,1/+1", 18)

        @test _parsesub_tz("FOO+0BAR+0,0/-1,1/1") == ParseNextError("Daylight saving start time should not have a sign", "FOO+0BAR+0,0/-1,1/1", 14)
        @test _parsesub_tz("FOO+0BAR+0,0/1,1/-1") == ParseNextError("Daylight saving end time should not have a sign", "FOO+0BAR+0,0/1,1/-1", 18)
    end

    # Example found in the `tzset 3` man page
    @testset "New Zealand example" begin
        tz, i = _parsesub_tz("NZST-12:00:00NZDT-13:00:00,M10.1.0,M3.3.0")
        nzst, nzdt = filter(t -> year(t.utc_datetime) == 2020, tz.transitions)
        @test nzst == Transition(DateTime(2020, 3, 14, 13), FixedTimeZone("NZST", 43200))
        @test nzdt == Transition(DateTime(2020, 10, 3, 14), FixedTimeZone("NZDT", 43200, 3600))
        @test i == 42
    end

    # Daylight saving offset is optional
    @testset "EST/EDT" begin
        tz, i = _parsesub_tz("EST5EDT,M3.2.0,M11.1.0")
        edt, est = filter(t -> year(t.utc_datetime) == 2020, tz.transitions)
        @test est == Transition(DateTime(2020, 11, 1, 6), FixedTimeZone("EST", -18000))
        @test edt == Transition(DateTime(2020, 3, 8, 7), FixedTimeZone("EDT", -18000, 3600))
        @test i == 23
    end

    # Validate the direct specification by comparing the result with a time zone computed
    # from tzdata.
    @testset "equivalent" begin
        # The tzdata time zone only uses consistent rules on/after 2007
        wpg = first(compile("America/Winnipeg", tzdata["northamerica"]))
        consistent_years = t -> year(t.utc_datetime) >= 2007

        tz, i = _parsesub_tz("CST+6CDT+5,M3.2.0/2,M11.1.0/2")
        @test tz.name == "CST/CDT"
        @test tz.name != wpg.name
        @test filter(consistent_years, tz.transitions) == filter(consistent_years, wpg.transitions)
        @test tz.cutoff == wpg.cutoff
        @test i == 30

        # Shorthand versions of the direct time zone specification we created
        expected = tz
        @test first(_parsesub_tz("CST+6CDT+5,M3.2.0,M11.1.0")) == expected
        @test first(_parsesub_tz("CST+6CDT+5")) == expected
    end
end
