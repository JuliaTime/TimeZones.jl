fixed = FixedTimeZone("UTC+01:00", 3600)
warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)
dt = DateTime(1942,12,25,1,23,45)


# VariableTimeZone as a string
@test string(warsaw) == "Europe/Warsaw"

buffer = IOBuffer()
show(buffer, warsaw)
@test takebuf_string(buffer) == "Europe/Warsaw"

# ZonedDateTime as a string
@test string(ZonedDateTime(dt, warsaw)) == "1942-12-25T01:23:45+01:00"

buffer = IOBuffer()
show(buffer, ZonedDateTime(dt, warsaw))
@test takebuf_string(buffer) == "1942-12-25T01:23:45+01:00"

# ZonedDateTime parsing
@test DateTime("1942-12-25T01:23:45+0100", "yyyy-mm-ddTHH:MM:SSzzz") == ZonedDateTime(dt, fixed)
@test DateTime("1942-12-25T01:23:45 Europe/Warsaw", "yyyy-mm-ddTHH:MM:SS ZZZ") == ZonedDateTime(dt, warsaw)

# Note: CET here represents the FixedTimeZone used in Europe/Warsaw and not the
# VariableTimeZone CET.
@test_throws ArgumentError DateTime("1942-12-25T01:23:45 CET", "yyyy-mm-ddTHH:MM:SS ZZZ")
