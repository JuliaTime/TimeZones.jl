using TimeZones: Class

@testset "istimezone" begin
    @test istimezone("Europe/Warsaw")
    @test istimezone("UTC+02")
    @test !istimezone("Europe/Camelot")
end

# Deserialization can cause us to have two immutables that are not using the same memory
@test TimeZone("Europe/Warsaw") === TimeZone("Europe/Warsaw")
@test tz"Africa/Nairobi" === TimeZone("Africa/Nairobi")

@testset "etcetera" begin
    # Note: In previous versions of TimeZones.jl the "etcetera" source file was not parsed
    # by default.
    @test !istimezone("Etc/GMT")
    @test !istimezone("Etc/GMT+12")
    @test !istimezone("Etc/GMT-14")

    @test istimezone("Etc/GMT", Class(:LEGACY))
    @test istimezone("Etc/GMT+12", Class(:LEGACY))
    @test istimezone("Etc/GMT-14", Class(:LEGACY))

    @test TimeZone("Etc/GMT", Class(:LEGACY)) == FixedTimeZone("Etc/GMT", 0)
    @test TimeZone("Etc/GMT+12", Class(:LEGACY)) == FixedTimeZone("Etc/GMT+12", -12 * 3600)
    @test TimeZone("Etc/GMT-14", Class(:LEGACY)) == FixedTimeZone("Etc/GMT-14", 14 * 3600)
end

@testset "legacy timezone auto-redirect" begin
    # Auto-redirect only works with TZJFile v2 (which stores link information)
    if TimeZones.TZJFile.tzjfile_version() >= 2
        # Auto-redirect with deprecation warning
        # Note: US/Pacific is a LEGACY timezone that links to America/Los_Angeles
        @test_logs (:warn, r"US/Pacific.*deprecated.*America/Los_Angeles") match_mode=:any begin
            tz = TimeZone("US/Pacific")
            @test TimeZones.name(tz) == "America/Los_Angeles"
        end

        # Explicit opt-in to LEGACY bypasses auto-redirect
        tz_legacy = TimeZone("US/Pacific", Class(:LEGACY))
        @test TimeZones.name(tz_legacy) == "US/Pacific"

        # istimezone returns true for LEGACY that will auto-redirect
        @test istimezone("US/Pacific")  # Uses default mask, will redirect
        @test istimezone("US/Pacific", Class(:DEFAULT))
        @test istimezone("US/Pacific", Class(:LEGACY))  # Explicit LEGACY allowed
    else
        # With v1 format, LEGACY timezones don't have link info, so they're blocked
        @test_throws ArgumentError TimeZone("US/Pacific")
        @test !istimezone("US/Pacific")

        # Explicit opt-in to LEGACY still works
        tz_legacy = TimeZone("US/Pacific", Class(:LEGACY))
        @test TimeZones.name(tz_legacy) == "US/Pacific"
        @test istimezone("US/Pacific", Class(:LEGACY))
    end
end

# These allocation tests are a bit fragile. Clearing the cache makes these tests more
# in on Julia 1.12.0-DEV.1786.
@testset "allocations" begin
    with_tz_cache() do
        # Trigger compilation (only upon the first call in Julia) and populate the cache
        @test @allocations(TimeZone("UTC")) > 0

        @test @allocations(TimeZone("UTC")) == 0
        @test @allocations(istimezone("UTC")) == 0
    end

    with_tz_cache() do
        # Trigger compilation (only upon the first call in Julia) and populate the cache
        @test @allocations(TimeZone("America/Winnipeg")) > 0

        @test @allocations(TimeZone("America/Winnipeg")) == 2
        @test @allocations(istimezone("America/Winnipeg")) == 1
    end
end
