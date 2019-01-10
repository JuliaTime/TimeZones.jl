const TIME_ZONES = Dict{String,TimeZone}()

"""
    TimeZone(str::AbstractString) -> TimeZone

Constructs a `TimeZone` subtype based upon the string. If the string is a recognized time
zone name then data is loaded from the compiled IANA time zone database. Otherwise the
string is assumed to be a static time zone.

A list of recognized time zones names is available from `timezone_names()`. Supported static
time zone string formats can be found in `FixedTimeZone(::AbstractString)`.
"""
function TimeZone(str::AbstractString)
    return get!(TIME_ZONES, str) do
        if occursin(FIXED_TIME_ZONE_REGEX, str)
            return FixedTimeZone(str)
        end

        tz_path = joinpath(TZData.COMPILED_DIR, split(str, "/")...)
        isfile(tz_path) || throw(ArgumentError("Unknown time zone \"$str\""))

        open(tz_path, "r") do fp
            return deserialize(fp)
        end
    end
end

"""
    @tz_str -> TimeZone

Constructs a `TimeZone` subtype based upon the string at parse time. See docstring of
`TimeZone` for more details.

```julia
julia> tz"Africa/Nairobi"
Africa/Nairobi (UTC+3)
```
"""
macro tz_str(str)
    TimeZone(str)
end

"""
    istimezone(str::AbstractString) -> Bool

Tests whether a string is a valid name for constructing a `TimeZone`.
"""
function istimezone(str::AbstractString)
    return (
        haskey(TIME_ZONES, str) ||
        occursin(FIXED_TIME_ZONE_REGEX, str) ||
        isfile(joinpath(TZData.COMPILED_DIR, split(str, "/")...))
    )
end
