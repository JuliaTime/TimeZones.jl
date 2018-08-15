import TimeZones: timezone_names
import Compat.Dates: Millisecond


names = timezone_names()
@test length(names) >= 436
@test isa(names, Array{AbstractString})
@test issorted(names)

# Make sure that extra time zones exist from "deps/tzdata/utc".
# If tests fail try rebuilding the package: Pkg.build("TimeZones")
@test "UTC" in names
@test "GMT" in names

timezones = all_timezones()
@test length(timezones) == length(names)
@test isa(timezones, Array{TimeZone})

timezones = timezones_from_abbr("EET")
@test length(timezones) >= 29
@test isa(timezones, Array{TimeZone})

# Note: Unlike time zone names it is possible, although unlikely, for the number of
# abbreviations to decrease over time. A number of abbreviations were eliminated in 2016
# instead of using invented or obsolete alphanumeric time zone abbreviations. Since the
# number of abbreviates is hard to predict we'll avoid testing the number of abbreviations.
abbrs = timezone_abbrs()
@test isa(abbrs, Array{AbstractString})
@test issorted(abbrs)


wpg = resolve("America/Winnipeg", tzdata["northamerica"]...)
apia = resolve("Pacific/Apia", tzdata["australasia"]...)
paris = resolve("Europe/Paris", tzdata["europe"]...)

@testset "next_transition_instant" begin
    @testset "non-existent" begin
        local zone = FixedTimeZone("CST", -6 * 3600)

        instant = next_transition_instant(ZonedDateTime(2018, 1, 1, wpg))
        expected_instant = ZonedDateTime(DateTime(2018, 3, 11, 8), wpg, zone)
        expected_valid = ZonedDateTime(2018, 3, 11, 3, wpg)

        @test instant === expected_instant
        @test instant == expected_valid
        @test instant !== expected_valid
        @test instant + Millisecond(0) === expected_valid
    end

    @testset "ambiguous" begin
        local zone = FixedTimeZone("CDT", -6 * 3600, 3600)

        instant = next_transition_instant(ZonedDateTime(2018, 6, 1, wpg))
        expected_instant = ZonedDateTime(DateTime(2018, 11, 4, 7), wpg, zone)
        expected_valid = ZonedDateTime(2018, 11, 4, 1, wpg, 2)

        @test instant === expected_instant
        @test instant == expected_valid
        @test instant !== expected_valid
        @test instant + Millisecond(0) === expected_valid
    end

    @testset "upcoming" begin
        if !compiled_modules_enabled
            local patch = @patch now(tz::TimeZone) = ZonedDateTime(2000, 1, 1, tz)
            apply(patch) do
                @test next_transition_instant(wpg) == ZonedDateTime(2000, 4, 2, 3, wpg)
            end
        end
    end
end

@testset "show_next_transition" begin
    @testset "non-existent" begin
        @test sprint(show_next_transition, ZonedDateTime(2018, 1, 1, wpg)) ==
            """
            Transition Date:   2018-03-11
            Local Time Change: 02:00 → 03:00 (Forward)
            Offset Change:     UTC-6/+0 → UTC-6/+1
            Transition From:   2018-03-11T01:59:59.999-06:00 (CST)
            Transition To:     2018-03-11T03:00:00.000-05:00 (CDT)
            """
    end

    @testset "ambiguous" begin
         @test sprint(show_next_transition, ZonedDateTime(2018, 6, 1, wpg)) ==
            """
            Transition Date:   2018-11-04
            Local Time Change: 02:00 → 01:00 (Backward)
            Offset Change:     UTC-6/+1 → UTC-6/+0
            Transition From:   2018-11-04T01:59:59.999-05:00 (CDT)
            Transition To:     2018-11-04T01:00:00.000-06:00 (CST)
            """
    end

    @testset "standard offset change" begin
        @test sprint(show_next_transition, ZonedDateTime(2011, 12, 1, apia)) ==
            """
            Transition Date:   2011-12-30
            Local Time Change: 00:00 → 00:00 (Forward)
            Offset Change:     UTC-11/+1 → UTC+13/+1
            Transition From:   2011-12-29T23:59:59.999-10:00 (SDT)
            Transition To:     2011-12-31T00:00:00.000+14:00 (WSDT)
            """
    end

    @testset "dst offset change" begin
        @test sprint(show_next_transition, ZonedDateTime(1945, 4, 1, paris)) ==
            """
            Transition Date:   1945-04-02
            Local Time Change: 02:00 → 03:00 (Forward)
            Offset Change:     UTC+0/+1 → UTC+0/+2
            Transition From:   1945-04-02T01:59:59.999+01:00 (WEST)
            Transition To:     1945-04-02T03:00:00.000+02:00 (WEMT)
            """
    end

    @testset "upcoming" begin
        if !compiled_modules_enabled
            local patch = @patch now(tz::TimeZone) = ZonedDateTime(2000, 1, 1, tz)
            apply(patch) do
                @test occursin("2000-04-02", sprint(show_next_transition, wpg))
            end
        end
    end
end
