@test istimezone("Europe/Warsaw")
@test istimezone("UTC+02")
@test !istimezone("Europe/Camelot")

# Deserialization can cause us to have two immutables that are not using the same memory
@test TimeZone("Europe/Warsaw") === TimeZone("Europe/Warsaw")
@test tz"Africa/Nairobi" === TimeZone("Africa/Nairobi")

if lowercase(get(ENV, "CI", "false")) == "true"
    @info "Testing build process"

    # Clean out deps directories for a clean re-build
    rm(TimeZones.COMPILED_DIR, recursive=true)
    for file in readdir(TimeZones.TZ_SOURCE_DIR)
        file == "utc" && continue
        rm(joinpath(TimeZones.TZ_SOURCE_DIR, file))
    end

    @test !isdir(TimeZones.COMPILED_DIR)
    @test length(readdir(TimeZones.TZ_SOURCE_DIR)) == 1

    # Using a version we already have avoids triggering a download
    TimeZones.build(TZDATA_VERSION, TimeZones.REGIONS)

    @test isdir(TimeZones.COMPILED_DIR)
    @test length(readdir(TimeZones.COMPILED_DIR)) > 0
    @test readdir(TimeZones.TZ_SOURCE_DIR) == sort!([TimeZones.REGIONS; "utc"])


    # Compile the "etcetera" tz source file. An example from the FAQ.
    @test !isfile(joinpath(TimeZones.TZ_SOURCE_DIR, "etcetera"))

    archive = TimeZones.TZData.active_archive()
    TimeZones.TZData.extract(archive, TimeZones.TZ_SOURCE_DIR, "etcetera")

    @test isfile(joinpath(TimeZones.TZ_SOURCE_DIR, "etcetera"))
    TimeZones.TZData.compile()

    @test TimeZone("Etc/GMT") == FixedTimeZone("Etc/GMT", 0)
    @test TimeZone("Etc/GMT+12") == FixedTimeZone("Etc/GMT+12", -12 * 3600)
    @test TimeZone("Etc/GMT-14") == FixedTimeZone("Etc/GMT-14", 14 * 3600)


    # Compile tz source files with an extended max_year. An example from the FAQ.
    warsaw = TimeZone("Europe/Warsaw")

    @test last(warsaw.transitions).utc_datetime == DateTime(2037, 10, 25, 1)
    @test get(warsaw.cutoff) == DateTime(2038, 3, 28, 1)
    @test_throws TimeZones.UnhandledTimeError ZonedDateTime(DateTime(2039), warsaw)

    TimeZones.TZData.compile(max_year=2200)
    new_warsaw = TimeZone("Europe/Warsaw")

    @test warsaw !== new_warsaw
    @test last(new_warsaw.transitions).utc_datetime == DateTime(2200, 10, 26, 1)
    @test get(new_warsaw.cutoff) == DateTime(2201, 3, 29, 1)
    ZonedDateTime(2100, new_warsaw)  # Test this doesn't throw an exception

    @test_throws TimeZones.UnhandledTimeError ZonedDateTime(2100, warsaw)


    # Using the tz string macro which runs at parse time means that the resulting TimeZone
    # will not reflect changes made from compile or new builds during runtime.
    @test tz"Africa/Windhoek" != TimeZone("Africa/Windhoek")
    @test get(tz"Africa/Windhoek".cutoff, typemax(DateTime)) != DateTime(2201, 4, 5)
    @test get(TimeZone("Africa/Windhoek").cutoff) == DateTime(2201, 4, 5)
end
