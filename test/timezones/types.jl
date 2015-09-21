import TimeZones: Transition
import Base.Dates: Second


# Constructor FixedTimeZone from a string.
@test FixedTimeZone("0123") == FixedTimeZone("UTC+01:23", 4980)
@test FixedTimeZone("+0123") == FixedTimeZone("UTC+01:23", 4980)
@test FixedTimeZone("-0123") == FixedTimeZone("UTC-01:23", -4980)
@test FixedTimeZone("01:23") == FixedTimeZone("UTC+01:23", 4980)
@test FixedTimeZone("+01:23") == FixedTimeZone("UTC+01:23", 4980)
@test FixedTimeZone("-01:23") == FixedTimeZone("UTC-01:23", -4980)
@test FixedTimeZone("01:23:45") == FixedTimeZone("UTC+01:23:45", 5025)
@test FixedTimeZone("+01:23:45") == FixedTimeZone("UTC+01:23:45", 5025)
@test FixedTimeZone("-01:23:45") == FixedTimeZone("UTC-01:23:45", -5025)
@test FixedTimeZone("99:99:99") == FixedTimeZone("UTC+99:99:99", 362439)

@test_throws Exception FixedTimeZone("123")
@test_throws Exception FixedTimeZone("012345")
@test_throws Exception FixedTimeZone("01:-23:45")
@test_throws Exception FixedTimeZone("01:23:-45")
@test_throws Exception FixedTimeZone("01:23:45:67")


# Test exception messages
tz = FixedTimeZone("Imaginary/Zone", 0, 0)

buffer = IOBuffer()
showerror(buffer, AmbiguousTimeError(DateTime(2015,1,1), tz))
@test takebuf_string(buffer) == "Local DateTime 2015-01-01T00:00:00 is ambiguious"

buffer = IOBuffer()
showerror(buffer, NonExistentTimeError(DateTime(2015,1,1), tz))
@test takebuf_string(buffer) == "DateTime 2015-01-01T00:00:00 does not exist within Imaginary/Zone"


warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)

# Standard time behaviour
local_dt = DateTime(1916, 2, 1, 0)
utc_dt = DateTime(1916, 1, 31, 23)

# Disambiguating parameters ignored when there is no ambiguity.
@test ZonedDateTime(local_dt, warsaw).zone.name == :CET
@test ZonedDateTime(local_dt, warsaw, 1).zone.name == :CET
@test ZonedDateTime(local_dt, warsaw, 2).zone.name == :CET
@test ZonedDateTime(local_dt, warsaw, true).zone.name == :CET
@test ZonedDateTime(local_dt, warsaw, false).zone.name == :CET
@test ZonedDateTime(utc_dt, warsaw, from_utc=true).zone.name == :CET

@test ZonedDateTime(local_dt, warsaw).utc_datetime == utc_dt
@test ZonedDateTime(local_dt, warsaw, 1).utc_datetime == utc_dt
@test ZonedDateTime(local_dt, warsaw, 2).utc_datetime == utc_dt
@test ZonedDateTime(local_dt, warsaw, true).utc_datetime == utc_dt
@test ZonedDateTime(local_dt, warsaw, false).utc_datetime == utc_dt
@test ZonedDateTime(utc_dt, warsaw, from_utc=true).utc_datetime == utc_dt


# Daylight saving time behaviour
local_dt = DateTime(1916, 6, 1, 0)
utc_dt = DateTime(1916, 5, 31, 22)

# Disambiguating parameters ignored when there is no ambiguity.
@test ZonedDateTime(local_dt, warsaw).zone.name == :CEST
@test ZonedDateTime(local_dt, warsaw, 1).zone.name == :CEST
@test ZonedDateTime(local_dt, warsaw, 2).zone.name == :CEST
@test ZonedDateTime(local_dt, warsaw, true).zone.name == :CEST
@test ZonedDateTime(local_dt, warsaw, false).zone.name == :CEST
@test ZonedDateTime(utc_dt, warsaw, from_utc=true).zone.name == :CEST

@test ZonedDateTime(local_dt, warsaw).utc_datetime == utc_dt
@test ZonedDateTime(local_dt, warsaw, 1).utc_datetime == utc_dt
@test ZonedDateTime(local_dt, warsaw, 2).utc_datetime == utc_dt
@test ZonedDateTime(local_dt, warsaw, true).utc_datetime == utc_dt
@test ZonedDateTime(local_dt, warsaw, false).utc_datetime == utc_dt
@test ZonedDateTime(utc_dt, warsaw, from_utc=true).utc_datetime == utc_dt


# Typical "spring-forward" behaviour
local_dts = (
    DateTime(1916,4,30,22),
    DateTime(1916,4,30,23),
    DateTime(1916,5,1,0),
)
utc_dts = (
    DateTime(1916,4,30,21),
    DateTime(1916,4,30,22),
)
@test_throws NonExistentTimeError ZonedDateTime(local_dts[2], warsaw)
@test_throws NonExistentTimeError ZonedDateTime(local_dts[2], warsaw, 1)
@test_throws NonExistentTimeError ZonedDateTime(local_dts[2], warsaw, 2)
@test_throws NonExistentTimeError ZonedDateTime(local_dts[2], warsaw, true)
@test_throws NonExistentTimeError ZonedDateTime(local_dts[2], warsaw, false)

