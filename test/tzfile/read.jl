using TimeZones: Transition
using TimeZones.TZFile: TZFile, TZFILE_CUTOFF

desigs = b"LMT\0WSST\0SDT\0WSDT\0"  # Pacific/Apia
@test TZFile.get_designation(desigs, 5) == "WSST"
@test TZFile.get_designation(desigs, 6) == "SST"
@test TZFile.get_designation(desigs, 10) == "SDT"
@test TZFile.get_designation(desigs, 14) == "WSDT"


# Extracts Transitions such that the two arrays start and stop at the
# same DateTimes.
function overlap(a::Array{Transition}, b::Array{Transition})
    start_dt = max(first(a).utc_datetime, first(b).utc_datetime)
    end_dt = min(last(a).utc_datetime, last(b).utc_datetime)

    within = t -> start_dt <= t.utc_datetime <= end_dt
    return a[findall(within, a)], b[findall(within, b)]
end

function issimilar(x::Transition, y::Transition)
    x == y || x.utc_datetime == y.utc_datetime && x.zone.name == y.zone.name && isequal(x.zone.offset, y.zone.offset)
end

@testset "read_signature" begin
    @test TZFile.read_signature(IOBuffer(b"TZif")) == b"TZif"
    @test_throws ArgumentError TZFile.read_signature(IOBuffer(b"TZya"))
end

@testset "read_version" begin
    @test TZFile.read_version(IOBuffer("\0")) == '\0'
    @test TZFile.read_version(IOBuffer("2")) == '2'
    @test TZFile.read_version(IOBuffer("3")) == '3'
    @test TZFile.read_version(IOBuffer("4")) == '4'
    @test_throws ArgumentError TZFile.read_version(IOBuffer("5"))
end

@test_throws ArgumentError TZFile.read(IOBuffer())

# Compare tzfile transitions with those we resolved directly from the Olson zones/rules

# Ensure that `TZFile.read` returns a `FixedTimeZone` with the right data
utc = FixedTimeZone("UTC", 0)
open(joinpath(TZFILE_DIR, "Etc", "UTC")) do f
    tz = TZFile.read(f)("UTC")
    @test tz == utc
end

# Fixed time zone using version 2 data.
utc_plus_6 = FixedTimeZone("UTC+6", 6 * 3600)
open(joinpath(TZFILE_DIR, "Etc", "GMT-6")) do f
    tz = TZFile.read(f)("UTC+6")
    @test tz == utc_plus_6
end

warsaw = first(compile("Europe/Warsaw", tzdata["europe"]))
open(joinpath(TZFILE_DIR, "Europe", "Warsaw")) do f
    tz = TZFile.read(f)("Europe/Warsaw")
    @test string(tz) == "Europe/Warsaw"
    @test first(tz.transitions).utc_datetime == DateTime(1915,8,4,22,36)
    @test last(tz.transitions).utc_datetime == DateTime(2037,10,25,1)
    @test tz.cutoff == TZFILE_CUTOFF
    @test ==(overlap(tz.transitions, warsaw.transitions)...)
end

# Read version 1 compatible data
open(joinpath(TZFILE_DIR, "Europe", "Warsaw (Version 2)")) do f
    TZFile.read_signature(f)
    version = TZFile.read_version(f)
    tz = TZFile.read_content(f; version='\0')("Europe/Warsaw")
    @test version == '2'
    @test string(tz) == "Europe/Warsaw"
    @test first(tz.transitions).utc_datetime == typemin(DateTime)
    @test last(tz.transitions).utc_datetime == DateTime(2037,10,25,1)
    @test tz.cutoff == TZFILE_CUTOFF

    # File skips 1879-12-31T22:36:00
    @test ==(overlap(tz.transitions, warsaw.transitions[3:end])...)
end

# Read version 2 data
open(joinpath(TZFILE_DIR, "Europe", "Warsaw (Version 2)")) do f
    tz = TZFile.read(f)("Europe/Warsaw")
    @test string(tz) == "Europe/Warsaw"
    @test first(tz.transitions).utc_datetime == typemin(DateTime)
    @test last(tz.transitions).utc_datetime == DateTime(2037,10,25,1)
    @test tz.cutoff == TZFILE_CUTOFF
    @test ==(overlap(tz.transitions, warsaw.transitions)...)
end


godthab = first(compile("America/Godthab", tzdata["europe"]))
open(joinpath(TZFILE_DIR, "America", "Godthab")) do f
    tz = TZFile.read(f)("America/Godthab")
    @test string(tz) == "America/Godthab"
    @test first(tz.transitions).utc_datetime == DateTime(1916,7,28,3,26,56)
    @test last(tz.transitions).utc_datetime == DateTime(2037,10,25,1)
    @test tz.cutoff == TZFILE_CUTOFF
    @test ==(overlap(tz.transitions, godthab.transitions)...)
end

