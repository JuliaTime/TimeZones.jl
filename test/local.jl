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


@testset "localzone" begin

    # Ensure that the current system's local time zone is supported. If this test fails make
    # sure to report it as an issue.
    @testset "system time zone supported" begin
        @test isa(localzone(), TimeZone)
    end

    # Note: Be careful not to have the tests rely on time zone information being
    # pre-installed on the system. Some minimal systems, such as Docker containers, will not
    # have any system time zone information.
    Sys.islinux() && @testset "TZ environmental variable" begin
        @testset "invalid" begin
            # Bad TZ environment variable formats
            withenv("TZ" => "+12:00") do
                @test_throws ErrorException localzone()
            end

            # Unable to locate time zone on system
            withenv("TZ" => ":") do
                @test_throws ErrorException localzone()
            end
            withenv("TZ" => ":Etc/Foo") do
                @test_throws ErrorException localzone()
            end
        end

        @testset "direct specification" begin
            # Currently unsupported TZ environment variable formats
            withenv("TZ" => "NZST-12:00:00NZDT-13:00:00,M10.1.0,M3.3.0") do
                @test_throws ErrorException localzone()
            end
        end

        @testset "utc" begin
            withenv("TZ" => "") do
                @test localzone() == utc
            end
            withenv("TZ" => "UTC") do
                @test localzone() == utc
            end
        end

        # When TZ starts with a `:` then the remainder of the string should be treated as a
        # path. For TimeZones.jl we will only load tzfiles when this is specified.
        @testset "force file use" begin
            utc = TimeZone("UTC+0")

            withenv("TZ" => ":UTC+0") do
                @test_throws ErrorException localzone()
            end
            withenv("TZ" => "UTC+0") do
                @test localzone() == utc
            end
        end

        # Use a time zone unrecognized by IANA or TimeZones.jl to verify that the TZDIR
        # environmental variable is being respected.
        @testset "TZDIR environmental variable" begin
            mkdir(joinpath(TZFILE_DIR, "Test"))
            cp(joinpath(TZFILE_DIR, "Etc", "UTC"), joinpath(TZFILE_DIR, "Test", "UTC"))

            try
                @test_throws ArgumentError TimeZone("Test/UTC")
                test_utc = open(joinpath(TZFILE_DIR, "Test", "UTC")) do f
                    TimeZones.read_tzfile(f, "Test/UTC")
                end
                withenv("TZ" => ":Test/UTC", "TZDIR" => TZFILE_DIR) do
                    @test localzone() == test_utc
                end
                withenv("TZ" => "Test/UTC", "TZDIR" => TZFILE_DIR) do
                    @test localzone() == test_utc
                end
            finally
                rm(joinpath(TZFILE_DIR, "Test"), recursive=true, force=true)
            end
        end

        @testset "absolute path" begin
            warsaw_path = joinpath(TZFILE_DIR, "Europe", "Warsaw")
            warsaw_from_file = open(warsaw_path) do f
                TimeZones.read_tzfile(f, "local")
            end

            withenv("TZ" => ":" * abspath(warsaw_path)) do
                @test localzone() == warsaw_from_file
            end
            withenv("TZ" => abspath(warsaw_path)) do
                @test localzone() == warsaw_from_file
            end
        end

        @testset "relative path" begin
            warsaw_path = joinpath(TZFILE_DIR, "Europe", "Warsaw")
            warsaw_from_file = open(warsaw_path) do f
                TimeZones.read_tzfile(f, "Europe/Warsaw")
            end
            warsaw = TimeZone("Europe/Warsaw")

            withenv("TZ" => ":Europe/Warsaw", "TZDIR" => TZFILE_DIR) do
                @test localzone() == warsaw_from_file
            end
            withenv("TZ" => "Europe/Warsaw") do
                @test localzone() == warsaw
            end
        end
    end
end
