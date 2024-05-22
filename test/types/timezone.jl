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

@testset "fixed time zone cache skip" begin
    # Reset the tz cache as if we had just loaded the package
    lock(TimeZones._TZ_CACHE_LOCK) do
        TimeZones._TZ_CACHE_INITIALIZED[] = false
        empty!(TimeZones._TZ_CACHE)
    end

    try
        @test isempty(TimeZones._TZ_CACHE)

        TimeZone("UTC")  # Construct a `FixedTimeZone` without loading the tz cache
        @test isempty(TimeZones._TZ_CACHE)
    finally
        TimeZones._reload_tz_cache(TimeZones._COMPILED_DIR[])
    end
end
