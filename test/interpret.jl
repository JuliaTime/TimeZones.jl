# Contains both positive and negative UTC offsets and observes daylight saving time.
apia = first(compile("Pacific/Apia", tzdata["australasia"]))

ambiguous_pos = DateTime(2011,4,2,3)
non_existent_pos = DateTime(2011,9,24,3)
ambiguous_neg = DateTime(2012,4,1,3)
non_existent_neg = DateTime(2012,9,30,3)

@test_throws AmbiguousTimeError ZonedDateTime(ambiguous_pos, apia)
@test_throws NonExistentTimeError ZonedDateTime(non_existent_pos, apia)
@test_throws AmbiguousTimeError ZonedDateTime(ambiguous_neg, apia)
@test_throws NonExistentTimeError ZonedDateTime(non_existent_neg, apia)

@test TimeZones.shift_gap(ambiguous_pos, apia) == ZonedDateTime[]
@test TimeZones.shift_gap(non_existent_pos, apia) == [
    ZonedDateTime(2011, 9, 24, 2, 59, 59, 999, apia),
    ZonedDateTime(2011, 9, 24, 4, apia),
]
@test TimeZones.shift_gap(ambiguous_neg, apia) == ZonedDateTime[]
@test TimeZones.shift_gap(non_existent_neg, apia) == [
    ZonedDateTime(2012, 9, 30, 2, 59, 59, 999, apia),
    ZonedDateTime(2012, 9, 30, 4, apia),
]

# Valid local datetimes close to the non-existent hour should have no boundaries as are
# already valid.
@test TimeZones.shift_gap(non_existent_pos - Second(1), apia) == ZonedDateTime[]
@test TimeZones.shift_gap(non_existent_pos + Hour(1), apia) == ZonedDateTime[]
@test TimeZones.shift_gap(non_existent_neg - Second(1), apia) == ZonedDateTime[]
@test TimeZones.shift_gap(non_existent_neg + Hour(1), apia) == ZonedDateTime[]


# Create custom VariableTimeZones to test corner cases
zone = Dict{AbstractString,FixedTimeZone}()
zone["T+0"] = FixedTimeZone("T+0", 0)
zone["T+1"] = FixedTimeZone("T+1", 3600)
zone["T+2"] = FixedTimeZone("T+2", 7200)

# A time zone with a two hour gap
long = VariableTimeZone("Test/LongGap", [
    Transition(DateTime(1800,1,1,0), zone["T+1"])
    Transition(DateTime(1900,1,1,0), zone["T+0"])
    Transition(DateTime(1935,4,1,2), zone["T+2"])
])

# A time zone with an unnecessary transition that typically is hidden to the user
hidden = VariableTimeZone("Test/HiddenTransition", [
    Transition(DateTime(1800,1,1,0), zone["T+1"])
    Transition(DateTime(1900,1,1,0), zone["T+0"])
    Transition(DateTime(1935,4,1,2), zone["T+1"])  # The hidden transition
    Transition(DateTime(1935,4,1,2), zone["T+2"])
])

non_existent_1 = DateTime(1935,4,1,2)
non_existent_2 = DateTime(1935,4,1,3)

# Both "long" and "hidden" are identical for the following tests
for tz in (long, hidden)
    local tz
    boundaries = [
        ZonedDateTime(1935, 4, 1, 1, 59, 59, 999, tz),
        ZonedDateTime(1935, 4, 1, 4, tz),
    ]

    @test_throws NonExistentTimeError ZonedDateTime(non_existent_1, tz)
    @test_throws NonExistentTimeError ZonedDateTime(non_existent_2, tz)

    @test TimeZones.shift_gap(non_existent_1, tz) == boundaries
    @test TimeZones.shift_gap(non_existent_2, tz) == boundaries
end


# Various DateTimes in Pacific/Apia
valid = DateTime(2013,1,1)
ambiguous = ambiguous_pos
non_existent = non_existent_pos

# first_valid/last_valid with a step
@test TimeZones.first_valid(valid, apia, Hour(1)) == ZonedDateTime(valid, apia)
@test TimeZones.last_valid(valid, apia, Hour(1)) == ZonedDateTime(valid, apia)

@test TimeZones.first_valid(non_existent, apia, Hour(1)) == ZonedDateTime(2011,9,24,4,apia)
@test TimeZones.last_valid(non_existent, apia, Hour(1)) == ZonedDateTime(2011,9,24,2,apia)

@test TimeZones.first_valid(ambiguous, apia, Hour(1)) == ZonedDateTime(ambiguous,apia,1)
@test TimeZones.last_valid(ambiguous, apia, Hour(1)) == ZonedDateTime(ambiguous,apia,2)

# first_valid/last_valid with no step
@test TimeZones.first_valid(valid, apia) == ZonedDateTime(valid, apia)
@test TimeZones.last_valid(valid, apia) == ZonedDateTime(valid, apia)

@test TimeZones.first_valid(non_existent, apia) == ZonedDateTime(2011,9,24,4,apia)
@test TimeZones.last_valid(non_existent, apia) == ZonedDateTime(2011,9,24,2,59,59,999,apia)

@test TimeZones.first_valid(ambiguous, apia) == ZonedDateTime(ambiguous,apia,1)
@test TimeZones.last_valid(ambiguous, apia) == ZonedDateTime(ambiguous,apia,2)
