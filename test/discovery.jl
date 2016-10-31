import TimeZones: timezone_names

names = timezone_names()
@test length(names) >= 436
@test isa(names, Array{AbstractString})
@test issorted(names)

# Make sure that extra time zones exist from "deps/tzdata/utc".
# If tests fail try rebuilding the package: Pkg.build("TimeZones")
@test "UTC" in names
@test "GMT" in names

timezones = all_timezones()
@test length(timezones) == length(names)
@test isa(timezones, Array{TimeZone})

timezones = timezones_from_abbr("EET")
@test length(timezones) >= 29
@test isa(timezones, Array{TimeZone})

# Note: Unlike time zone names it is possible, although unlikely, for the number of
# abbreviations to decrease over time.
# Note: Release 2016g and 2016h switched to using numeric time zone abbreviations instead of
# using invented or obsolete alphanumeric time zone abbreviations.
abbrs = timezone_abbrs()
@test length(abbrs) >= 267  # Updated for release: 2016h
@test isa(abbrs, Array{AbstractString})
@test issorted(abbrs)
