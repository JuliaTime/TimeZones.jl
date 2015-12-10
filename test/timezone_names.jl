import TimeZones: timezone_names

names = timezone_names()

@test length(names) >= 429
@test isa(names, Array{UTF8String})
@test issorted(names)

# Make sure that extra timezones exist from "deps/tzdata/utc".
# If tests fail try rebuilding the package: Pkg.build("TimeZones")
@test "UTC" in names
@test "GMT" in names
