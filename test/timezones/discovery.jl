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

abbrs = timezone_abbrs()
@test length(abbrs) >= 336
@test isa(abbrs, Array{AbstractString})
@test issorted(abbrs)
