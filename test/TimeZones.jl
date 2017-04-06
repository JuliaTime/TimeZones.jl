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
end
