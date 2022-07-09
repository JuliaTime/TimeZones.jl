using TimeZones: TZData

# Note: These tests are only meant to be run in a CI environment as they will modify the
# build time zones in the `compiled_dir()`.

@testset "build process" begin
    # Clean out deps directories for a clean re-build
    compiled_dir = TZData.compiled_dir()
    tz_source_dir = TZData.tz_source_dir()

    rm(compiled_dir, recursive=true)
    for file in readdir(tz_source_dir)
        file == "utc" && continue
        rm(joinpath(tz_source_dir, file))
    end

    @test !isdir(compiled_dir)
    @test length(readdir(tz_source_dir)) == 1

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
