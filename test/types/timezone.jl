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
