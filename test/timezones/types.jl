using TimeZones
import Base.Dates: Second

warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)

# Typical "spring-forward" behaviour
dts = (
    DateTime(1916,4,30,22),
    DateTime(1916,4,30,23),
    DateTime(1916,5,1,0),
)
@test_throws NonExistentTimeError ZonedDateTime(dts[2], warsaw)

@test ZonedDateTime(dts[1], warsaw).zone.name == :CET
@test ZonedDateTime(dts[3], warsaw).zone.name == :CEST

@test ZonedDateTime(dts[1], warsaw).utc_datetime == DateTime(1916,4,30,21)
@test ZonedDateTime(dts[3], warsaw).utc_datetime == DateTime(1916,4,30,22)


# Typical "fall-back" behaviour
dt = DateTime(1916, 10, 1, 0)
@test_throws AmbiguousTimeError ZonedDateTime(dt, warsaw)

@test ZonedDateTime(dt, warsaw, 1).zone.name == :CEST
@test ZonedDateTime(dt, warsaw, 2).zone.name == :CET
@test ZonedDateTime(dt, warsaw, true).zone.name == :CEST
@test ZonedDateTime(dt, warsaw, false).zone.name == :CET

@test ZonedDateTime(dt, warsaw, 1).utc_datetime == DateTime(1916, 9, 30, 22)
@test ZonedDateTime(dt, warsaw, 2).utc_datetime == DateTime(1916, 9, 30, 23)
@test ZonedDateTime(dt, warsaw, true).utc_datetime == DateTime(1916, 9, 30, 22)
@test ZonedDateTime(dt, warsaw, false).utc_datetime == DateTime(1916, 9, 30, 23)

# Zone offset reduced creating an ambigious hour
dt = DateTime(1922,5,31,23)
@test_throws AmbiguousTimeError ZonedDateTime(dt, warsaw)

@test ZonedDateTime(dt, warsaw, 1).zone.name == :EET
@test ZonedDateTime(dt, warsaw, 2).zone.name == :CET
@test_throws AmbiguousTimeError ZonedDateTime(dt, warsaw, true)
@test_throws AmbiguousTimeError ZonedDateTime(dt, warsaw, false)

@test ZonedDateTime(dt, warsaw, 1).utc_datetime == DateTime(1922, 5, 31, 21)
@test ZonedDateTime(dt, warsaw, 2).utc_datetime == DateTime(1922, 5, 31, 22)


# Check behaviour when save is larger than an hour.
paris = resolve("Europe/Paris", tzdata["europe"]...)

@test ZonedDateTime(DateTime(1945,4,2,1), paris).zone == FixedTimeZone("WEST", 0, 3600)
@test_throws NonExistentTimeError ZonedDateTime(DateTime(1945,4,2,2), paris)
@test ZonedDateTime(DateTime(1945,4,2,3), paris).zone == FixedTimeZone("WEMT", 0, 7200)

@test_throws AmbiguousTimeError ZonedDateTime(DateTime(1945,9,16,2), paris)
@test ZonedDateTime(DateTime(1945,9,16,2), paris, 1).zone == FixedTimeZone("WEMT", 0, 7200)
@test ZonedDateTime(DateTime(1945,9,16,2), paris, 2).zone == FixedTimeZone("CET", 3600, 0)

# Ensure that dates are continuous when both a UTC offset and the DST offset change.
@test ZonedDateTime(DateTime(1945,9,16,1), paris).utc_datetime == DateTime(1945,9,15,23)
@test ZonedDateTime(DateTime(1945,9,16,2), paris, 1).utc_datetime == DateTime(1945,9,16,0)
@test ZonedDateTime(DateTime(1945,9,16,2), paris, 2).utc_datetime == DateTime(1945,9,16,1)
@test ZonedDateTime(DateTime(1945,9,16,3), paris).utc_datetime == DateTime(1945,9,16,2)


# Transitions changes that exceed an hour.
t = VariableTimeZone("Testing", [
    Transition(DateTime(1800,1,1), FixedTimeZone("TST",0,0)),
    Transition(DateTime(1950,4,1), FixedTimeZone("TDT",0,7200)),
    Transition(DateTime(1950,9,1), FixedTimeZone("TST",0,0)),
])

# A "spring forward" where 2 hours are skipped.
@test ZonedDateTime(DateTime(1950,3,31,23), t).zone == FixedTimeZone("TST",0,0)
@test_throws NonExistentTimeError ZonedDateTime(DateTime(1950,4,1,0), t)
@test_throws NonExistentTimeError ZonedDateTime(DateTime(1950,4,1,1), t)
@test ZonedDateTime(DateTime(1950,4,1,2), t).zone == FixedTimeZone("TDT",0,7200)


