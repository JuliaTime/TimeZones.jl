using TimeZones: TZData

# Note: These tests are only meant to be run in a CI environment as they will modify the
# built time zones in the `compiled_dir()`. This could interfere with concurrently running
# Julia sessions or just leave the end-users system in a inconsistent state.

@testset "build process" begin
    # Clean out deps directories for a clean re-build
    compiled_dir = TZData._compiled_dir(TZDATA_VERSION)
    tz_source_dir = TZData._tz_source_dir(TZDATA_VERSION)

    rm(compiled_dir, recursive=true)
    rm(tz_source_dir, recursive=true)

    @test !isdir(compiled_dir)
    @test !isdir(tz_source_dir)

    # Using a version we already have avoids triggering a download
    TimeZones.build(TZDATA_VERSION)

    @test isdir(compiled_dir)
    @test length(readdir(compiled_dir)) > 0
    @test readdir(tz_source_dir) == sort(TZData.REGIONS)

    # Compile tz source files with an extended max_year. An example from the FAQ.
    warsaw = TimeZone("Europe/Warsaw")

    @test last(warsaw.transitions).utc_datetime == DateTime(2037, 10, 25, 1)
    @test warsaw.cutoff == DateTime(2038, 3, 28, 1)
    @test_throws TimeZones.UnhandledTimeError ZonedDateTime(DateTime(2039), warsaw)

    TZData.compile(max_year=2200)
    new_warsaw = TimeZone("Europe/Warsaw")

    @test warsaw !== new_warsaw
    @test last(new_warsaw.transitions).utc_datetime == DateTime(2200, 10, 26, 1)
    @test new_warsaw.cutoff == DateTime(2201, 3, 29, 1)
    ZonedDateTime(2100, new_warsaw)  # Test this doesn't throw an exception

    @test_throws TimeZones.UnhandledTimeError ZonedDateTime(2100, warsaw)

    # Using the tz string macro which runs at parse time means that the resulting TimeZone
    # will not reflect changes made from compile or new builds during runtime.
    @test tz"Africa/Windhoek" != TimeZone("Africa/Windhoek")
    @test tz"Africa/Windhoek".cutoff != DateTime(2201, 4, 5)
    @test TimeZone("Africa/Windhoek").cutoff == DateTime(2201, 4, 5)
end
