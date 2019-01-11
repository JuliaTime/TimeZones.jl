const TIME_ZONE_CACHE = Dict{String,Tuple{TimeZone,Class}}()

"""
    TimeZone(str::AbstractString, mask::Class=Class.DEFAULT) -> TimeZone

Constructs a `TimeZone` subtype based upon the string and the provided `mask`. If the
string is a recognized time zone name then data is loaded from the compiled IANA time zone
database. Otherwise the string is assumed to be a fixed time zone.

A list of recognized time zones names is available from `timezone_names()`. Supported fixed
time zone string formats can be found in docstring for: `FixedTimeZone(::AbstractString)`.
"""
function TimeZone(str::AbstractString, mask::Class=Class.DEFAULT)
    # Note: If the class `mask` does not match the time zone we'll still load the
    # information into the cache to ensure the result is consistent.
    tz, class = get!(TIME_ZONE_CACHE, str) do
        tz_path = joinpath(TZData.COMPILED_DIR, split(str, "/")...)

        if isfile(tz_path)
            open(deserialize, tz_path, "r")
        elseif occursin(FIXED_TIME_ZONE_REGEX, str)
            FixedTimeZone(str), Class.FIXED
        else
            throw(ArgumentError("Unknown time zone \"$str\""))
        end
    end

    if mask & class == Class.NONE
        throw(ArgumentError(
            "The time zone \"$str\" is of class `$(repr(class))` which is " *
            "currently not allowed by the mask: `$(repr(mask))`"
        ))
    end

    return tz
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
    istimezone(str::AbstractString, mask::Class=Class.DEFAULT) -> Bool

Check whether a string is a valid for constructing a `TimeZone` with the provided `mask`.
"""
function istimezone(str::AbstractString, mask::Class=Class.DEFAULT)
    return (
        haskey(TIME_ZONE_CACHE, str) ||
        mask & Class.FIXED != Class.NONE && occursin(FIXED_TIME_ZONE_REGEX, str) ||
        isfile(joinpath(TZData.COMPILED_DIR, split(str, "/")...))
    )
end