# A "fall back" where 2 hours are duplicated. Never appears to occur in reality.
@test ZonedDateTime(DateTime(1950,8,31,23), t).utc_datetime == DateTime(1950,8,31,21)  # TDT

# First occurrences of duplicated hours.
@test ZonedDateTime(DateTime(1950,9,1,0), t, 1).utc_datetime == DateTime(1950,8,31,22) # TST
@test ZonedDateTime(DateTime(1950,9,1,1), t, 1).utc_datetime == DateTime(1950,8,31,23) # TST

# Second occurrences of duplicated hours.
@test ZonedDateTime(DateTime(1950,9,1,0), t, 2).utc_datetime == DateTime(1950,9,1,0)   # TDT
@test ZonedDateTime(DateTime(1950,9,1,1), t, 2).utc_datetime == DateTime(1950,9,1,1)   # TDT

@test ZonedDateTime(DateTime(1950,9,1,2), t).utc_datetime == DateTime(1950,9,1,2)      # TDT


# Ambigious local DateTime that has more than 2 solutions. Never occurs in reality.
t = VariableTimeZone("Testing", [
    Transition(DateTime(1800,1,1), FixedTimeZone("TST",0,0)),
    Transition(DateTime(1960,4,1), FixedTimeZone("TDT",0,7200)),
    Transition(DateTime(1960,8,31,23), FixedTimeZone("TXT",0,3600)),
    Transition(DateTime(1960,9,1), FixedTimeZone("TST",0,0)),
])

@test ZonedDateTime(DateTime(1960,8,31,23), t).utc_datetime == DateTime(1960,8,31,21)  # TDT
@test ZonedDateTime(DateTime(1960,9,1,0), t, 1).utc_datetime == DateTime(1960,8,31,22) # TDT
@test ZonedDateTime(DateTime(1960,9,1,0), t, 2).utc_datetime == DateTime(1960,8,31,23) # TXT
@test ZonedDateTime(DateTime(1960,9,1,0), t, 3).utc_datetime == DateTime(1960,9,1,0)   # TST
@test ZonedDateTime(DateTime(1960,9,1,1), t).utc_datetime == DateTime(1960,9,1,1)      # TST

@test_throws AmbiguousTimeError ZonedDateTime(DateTime(1960,9,1,0), t, true)
@test_throws AmbiguousTimeError ZonedDateTime(DateTime(1960,9,1,0), t, false)


# Significant offset change: -11:00 -> 13:00.
apia = resolve("Pacific/Apia", tzdata["australasia"]...)

# Skips an entire day.
@test ZonedDateTime(DateTime(2011,12,29,23),apia).utc_datetime == DateTime(2011,12,30,9)
@test_throws NonExistentTimeError ZonedDateTime(DateTime(2011,12,30,0),apia)
@test_throws NonExistentTimeError ZonedDateTime(DateTime(2011,12,30,23),apia)
@test ZonedDateTime(DateTime(2011,12,31,0),apia).utc_datetime == DateTime(2011,12,30,10)


# Redundant transitions should be ignored.
# Note: that this can occur in reality if the TZ database parse has a Zone that ends at
# the same time a Rule starts. When this occurs the duplicates always in standard time
# with the same abbreviation.
zone = Dict{String,FixedTimeZone}()
zone["DTST"] = TimeZones.DaylightSavingTimeZone("DTST", 0, 0)
zone["DTDT-1"] = TimeZones.DaylightSavingTimeZone("DTDT-1", 0, 3600)
zone["DTDT-2"] = TimeZones.DaylightSavingTimeZone("DTDT-2", 0, 3600)

dup = VariableTimeZone("DuplicateTest", [
    Transition(DateTime(1800,1,1), zone["DTST"])
    Transition(DateTime(1935,4,1), zone["DTDT-1"])  # Ignored
    Transition(DateTime(1935,4,1), zone["DTDT-2"])
    Transition(DateTime(1935,9,1), zone["DTST"])
])

# Make sure that the duplicated hour only doesn't contain an additional entry.
@test_throws AmbiguousTimeError ZonedDateTime(DateTime(1935,9,1), dup)
@test ZonedDateTime(DateTime(1935,9,1), dup, 1).zone.name == symbol("DTDT-2")
@test ZonedDateTime(DateTime(1935,9,1), dup, 2).zone.name == :DTST
@test_throws BoundsError ZonedDateTime(DateTime(1935,9,1), dup, 3)

# Ensure that DTDT-1 is completely ignored.
@test_throws NonExistentTimeError ZonedDateTime(DateTime(1935,4,1), dup)
@test ZonedDateTime(DateTime(1935,4,1,1), dup).zone.name == symbol("DTDT-2")
@test ZonedDateTime(DateTime(1935,8,31,23), dup).zone.name == symbol("DTDT-2")