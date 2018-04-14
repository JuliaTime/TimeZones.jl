using TimeZones.TZData: parse_components

null = FixedTimeZone("", 10800)
fixed = FixedTimeZone("UTC+01:00")
est = FixedTimeZone("EST", -18000)
warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)
apia = resolve("Pacific/Apia", tzdata["australasia"]...)
honolulu = resolve("Pacific/Honolulu", tzdata["northamerica"]...)  # Uses cutoff
ulyanovsk = resolve("Europe/Ulyanovsk", tzdata["europe"]...)  # No named abbreviations
new_york = resolve("America/New_York", tzdata["northamerica"]...)  # Underscore in name
dt = DateTime(1942,12,25,1,23,45)

# TimeZones as a string
@test string(null) == "UTC+03:00"
@test string(fixed) == "UTC+01:00"
@test string(est) == "EST"
@test string(warsaw) == "Europe/Warsaw"
@test string(apia) == "Pacific/Apia"
@test string(honolulu) == "Pacific/Honolulu"
@test string(ulyanovsk) == "Europe/Ulyanovsk"

# Alternatively in Julia 0.7.0-DEV.4517 we could use
# `sprint(show, ..., context=:compact => true)`
show_compact = (io, args...) -> show(IOContext(io, :compact => true), args...)
@test sprint(show_compact, null) == "UTC+03:00"
@test sprint(show_compact, fixed) == "UTC+01:00"
@test sprint(show_compact, est) == "EST"
@test sprint(show_compact, warsaw) == "Europe/Warsaw"
@test sprint(show_compact, apia) == "Pacific/Apia"
@test sprint(show_compact, honolulu) == "Pacific/Honolulu"
@test sprint(show_compact, ulyanovsk) == "Europe/Ulyanovsk"

@test sprint(show, null) == "UTC+03:00"
@test sprint(show, fixed) == "UTC+01:00"
@test sprint(show, est) == "EST (UTC-5)"
@test sprint(show, warsaw) == "Europe/Warsaw (UTC+1/UTC+2)"
@test sprint(show, apia) == "Pacific/Apia (UTC+13/UTC+14)"
@test sprint(show, honolulu) == "Pacific/Honolulu (UTC-10)"
@test sprint(show, ulyanovsk) == "Europe/Ulyanovsk (UTC+4)"

# UTC and GMT are special cases
@test sprint(show, FixedTimeZone("UTC")) == "UTC"
@test sprint(show, FixedTimeZone("GMT", 0)) == "GMT"
@test sprint(show, FixedTimeZone("FOO", 0)) == "FOO (UTC+0)"

# ZonedDateTime as a string
zdt = ZonedDateTime(dt, warsaw)
@test string(zdt) == "1942-12-25T01:23:45+01:00"
@test sprint(show, zdt) == "1942-12-25T01:23:45+01:00"


# TimeZone parsing

# Make sure that TimeZone conversion specifiers are set (issue #24)
CONVERSION_SPECIFIERS = isdefined(Dates, :SLOT_RULE) ? Dates.keys(Dates.SLOT_RULE) : keys(Dates.CONVERSION_SPECIFIERS)
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
