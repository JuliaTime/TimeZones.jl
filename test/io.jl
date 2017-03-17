import TimeZones.Olson: parse_components

null = FixedTimeZone("", 10800)
fixed = FixedTimeZone("UTC+01:00")
est = FixedTimeZone("EST", -18000)
warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)
apia = resolve("Pacific/Apia", tzdata["australasia"]...)
honolulu = resolve("Pacific/Honolulu", tzdata["northamerica"]...)  # Uses cutoff
ulyanovsk = resolve("Europe/Ulyanovsk", tzdata["europe"]...)  # No named abbreviations
new_york = resolve("America/New_York", tzdata["northamerica"]...)  # Underscore in name
dt = DateTime(1942,12,25,1,23,45)

buffer = IOBuffer()

# TimeZones as a string
@test string(null) == "UTC+03:00"
@test string(fixed) == "UTC+01:00"
@test string(est) == "EST"
@test string(warsaw) == "Europe/Warsaw"
@test string(apia) == "Pacific/Apia"
@test string(honolulu) == "Pacific/Honolulu"
@test string(ulyanovsk) == "Europe/Ulyanovsk"

showcompact(buffer, null)
@test Compat.String(take!(buffer)) == "UTC+03:00"
showcompact(buffer, fixed)
@test Compat.String(take!(buffer)) == "UTC+01:00"
showcompact(buffer, est)
@test Compat.String(take!(buffer)) == "EST"
showcompact(buffer, warsaw)
@test Compat.String(take!(buffer)) == "Europe/Warsaw"
showcompact(buffer, apia)
@test Compat.String(take!(buffer)) == "Pacific/Apia"
showcompact(buffer, honolulu)
@test Compat.String(take!(buffer)) == "Pacific/Honolulu"
showcompact(buffer, ulyanovsk)
@test Compat.String(take!(buffer)) == "Europe/Ulyanovsk"

show(buffer, null)
@test Compat.String(take!(buffer)) == "UTC+03:00"
show(buffer, fixed)
@test Compat.String(take!(buffer)) == "UTC+01:00"
show(buffer, est)
@test Compat.String(take!(buffer)) == "EST (UTC-5)"
show(buffer, warsaw)
@test Compat.String(take!(buffer)) == "Europe/Warsaw (UTC+1/UTC+2)"
show(buffer, apia)
@test Compat.String(take!(buffer)) == "Pacific/Apia (UTC+13/UTC+14)"
show(buffer, honolulu)
@test Compat.String(take!(buffer)) == "Pacific/Honolulu (UTC-10)"
show(buffer, ulyanovsk)
@test Compat.String(take!(buffer)) == "Europe/Ulyanovsk (UTC+4)"

# UTC and GMT are special cases
show(buffer, FixedTimeZone("UTC"))
@test Compat.String(take!(buffer)) == "UTC"
show(buffer, FixedTimeZone("GMT", 0))
@test Compat.String(take!(buffer)) == "GMT"
show(buffer, FixedTimeZone("FOO", 0))
@test Compat.String(take!(buffer)) == "FOO (UTC+0)"

# ZonedDateTime as a string
zdt = ZonedDateTime(dt, warsaw)
@test string(zdt) == "1942-12-25T01:23:45+01:00"

show(buffer, zdt)
@test Compat.String(take!(buffer)) == "1942-12-25T01:23:45+01:00"


# TimeZone parsing

# Make sure that TimeZone conversion specifiers are set (issue #24)
CONVERSION_SPECIFIERS = isdefined(Base.Dates, :SLOT_RULE) ? Dates.keys(Dates.SLOT_RULE) : keys(Dates.CONVERSION_SPECIFIERS)
@test 'z' in CONVERSION_SPECIFIERS
@test 'Z' in CONVERSION_SPECIFIERS

df = Dates.DateFormat("z")
@test parse_components("+0100", df) == Any[FixedTimeZone("+01:00")]
@test_throws ArgumentError parse_components("EST", df)
@test_throws ArgumentError parse_components("UTC", df)
@test_throws ArgumentError parse_components("Europe/Warsaw", df)

df = Dates.DateFormat("Z")
@test_throws ArgumentError parse_components("+0100", df)
@test_throws ArgumentError parse_components("EST", df)
@test parse_components("UTC", df) == Any[FixedTimeZone("UTC")]
@test parse_components("Europe/Warsaw", df) == Any[warsaw]

# ZonedDateTime parsing.
# Note: uses compiled time zone information. If these tests are failing try to rebuild
# the TimeZones package.
@test ZonedDateTime("1942-12-25T01:23:45.000+01:00") == ZonedDateTime(dt, fixed)
@test ZonedDateTime("1942-12-25T01:23:45+0100", "yyyy-mm-ddTHH:MM:SSzzz") == ZonedDateTime(dt, fixed)
@test ZonedDateTime("1942-12-25T01:23:45 Europe/Warsaw", "yyyy-mm-ddTHH:MM:SS ZZZ") == ZonedDateTime(dt, warsaw)
@test ZonedDateTime("1942-12-25T01:23:45 America/New_York", "yyyy-mm-ddTHH:MM:SS ZZZ") == ZonedDateTime(dt, new_york)

x = "1942-12-25T01:23:45.123+01:00"
@test string(ZonedDateTime(x)) == x

# Note: CET here represents the FixedTimeZone used in Europe/Warsaw and not the
# VariableTimeZone CET.
@test_throws ArgumentError ZonedDateTime("1942-12-25T01:23:45 CET", "yyyy-mm-ddTHH:MM:SS ZZZ")

# Creating a ZonedDateTime requires a TimeZone to be present.
@test_throws ArgumentError ZonedDateTime("1942-12-25T01:23:45", "yyyy-mm-ddTHH:MM:SSzzz")


# ZonedDateTime formatting
f = "yyyy/m/d H:M:S ZZZ"
@test Dates.format(ZonedDateTime(dt, fixed), f) == "1942/12/25 1:23:45 UTC+01:00"
@test Dates.format(ZonedDateTime(dt, warsaw), f) == "1942/12/25 1:23:45 CET"
@test Dates.format(ZonedDateTime(dt, ulyanovsk), f) == "1942/12/25 1:23:45 UTC+04:00"

f = "yyyy/m/d H:M:S zzz"
@test Dates.format(ZonedDateTime(dt, fixed), f) == "1942/12/25 1:23:45 +01:00"
@test Dates.format(ZonedDateTime(dt, warsaw), f) == "1942/12/25 1:23:45 +01:00"
@test Dates.format(ZonedDateTime(dt, ulyanovsk), f) == "1942/12/25 1:23:45 +04:00"


# The "Z" slot displays the time zone abbreviation for VariableTimeZones. It is fine to use
# the abbreviation for display purposes but not fine for parsing. This means that we
# currently cannot parse all strings produced by format.
df = Dates.DateFormat("yyyy-mm-ddTHH:MM:SS ZZZ")
zdt = ZonedDateTime(dt, warsaw)
@test_throws ArgumentError parse(ZonedDateTime, Dates.format(zdt, df), df)
