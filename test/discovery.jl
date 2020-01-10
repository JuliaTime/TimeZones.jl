using TimeZones: timezone_names
using Dates: Millisecond


names = timezone_names()
@test length(names) >= 436
@test isa(names, Vector{String})
@test issorted(names)

# Make sure that extra time zones exist from "deps/tzdata/utc".
# If tests fail try rebuilding the package: Pkg.build("TimeZones")
@test "UTC" in names
@test "GMT" in names

timezones = all_timezones()
@test length(timezones) == length(names)
@test isa(timezones, Vector{TimeZone})

timezones = timezones_from_abbr("EET")
@test length(timezones) >= 29
@test isa(timezones, Vector{TimeZone})

# Note: Unlike time zone names it is possible, although unlikely, for the number of
# abbreviations to decrease over time. A number of abbreviations were eliminated in 2016
# instead of using invented or obsolete alphanumeric time zone abbreviations. Since the
# number of abbreviates is hard to predict we'll avoid testing the number of abbreviations.
abbrs = timezone_abbrs()
@test isa(abbrs, Vector{String})
@test issorted(abbrs)


wpg = first(compile("America/Winnipeg", tzdata["northamerica"]))
apia = first(compile("Pacific/Apia", tzdata["australasia"]))
paris = first(compile("Europe/Paris", tzdata["europe"]))

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
        local patch = @patch now(tz::TimeZone) = ZonedDateTime(2000, 1, 1, tz)
        apply(patch) do
            @test next_transition_instant(wpg) == ZonedDateTime(2000, 4, 2, 3, wpg)
        end
    end

    @testset "fixed time zone" begin
        @test next_transition_instant(ZonedDateTime(2018, 1, 1, tz"UTC")) === nothing
    end

    @testset "no future transition" begin
        # Determine the last transition instant for the time zone
        t = wpg.transitions[end]
        last_trans_instant = ZonedDateTime(t.utc_datetime, wpg, t.zone)

        @test next_transition_instant(last_trans_instant) !== nothing
        @test next_transition_instant(last_trans_instant + Millisecond(1)) === nothing
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
        local patch = @patch now(tz::TimeZone) = ZonedDateTime(2000, 1, 1, tz)
        apply(patch) do
            @test occursin("2000-04-02", sprint(show_next_transition, wpg))
        end
    end

    @testset "fixed time zone" begin
        msg = "No transitions exist in time zone UTC"
        instant = ZonedDateTime(2019 ,1, 1, tz"UTC")

        io = IOBuffer()
        @test_logs (:warn, msg) show_next_transition(io, instant)
        @test isempty(read(seekstart(io), String))
    end

    @testset "no future transition" begin
        msg = "No transition exists in America/Winnipeg after: 2038-03-14T01:59:59.999-06:00"
        instant = ZonedDateTime(wpg.cutoff - Millisecond(1), wpg; from_utc=true)

        io = IOBuffer()
        @test_logs (:warn, msg) show_next_transition(io, instant)
        @test isempty(read(seekstart(io), String))
    end

    @testset "vararg stack overflow" begin
        # Note: Would cause `Segmentation fault: 11` in Julia 1.0.5
        @test_throws MethodError show_next_transition(1)
    end
end