@test ZonedDateTime(local_dts[1], warsaw).zone.name == :CET
@test ZonedDateTime(local_dts[3], warsaw).zone.name == :CEST
@test ZonedDateTime(utc_dts[1], warsaw, from_utc=true).zone.name == :CET
@test ZonedDateTime(utc_dts[2], warsaw, from_utc=true).zone.name == :CEST

@test ZonedDateTime(local_dts[1], warsaw).utc_datetime == utc_dts[1]
@test ZonedDateTime(local_dts[3], warsaw).utc_datetime == utc_dts[2]
@test ZonedDateTime(utc_dts[1], warsaw, from_utc=true).utc_datetime == utc_dts[1]
@test ZonedDateTime(utc_dts[2], warsaw, from_utc=true).utc_datetime == utc_dts[2]


# Typical "fall-back" behaviour
local_dt = DateTime(1916, 10, 1, 0)
utc_dts = (DateTime(1916, 9, 30, 22), DateTime(1916, 9, 30, 23))
@test_throws AmbiguousTimeError ZonedDateTime(local_dt, warsaw)

@test ZonedDateTime(local_dt, warsaw, 1).zone.name == :CEST
@test ZonedDateTime(local_dt, warsaw, 2).zone.name == :CET
@test ZonedDateTime(local_dt, warsaw, true).zone.name == :CEST
@test ZonedDateTime(local_dt, warsaw, false).zone.name == :CET
@test ZonedDateTime(utc_dts[1], warsaw, from_utc=true).zone.name == :CEST
@test ZonedDateTime(utc_dts[2], warsaw, from_utc=true).zone.name == :CET

@test ZonedDateTime(local_dt, warsaw, 1).utc_datetime == utc_dts[1]
@test ZonedDateTime(local_dt, warsaw, 2).utc_datetime == utc_dts[2]
@test ZonedDateTime(local_dt, warsaw, true).utc_datetime == utc_dts[1]
@test ZonedDateTime(local_dt, warsaw, false).utc_datetime == utc_dts[2]
@test ZonedDateTime(utc_dts[1], warsaw, from_utc=true).utc_datetime == utc_dts[1]
@test ZonedDateTime(utc_dts[2], warsaw, from_utc=true).utc_datetime == utc_dts[2]

# Zone offset reduced creating an ambigious hour
local_dt = DateTime(1922,5,31,23)
utc_dts = (DateTime(1922, 5, 31, 21), DateTime(1922, 5, 31, 22))
@test_throws AmbiguousTimeError ZonedDateTime(local_dt, warsaw)

@test ZonedDateTime(local_dt, warsaw, 1).zone.name == :EET
@test ZonedDateTime(local_dt, warsaw, 2).zone.name == :CET
@test_throws AmbiguousTimeError ZonedDateTime(local_dt, warsaw, true)
@test_throws AmbiguousTimeError ZonedDateTime(local_dt, warsaw, false)
@test ZonedDateTime(utc_dts[1], warsaw, from_utc=true).zone.name == :EET
@test ZonedDateTime(utc_dts[2], warsaw, from_utc=true).zone.name == :CET

@test ZonedDateTime(local_dt, warsaw, 1).utc_datetime == utc_dts[1]
@test ZonedDateTime(local_dt, warsaw, 2).utc_datetime == utc_dts[2]
@test ZonedDateTime(utc_dts[1], warsaw, from_utc=true).utc_datetime == utc_dts[1]
@test ZonedDateTime(utc_dts[2], warsaw, from_utc=true).utc_datetime == utc_dts[2]


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
zone = Dict{AbstractString,FixedTimeZone}()
zone["DTST"] = FixedTimeZone("DTST", 0, 0)
zone["DTDT-1"] = FixedTimeZone("DTDT-1", 0, 3600)
zone["DTDT-2"] = FixedTimeZone("DTDT-2", 0, 3600)

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


# Check equality between ZonedDateTimes
utc = FixedTimeZone("UTC", 0, 0)

spring_utc = ZonedDateTime(DateTime(2010, 5, 1, 12), utc)
spring_apia = ZonedDateTime(DateTime(2010, 5, 1, 1), apia)
early_utc = ZonedDateTime(DateTime(1, 1, 1, 0), utc)

@test spring_utc.zone == FixedTimeZone("UTC", 0, 0)
@test spring_apia.zone == FixedTimeZone("SST", -39600, 0)
@test spring_utc == spring_apia
@test spring_utc !== spring_apia
@test ZonedDateTime(spring_utc, apia) === spring_apia
@test ZonedDateTime(spring_apia, utc) === spring_utc

fall_utc = ZonedDateTime(DateTime(2010, 10, 1, 12), utc)
fall_apia = ZonedDateTime(DateTime(2010, 10, 1, 2), apia)

@test fall_utc.zone == FixedTimeZone("UTC", 0, 0)
@test fall_apia.zone == FixedTimeZone("SDT", -39600, 3600)
@test fall_utc == fall_apia
@test fall_utc !== fall_apia
@test !(fall_utc < fall_apia)
@test !(fall_utc > fall_apia)
@test ZonedDateTime(fall_utc, apia) === fall_apia
@test ZonedDateTime(fall_apia, utc) === fall_utc

# A FixedTimeZone is effective for all of time where as a VariableTimeZone has as start.
@test TimeZones.utc(early_utc) < apia.transitions[1].utc_datetime
@test_throws NonExistentTimeError ZonedDateTime(early_utc, apia)


# ZonedDateTime constructor that takes any number of Period or TimeZone types
@test_throws ArgumentError ZonedDateTime(FixedTimeZone("UTC", 0, 0), FixedTimeZone("TMW", 86400, 0))
