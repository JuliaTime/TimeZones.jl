import TimeZones: TimeZone, localzone

# Ensure that the current system's local time zone is supported. If this test fails make
# sure to report it as an issue.
@test isa(localzone(), TimeZone)


@linux_only begin
    # Bad TZ environmental variables
    withenv("TZ" => "") do
        @test_throws ErrorException localzone()
    end
    withenv("TZ" => "Europe/Warsaw") do
        @test_throws ErrorException localzone()
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
    @test_throws ErrorException TimeZone("Etc/UTC")
    utc = open(joinpath(TZFILE_DIR, "Etc", "UTC")) do f
        TimeZones.read_tzfile(f, "Etc/UTC")
    end
    withenv("TZ" => ":Etc/UTC", "TZDIR" => TZFILE_DIR) do
        @test localzone() == utc
    end

    # Use system installed files
    @test_throws ErrorException TimeZone("Etc/GMT-9")
    gmt_minus_9 = FixedTimeZone("Etc/GMT-9", 9 * 3600)
    withenv("TZ" => ":Etc/GMT-9") do
        @test localzone() == gmt_minus_9
    end

    # Unable to locate time zone on system
    withenv("TZ" => ":") do
        @test_throws SystemError localzone()
    end
    withenv("TZ" => ":Etc/Foo") do
        @test_throws SystemError localzone()
    end
end
