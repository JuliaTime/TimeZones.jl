using TimeZones: TimeZone, localzone, parse_tz_format

# Parse the TZ environment variable format
# Should mirror the behaviour of running:
# `date -u; env TZ="..." date`

@test_throws ArgumentError parse_tz_format("AB")
@test_throws ArgumentError parse_tz_format("+")
@test_throws ArgumentError parse_tz_format("12")

@test parse_tz_format("") == FixedTimeZone("UTC", 0, 0)
@test parse_tz_format("ABC") == FixedTimeZone("ABC", 0, 0)
@test parse_tz_format("ABC+") == FixedTimeZone("ABC", 0, 0)
@test parse_tz_format("ABC-") == FixedTimeZone("ABC", 0, 0)

@test parse_tz_format("ABC1") == FixedTimeZone("ABC", -1 * 3600, 0)
@test parse_tz_format("ABC+1") == FixedTimeZone("ABC", -1 * 3600, 0)
@test parse_tz_format("ABC-1") == FixedTimeZone("ABC", 1 * 3600, 0)

@test parse_tz_format("ABC-24")  == FixedTimeZone("ABC", 24 * 3600, 0)
@test parse_tz_format("ABC-25")  == FixedTimeZone("ABC", 24 * 3600, 0)
@test parse_tz_format("ABC-100") == FixedTimeZone("ABC", 24 * 3600, 0)

@test parse_tz_format("ABC-00:59")  == FixedTimeZone("ABC", 59 * 60, 0)
@test parse_tz_format("ABC-00:99")  == FixedTimeZone("ABC", 59 * 60, 0)
@test parse_tz_format("ABC-00:100") == FixedTimeZone("ABC", 59 * 60, 0)

@test parse_tz_format("ABC-00:00:59")  == FixedTimeZone("ABC", 59, 0)
@test parse_tz_format("ABC-00:00:99")  == FixedTimeZone("ABC", 59, 0)
@test parse_tz_format("ABC-00:00:100") == FixedTimeZone("ABC", 59, 0)

@test_throws ArgumentError parse_tz_format("ABC+00:")  # Terminal test is valid and equal to "ABC"
@test_throws ArgumentError parse_tz_format("ABC+12:")


# Ensure that the current system's local time zone is supported. If this test fails make
# sure to report it as an issue.
@test isa(localzone(), TimeZone)


if Sys.islinux()
    # Bad TZ environment variable formats
    withenv("TZ" => "+12:00") do
        @test_throws ArgumentError localzone()
    end
    withenv("TZ" => "Europe/Warsaw") do
        @test_throws ArgumentError localzone()
    end

    # Currently unsupported TZ environment variable formats
    withenv("TZ" => "NZST-12:00:00NZDT-13:00:00,M10.1.0,M3.3.0") do
        @test_throws ArgumentError localzone()
    end

    # Valid TZ formats
    withenv("TZ" => "") do
        @test localzone() == utc
    end
    withenv("TZ" => "UTC") do
        @test localzone() == utc
    end

    # Absolute filespec
    warsaw_path = joinpath(TZFILE_DIR, "Europe", "Warsaw")
    warsaw_from_file = open(warsaw_path) do f
        TimeZones.read_tzfile(f, "local")
    end
    withenv("TZ" => ":" * abspath(warsaw_path)) do
        @test localzone() == warsaw_from_file
    end

    # Relative filespec
    warsaw = TimeZone("Europe/Warsaw")
    withenv("TZ" => ":Europe/Warsaw") do
        @test localzone() == warsaw
    end

    # Set TZDIR and use time zone unrecognized by TimeZone
    @test_throws ArgumentError TimeZone("Etc/UTC")
    utc = open(joinpath(TZFILE_DIR, "Etc", "UTC")) do f
        TimeZones.read_tzfile(f, "Etc/UTC")
    end
    withenv("TZ" => ":Etc/UTC", "TZDIR" => TZFILE_DIR) do
        @test localzone() == utc
    end

    # Attempt to use system installed time zone files. On some minimal systems no time zone
    # information will be available.
    @test_throws ArgumentError TimeZone("Etc/GMT-9")
    gmt_minus_9 = FixedTimeZone("Etc/GMT-9", 9 * 3600)
    withenv("TZ" => ":Etc/GMT-9") do
        try
            tz = localzone()
            @test tz == gmt_minus_9
        catch err
            msg = sprint(showerror, err)
            if isa(err, ErrorException) && msg == "unable to locate tzfile: Etc/GMT-9"
                warn("Skipping test: missing system time zone information")
            else
                rethrow()
            end
        end
    end

    # Unable to locate time zone on system
    withenv("TZ" => ":") do
        @test_throws ErrorException localzone()
    end
    withenv("TZ" => ":Etc/Foo") do
        @test_throws ErrorException localzone()
    end
end
