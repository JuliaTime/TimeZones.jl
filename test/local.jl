using TimeZones: ParseNextError, TimeZone, localzone, parse_tz_format
using TimeZones: _path_tz_name

# Parse the TZ environment variable format
# Should mirror the behaviour of running:
# `date -u; env TZ="..." date`

@test_throws ParseNextError parse_tz_format("AB")
@test_throws ParseNextError parse_tz_format("+")
@test_throws ParseNextError parse_tz_format("12")

@test parse_tz_format("") == FixedTimeZone("UTC", 0, 0)
@test_throws ParseNextError parse_tz_format("ABC")
@test_throws ParseNextError parse_tz_format("ABC+")
@test_throws ParseNextError parse_tz_format("ABC-")

@test parse_tz_format("ABC1") == FixedTimeZone("ABC", -1 * 3600, 0)
@test parse_tz_format("ABC+1") == FixedTimeZone("ABC", -1 * 3600, 0)
@test parse_tz_format("ABC-1") == FixedTimeZone("ABC", 1 * 3600, 0)

@test parse_tz_format("ABC-24")  == FixedTimeZone("ABC", 24 * 3600, 0)
@test_throws ParseNextError parse_tz_format("ABC-25")
@test_throws ParseNextError parse_tz_format("ABC-100")

@test parse_tz_format("ABC-00:59")  == FixedTimeZone("ABC", 59 * 60, 0)
@test_throws ParseNextError parse_tz_format("ABC-00:99")
@test_throws ParseNextError parse_tz_format("ABC-00:100")

@test parse_tz_format("ABC-00:00:59")  == FixedTimeZone("ABC", 59, 0)
@test_throws ParseNextError parse_tz_format("ABC-00:00:99")
@test_throws ParseNextError parse_tz_format("ABC-00:00:100")

@test_throws ParseNextError parse_tz_format("ABC+00:")
@test_throws ParseNextError parse_tz_format("ABC+12:")


@testset "localzone" begin
    @testset "_path_tz_name" begin
        @test _path_tz_name("") === nothing
        @test _path_tz_name("/tmp/UTC/file") === nothing

        for name in ("UTC", "Europe/Warsaw", "America/Indiana/Indianapolis")
            # Use eval to improve readability of tests when failures occur
            @eval begin
                @test _path_tz_name($name) == $name
                @test _path_tz_name("/usr/share/zoneinfo/$($name)") == $name
                @test _path_tz_name("/var/db/timezone/zoneinfo/$($name)") == $name
            end
        end

        # Verify that the algorithm employed extracts the full time zone name.
        # e.g. Passing in "/usr/share/zoneinfo/Etc/GMT0" may return "GMT0" instead of
        # "Etc/GMT0" if we process from right-to-left.
        @testset "alternative match" begin
            @test _path_tz_name("GMT0") == "GMT0"  # A valid time zone name
            @test _path_tz_name("Etc/GMT0") == "Etc/GMT0"
        end
    end

    # Ensure that the current system's local time zone is supported. If this test fails make
    # sure to report it as an issue.
    @testset "system time zone supported" begin
        @test isa(localzone(), TimeZone)
    end

    # Note: Be careful not to have the tests rely on time zone information being
    # pre-installed on the system. Some minimal systems, such as Docker containers, will not
    # have any system time zone information.
    Sys.isunix() && @testset "TZ environmental variable" begin
        @testset "invalid" begin
            # Bad TZ environment variable formats
            withenv("TZ" => "+12:00") do
                @test_throws ParseNextError localzone()
            end

            # Unable to locate time zone on system
            withenv("TZ" => ":") do
                @test_throws ErrorException localzone()
            end
            withenv("TZ" => ":Etc/Foo") do
                @test_throws ErrorException localzone()
            end

            # Bad TZ which is not a file and not a direct representation. Under these
            # conditions we should throw a error message from parsing the direct
            # representation.
            withenv("TZ" => "A") do
                try
                    localzone()
                catch e
                    @test e isa ParseNextError
                    @test occursin("Unhandled TZ environment variable", e.msg)
                end
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
            try
                mkdir(joinpath(TZFILE_DIR, "Test"))
                cp(joinpath(TZFILE_DIR, "Etc", "UTC"), joinpath(TZFILE_DIR, "Test", "UTC"))

                @test_throws ArgumentError TimeZone("Test/UTC")
                test_utc = open(joinpath(TZFILE_DIR, "Test", "UTC")) do f
                    TZFile.read(f)("Test/UTC")
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
                TZFile.read(f)("Europe/Warsaw")
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
                TZFile.read(f)("Europe/Warsaw")
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
