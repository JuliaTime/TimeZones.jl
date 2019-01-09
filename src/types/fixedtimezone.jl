const FIXED_TIME_ZONE_REGEX = r"""
    ^(?|
        UTC
        (?:
            (?<sign>[+-])
            (?<hour>\d{1,2})
        )?
    |
        (?<sign>[+-])
        (?<hour>\d{2})
    |
        (?:UTC(?=[+-]))?
        (?<sign>[+-])?
        (?<hour>\d{2})
        (?|
            (?(hour)\:(?<minute>\d{2}))
            (?(minute)\:(?<second>\d{2}))?
        |
            (?(hour)(?<minute>\d{2}))
        )
    )$
    """x


"""
    FixedTimeZone

A `TimeZone` with a constant offset for all of time.
"""
struct FixedTimeZone <: TimeZone
    name::String
    offset::UTCOffset
end

"""
    FixedTimeZone(name, utc_offset, dst_offset=0) -> FixedTimeZone

Constructs a `FixedTimeZone` with the given `name`, UTC offset (in seconds), and DST offset
(in seconds).
"""
function FixedTimeZone(name::AbstractString, utc_offset::Integer, dst_offset::Integer=0)
    FixedTimeZone(name, UTCOffset(utc_offset, dst_offset))
end

function FixedTimeZone(name::AbstractString, utc_offset::Second, dst_offset::Second=Second(0))
    FixedTimeZone(name, UTCOffset(utc_offset, dst_offset))
end

"""
    FixedTimeZone(::AbstractString) -> FixedTimeZone

Constructs a `FixedTimeZone` with a UTC offset from a string. Resulting `FixedTimeZone` will
be named like \"UTC±HH:MM[:SS]\".

# Examples
```julia
julia> FixedTimeZone(\"UTC+6\")
UTC+06:00

julia> FixedTimeZone(\"-1330\")
UTC-13:30

julia> FixedTimeZone(\"15:45:21\")
UTC+15:45:21
```
"""
function FixedTimeZone(s::AbstractString)
    m = match(FIXED_TIME_ZONE_REGEX, s)
    m === nothing && throw(ArgumentError("Unrecognized time zone: $s"))

    coefficient = m[:sign] == "-" ? -1 : 1
    sig = coefficient < 0 ? '-' : '+'
    hour = m[:hour] === nothing ? 0 : parse(Int, m[:hour])
    minute = m[:minute] === nothing ? 0 : parse(Int, m[:minute])
    second = m[:second] === nothing ? 0 : parse(Int, m[:second])

    if hour == 0 && minute == 0 && second == 0
        name = "UTC"
    elseif second == 0
        name = @sprintf("UTC%c%02d:%02d", sig, hour, minute)
    else
        name = @sprintf("UTC%c%02d:%02d:%02d", sig, hour, minute, second)
    end

    offset = coefficient * (hour * 3600 + minute * 60 + second)
    return FixedTimeZone(name, offset)
end

name(tz::FixedTimeZone) = tz.name
rename(tz::FixedTimeZone, name::AbstractString) = FixedTimeZone(name, tz.offset)
