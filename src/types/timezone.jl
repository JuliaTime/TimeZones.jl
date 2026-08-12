"""
    TimeZone(str::AbstractString) -> TimeZone

Constructs a `TimeZone` subtype based upon the string. If the string is a recognized
standard time zone name then data is loaded from the compiled IANA time zone database.
Otherwise the string is parsed as a fixed time zone.

A list of recognized standard and legacy time zones names can is available by running
`timezone_names()`. Supported fixed time zone string formats can be found in docstring for
[`FixedTimeZone(::AbstractString)`](@ref).

## Examples
```jldoctest
julia> TimeZone("Europe/Warsaw")
Europe/Warsaw (UTC+1/UTC+2)

julia> TimeZone("UTC")
UTC
```
"""
TimeZone(::AbstractString)

"""
    TimeZone(str::AbstractString, mask::Class) -> TimeZone

Similar to [`TimeZone(::AbstractString)`](@ref) but allows you to control what time zone
classes are allowed to be constructed with `mask`. Can be used to construct time zones
which are classified as "legacy".

## Examples
```jldoctest
julia> TimeZone("US/Pacific")
ERROR: ArgumentError: The time zone "US/Pacific" is of class `TimeZones.Class(:LEGACY)` which is currently not allowed by the mask: `TimeZones.Class(:FIXED) | TimeZones.Class(:STANDARD)`

julia> TimeZone("US/Pacific", TimeZones.Class(:LEGACY))
US/Pacific (UTC-8/UTC-7)
```
"""
TimeZone(::AbstractString, ::Class)

function TimeZone(str::AbstractString, mask::Class=Class(:DEFAULT))
    tz, class, link = get(_TZ_CACHE, str) do
        if occursin(FIXED_TIME_ZONE_REGEX, str)
            FixedTimeZone(str), Class(:FIXED), InlineString31("")
        else
            throw(ArgumentError("Unknown time zone \"$str\""))
        end
    end

    # Auto-redirect LEGACY timezones to their modern equivalents
    # Only when user hasn't explicitly opted in to LEGACY class
    if !isempty(link) && class == Class(:LEGACY) && mask & Class(:LEGACY) == Class(:NONE)
        # Note: Using depwarn here allows users to control behavior via --depwarn flag.
        # With --depwarn=error, this becomes an error (strict mode).
        # This matches the behavior requested in issue #469 https://github.com/JuliaTime/TimeZones.jl/issues/469#issuecomment-2341741754.
        Base.depwarn(
            "The time zone \"$str\" is deprecated, using \"$link\" instead.",
            :TimeZone
        )
        return TimeZone(String(link), mask)
    end

    if mask & class == Class(:NONE)
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
    istimezone(str::AbstractString, mask::Class=Class(:DEFAULT)) -> Bool

Check whether a string is a valid for constructing a `TimeZone` with the provided `mask`.
"""
function istimezone(str::AbstractString, mask::Class=Class(:DEFAULT))
    # Start by performing quick FIXED class test
    if mask & Class(:FIXED) != Class(:NONE) && occursin(FIXED_TIME_ZONE_REGEX, str)
        return true
    end

    # Checks against pre-compiled time zones (3-tuple now: tz, class, link)
    _, class, link = get(() -> (UTC_ZERO, Class(:NONE), InlineString31("")), _TZ_CACHE, str)

    # Allow linked legacy timezones to auto-redirect
    !isempty(link) && class == Class(:LEGACY) && mask & Class(:LEGACY) == Class(:NONE) && return true
    return mask & class != Class(:NONE)
end
