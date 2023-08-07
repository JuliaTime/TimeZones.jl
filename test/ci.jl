using TimeZones: TZData

# Note: These tests are only meant to be run in a CI environment as they will modify the
# built time zones in the `compiled_dir()`. This could interfere with concurrently running
# Julia sessions or just leave the end-users system in a inconsistent state.

@testset "build process" begin
    working_dir = _scratch_dir()

    # Clean out deps directories for a clean re-build
    TZData.cleanup(TZDATA_VERSION, working_dir)

    tz_source_dir = joinpath(working_dir, _tz_source_relative_dir(TZDATA_VERSION))
    compiled_dir = joinpath(working_dir, _compiled_relative_dir(TZDATA_VERSION))

    @test !isdir(compiled_dir)
    @test !isdir(tz_source_dir)

    # TODO: Comment incorrect
    # Using a version we already have avoids triggering a download
    TZData.build(TZDATA_VERSION, working_dir)

    @test isdir(compiled_dir)
    @test length(readdir(compiled_dir)) > 0
    @test readdir(tz_source_dir) == sort(TZData.REGIONS)

    # Compile tz source files with an extended max_year. An example from the FAQ.
    warsaw = TimeZone("Europe/Warsaw")

    @test last(warsaw.transitions).utc_datetime == DateTime(2037, 10, 25, 1)
    @test warsaw.cutoff == DateTime(2038, 3, 28, 1)
    @test_throws TimeZones.UnhandledTimeError ZonedDateTime(DateTime(2039), warsaw)

    # Note: Using `TZData.compile(max_year=2200)` will end up updating the compiled data for
    # `tzdata_version()` instead of what we last built using `TZDATA_VERSION`.
    TZData.compile(tz_source_dir, compiled_dir, max_year=2200)

    # TODO: In the future the `TZData.compile` function won't reload the cache. We'll need
    # revise the above line to be something like:
    # tz_source = TZData.TZSource(joinpath.(tz_source_dir, ["europe", "africa"]))
    # TZData.compile(tz_source, compiled_dir, max_year=2200)
    # TimeZones._reload_cache(compiled_dir)

    new_warsaw = TimeZone("Europe/Warsaw")

    @test warsaw !== new_warsaw
    @test last(new_warsaw.transitions).utc_datetime == DateTime(2200, 10, 26, 1)
    @test new_warsaw.cutoff == DateTime(2201, 3, 29, 1)
    @test year(ZonedDateTime(2100, new_warsaw)) == 2100  # Test this doesn't throw an exception

    @test_throws TimeZones.UnhandledTimeError ZonedDateTime(2100, warsaw)

    # Using the tz string macro which runs at parse time means that the resulting TimeZone
    # will not reflect changes made from compile or new builds during runtime.
    @test tz"Africa/Windhoek" != TimeZone("Africa/Windhoek")
    @test tz"Africa/Windhoek".cutoff != DateTime(2201, 4, 5)
    @test TimeZone("Africa/Windhoek").cutoff == DateTime(2201, 4, 5)
end
