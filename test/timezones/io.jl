fixed = FixedTimeZone("UTC+01:00", 3600)
warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)
dt = DateTime(1942,12,25,1,23,45)


# TimeZones as a string
@test string(warsaw) == "Europe/Warsaw"
@test string(fixed) == "UTC+01:00"
@test string(fixed.offset) == "+01:00"

buffer = IOBuffer()
show(buffer, warsaw)
@test takebuf_string(buffer) == "Europe/Warsaw"

# ZonedDateTime as a string
@test string(ZonedDateTime(dt, warsaw)) == "1942-12-25T01:23:45+01:00"

buffer = IOBuffer()
show(buffer, ZonedDateTime(dt, warsaw))
@test takebuf_string(buffer) == "1942-12-25T01:23:45+01:00"

# ZonedDateTime parsing. Note this will use the compiled timezone information.
@test ZonedDateTime("1942-12-25T01:23:45+0100", "yyyy-mm-ddTHH:MM:SSzzz") == ZonedDateTime(dt, fixed)
@test ZonedDateTime("1942-12-25T01:23:45 Europe/Warsaw", "yyyy-mm-ddTHH:MM:SS ZZZ") == ZonedDateTime(dt, warsaw)

# Note: CET here represents the FixedTimeZone used in Europe/Warsaw and not the
# VariableTimeZone CET.
@test_throws ArgumentError ZonedDateTime("1942-12-25T01:23:45 CET", "yyyy-mm-ddTHH:MM:SS ZZZ")

# Creating a ZonedDateTime requires a TimeZone to be present.
@test_throws ArgumentError ZonedDateTime("1942-12-25T01:23:45", "yyyy-mm-ddTHH:MM:SSzzz")


# ZonedDateTime formatting
f = "yyyy/m/d H:M:S ZZZ"
@test Dates.format(ZonedDateTime(dt, fixed), f) == "1942/12/25 1:23:45 UTC+01:00"
@test Dates.format(ZonedDateTime(dt, warsaw), f) == "1942/12/25 1:23:45 Europe/Warsaw"

f = "yyyy/m/d H:M:S zzz"
@test Dates.format(ZonedDateTime(dt, fixed), f) == "1942/12/25 1:23:45 +01:00"
@test Dates.format(ZonedDateTime(dt, warsaw), f) == "1942/12/25 1:23:45 +01:00"
