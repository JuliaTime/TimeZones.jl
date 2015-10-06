import TimeZones: Transition, Offset

# Extracts Transitions such that the two arrays start and stop at the
# same DateTimes.
function overlap(a::Array{Transition}, b::Array{Transition})
    start_dt = max(first(a).utc_datetime, first(b).utc_datetime)
    end_dt = min(last(a).utc_datetime, last(b).utc_datetime)

    within = t -> start_dt <= t.utc_datetime <= end_dt
    return a[find(within, a)], b[find(within, b)]
end

function issimilar(x::Transition, y::Transition)
    x == y || x.utc_datetime == y.utc_datetime && x.zone.name == y.zone.name && issimilar(x.zone.offset, y.zone.offset)
end

function issimilar(x::Offset, y::Offset)
    x == y || Second(x) == Second(y) && (x.dst == y.dst || x.dst > Second(0) && y.dst > Second(0))
end

@test_throws AssertionError TimeZones.read_tzfile(IOBuffer(), "")

# Compare tzfile transitions with those we resolved directly from the Olson zones/rules

warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)
open(joinpath(TZFILE_DIR, "Warsaw")) do f
    tz = TimeZones.read_tzfile(f, "Europe/Warsaw")
    @test string(tz) == "Europe/Warsaw"
    @test ==(overlap(tz.transitions, warsaw.transitions)...)
end


# "Pacific/Apia" was the timezone I was thinking could be an issue for the
# DST calculation. The entire day of 2011/12/30 was skipped when they changed from a
# -11:00 GMT offset to 13:00 GMT offset
apia = resolve("Pacific/Apia", tzdata["australasia"]...)
open(joinpath(TZFILE_DIR, "Apia")) do f
    tz = TimeZones.read_tzfile(f, "Pacific/Apia")
    @test string(tz) == "Pacific/Apia"
    @test ==(overlap(tz.transitions, apia.transitions)...)
end

# Because read_tzfile files only store a single offset if both utc and dst change at the same
# time then the resulting utc and dst might not be quite right. Most notably during
# midsomer back in 1940's there were 2 different dst one after another, we get a
# different utc and dst than Olson.
paris = resolve("Europe/Paris", tzdata["europe"]...)
open(joinpath(TZFILE_DIR, "Paris")) do f
    tz = TimeZones.read_tzfile(f, "Europe/Paris")
    @test string(tz) == "Europe/Paris"

    tz_transitions, paris_transitions = overlap(tz.transitions, paris.transitions)

    # Indices 56:2:58 don't match due to issues with Midsummer time.
    mask = tz_transitions .== paris_transitions
    @test sum(!mask) == 2
    @test tz_transitions[mask] == paris_transitions[mask]
    @test all(map(issimilar, tz_transitions[!mask], paris_transitions[!mask]))
end

madrid = resolve("Europe/Madrid", tzdata["europe"]...)
open(joinpath(TZFILE_DIR, "Madrid")) do f
    tz = TimeZones.read_tzfile(f, "Europe/Madrid")
    @test string(tz) == "Europe/Madrid"

    tz_transitions, madrid_transitions = overlap(tz.transitions, madrid.transitions)

    # Indices 24:2:32 don't match due to issues with Midsummer time.
    mask = tz_transitions .== madrid_transitions
    @test sum(!mask) == 5
    @test tz_transitions[mask] == madrid_transitions[mask]
    @test all(map(issimilar, tz_transitions[!mask], madrid_transitions[!mask]))
end
