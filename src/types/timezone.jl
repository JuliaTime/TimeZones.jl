const TIME_ZONE_NAMES = Dict{UInt8,Vector{String}}()
const TIME_ZONE_CACHE = Dict{String,Tuple{TimeZone,UInt8}}()

"""
    TimeZone(str::AbstractString, class_mask::UInt8=DEFAULT_MASK) -> TimeZone

Constructs a `TimeZone` subtype based upon the string and the provided `class_mask`. If the
string is a recognized time zone name then data is loaded from the compiled IANA time zone
database. Otherwise the string is assumed to be a fixed time zone.

A list of recognized time zones names is available from `timezone_names()`. Supported fixed
time zone string formats can be found in docstring for: `FixedTimeZone(::AbstractString)`.
"""
function TimeZone(str::AbstractString, class_mask::UInt8=DEFAULT_MASK)
    # Note: If the `class_mask` does not match the time zone we'll still load the
    # information into the cache to ensure the result is consistent.
    tz, class = get!(TIME_ZONE_CACHE, str) do
        class = _timezone_class(str)

        tz = if class == FIXED
            FixedTimeZone(str)
        elseif class == STANDARD || class == LEGACY
            tz_path = joinpath(TZData.COMPILED_DIR, split(str, '/')...)
            open(deserialize, tz_path, "r")
        else
            throw(ArgumentError("Unknown time zone \"$str\""))
        end

        tz, class
    end

    if iszero(class_mask & class)
        throw(ArgumentError(
            "The time zone \"$str\" is of class `$class` which is " *
            "currently not allowed by the mask: `$class_mask`"
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
    istimezone(str::AbstractString, class_mask::UInt8=DEFAULT_MASK) -> Bool

Check whether a string is a valid for constructing a `TimeZone` with the provided
`class_mask`.
"""
function istimezone(str::AbstractString, class_mask::UInt8=DEFAULT_MASK)
    # Note: Similar to `_timezone_class` but avoids computation with a limited `class_mask`
    return (
        !iszero(class_mask & STANDARD) && str in TIME_ZONE_NAMES[STANDARD] ||
        !iszero(class_mask & LEGACY) && str in TIME_ZONE_NAMES[LEGACY] ||
        !iszero(class_mask & FIXED) && occursin(FIXED_TIME_ZONE_REGEX, str)
    )
end