# Read version 1 compatible data
open(joinpath(TZFILE_DIR, "America", "Godthab (Version 3)")) do f
    TZFile.read_signature(f)
    version = TZFile.read_version(f)
    tz = TZFile.read_content(f; version='\0')("America/Godthab")
    @test version == '3'
    @test string(tz) == "America/Godthab"
    @test first(tz.transitions).utc_datetime == typemin(DateTime)
    @test last(tz.transitions).utc_datetime == DateTime(2037,10,25,1)
    @test tz.cutoff == TZFILE_CUTOFF
    @test ==(overlap(tz.transitions, godthab.transitions)...)
end

# Read version 3 data
open(joinpath(TZFILE_DIR, "America", "Godthab (Version 3)")) do f
    tz = TZFile.read(f)("America/Godthab")
    @test string(tz) == "America/Godthab"
    @test first(tz.transitions).utc_datetime == typemin(DateTime)
    @test last(tz.transitions).utc_datetime == DateTime(2037,10,25,1)
    @test tz.cutoff == TZFILE_CUTOFF
    @test ==(overlap(tz.transitions, godthab.transitions)...)
end


# "Pacific/Apia" was the time zone I was thinking could be an issue for the
# DST calculation. The entire day of 2011/12/30 was skipped when they changed from a
# -11:00 GMT offset to 13:00 GMT offset
apia = first(compile("Pacific/Apia", tzdata["australasia"]))
open(joinpath(TZFILE_DIR, "Pacific", "Apia")) do f
    tz = TZFile.read(f)("Pacific/Apia")
    @test string(tz) == "Pacific/Apia"
    @test first(tz.transitions).utc_datetime == DateTime(1911,1,1,11,26,56)
    @test last(tz.transitions).utc_datetime == DateTime(2037,9,26,14)
    @test tz.cutoff == TZFILE_CUTOFF
    @test ==(overlap(tz.transitions, apia.transitions)...)
end

# Because `TZfile.read` files only store a single offset if both utc and dst change at the
# same time then the resulting utc and dst might not be quite right. Most notably during
# midsomer back in 1940's there were 2 different dst one after another, we get a
# different utc and dst than Olson.
paris = first(compile("Europe/Paris", tzdata["europe"]))
open(joinpath(TZFILE_DIR, "Europe", "Paris")) do f
    tz = TZFile.read(f)("Europe/Paris")
    @test string(tz) == "Europe/Paris"
    @test first(tz.transitions).utc_datetime == DateTime(1911,3,10,23,51,39)
    @test last(tz.transitions).utc_datetime == DateTime(2037,10,25,1)
    @test tz.cutoff == TZFILE_CUTOFF

    tz_transitions, paris_transitions = overlap(tz.transitions, paris.transitions)

    # Indices 56:2:58 don't match due to issues with Midsummer time.
    mask = tz_transitions .== paris_transitions
    neg_mask = map(!, mask)
    @test sum(neg_mask) == 2
    @test tz_transitions[mask] == paris_transitions[mask]
    @test all(map(issimilar, tz_transitions[neg_mask], paris_transitions[neg_mask]))
end

madrid = first(compile("Europe/Madrid", tzdata["europe"]))
open(joinpath(TZFILE_DIR, "Europe", "Madrid")) do f
    tz = TZFile.read(f)("Europe/Madrid")
    @test string(tz) == "Europe/Madrid"
    @test first(tz.transitions).utc_datetime == DateTime(1917,5,5,23)
    @test last(tz.transitions).utc_datetime == DateTime(2037,10,25,1)
    @test tz.cutoff == TZFILE_CUTOFF

    tz_transitions, madrid_transitions = overlap(tz.transitions, madrid.transitions)

    # Indices 24:2:32 don't match due to issues with Midsummer time.
    mask = tz_transitions .== madrid_transitions
    neg_mask = map(!, mask)
    @test sum(neg_mask) == 5
    @test tz_transitions[mask] == madrid_transitions[mask]
    @test all(map(issimilar, tz_transitions[neg_mask], madrid_transitions[neg_mask]))
end


# "Australia/Perth" test processing a tzfile that should not contain a cutoff
perth = first(compile("Australia/Perth", tzdata["australasia"]))
open(joinpath(TZFILE_DIR, "Australia", "Perth")) do f
    tz = TZFile.read(f)("Australia/Perth")
    @test string(tz) == "Australia/Perth"
    @test first(tz.transitions).utc_datetime == DateTime(1916,12,31,16,1)
    @test last(tz.transitions).utc_datetime == DateTime(2009,3,28,18)
    @test tz.cutoff === nothing

    tz_transitions, perth_transitions = overlap(tz.transitions, perth.transitions)

    # Index 1 doesn't match up
    mask = tz_transitions .== perth_transitions
    neg_mask = map(!, mask)
    @test sum(neg_mask) == 1
    @test tz_transitions[mask] == perth_transitions[mask]
    @test all(map(issimilar, tz_transitions[neg_mask], perth_transitions[neg_mask]))
end
