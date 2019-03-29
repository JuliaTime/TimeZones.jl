using Dates: AbstractTime, Second, value

# Note: The IANA time zone database rounds offset precision to the nearest second
# See "America/New_York" notes in tzdata file "northamerica" for an example.
"""
    UTCOffset

A `UTCOffset` is an amount of time subtracted from or added to UTC to get the current
local time – whether it's standard time or daylight saving time.
"""
struct UTCOffset <: AbstractTime
    std::Second  # Standard time offset from UTC in seconds
    dst::Second  # Daylight saving time offset in seconds

    function UTCOffset(std_offset::Second, dst_offset::Second=Second(0))
        new(std_offset, dst_offset)
    end
end

function UTCOffset(std_offset::Integer, dst_offset::Integer=0)
    UTCOffset(Second(std_offset), Second(dst_offset))
end

Dates.value(offset::UTCOffset) = value(offset.std + offset.dst)

Base.:(+)(dt::DateTime, offset::UTCOffset) = dt + (offset.std + offset.dst)
Base.:(-)(dt::DateTime, offset::UTCOffset) = dt - (offset.std + offset.dst)
Base.:(-)(a::UTCOffset, b::UTCOffset) = UTCOffset(a.std - b.std, a.dst - b.dst)

# Determines if the given `UTCOffset` is an offset for daylight saving time.
isdst(offset::UTCOffset) = offset.dst != Second(0)

# Two `UTCOffset`s can be considered equal if the total offset is the same and they are
# both either offsets for standard time or daylight saving time.
function Base.isequal(x::UTCOffset, y::UTCOffset)
    x == y || value(x) == value(y) && isdst(x) == isdst(y)
end
Base.isless(x::UTCOffset, y::UTCOffset) = isless(value(x), value(y))

function offset_string(seconds::Second, iso8601::Bool=false)
    val = value(seconds)
    sig = val < 0 ? '-' : '+'
    hour, val = divrem(abs(val), 3600)
    minute, second  = divrem(val, 60)

    if !iso8601 && minute == 0 && second == 0
        return @sprintf("%c%01d", sig, hour)
    elseif second == 0
        return @sprintf("%c%02d:%02d", sig, hour, minute)
    else
        # Not in the ISO 8601 standard
        return @sprintf("%c%02d:%02d:%02d", sig, hour, minute, second)
    end
end
function offset_string(offset::UTCOffset, iso8601::Bool=false)
    offset_string(offset.std + offset.dst, iso8601)
end

Base.print(io::IO, o::UTCOffset) = print(io, offset_string(o, true))

function Base.show(io::IO, o::UTCOffset)
    if get(io, :compact, false)
        # Show DST as a separate offset since we want to distinguish between normal hourly
        # daylight saving time offsets and exotic DST offsets (e.g. midsummer time).
        print(io, "UTC", offset_string(o.std), "/", offset_string(o.dst))
    else
        # Fallback to calling the default show instead of reimplementing it.
        invoke(show, Tuple{IO, Any}, io, o)
    end
end

function Base.show(io::IO, ::MIME"text/plain", o::UTCOffset)
    show(IOContext(io, :compact => true), o)
end
