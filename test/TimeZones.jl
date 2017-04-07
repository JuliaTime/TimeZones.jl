# Deserialization can cause us to have two immutables that are not using the same memory
@test TimeZone("Europe/Warsaw") === TimeZone("Europe/Warsaw")

if lowercase(get(ENV, "CI", "false")) == "true"
    info("Testing build process")

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
end
