import Base: +, -, isequal, convert, string, show
import Base.Dates: AbstractTime, Second, value

# Note: The Olson Database rounds offset precision to the nearest second
# See "America/New_York" notes in Olson file "northamerica" for an example.
"""
    UTCOffset

A `UTCOffset` is an amount of time subtracted from or added to UTC to get the current
local time – whether it's standard time or daylight saving time.
"""
immutable UTCOffset <: AbstractTime
    std::Second  # Standard offset from UTC in seconds
    dst::Second  # Addition daylight saving time offset applied to UTC offset in seconds

    function UTCOffset(std_offset::Second, dst_offset::Second=Second(0))
        new(std_offset, dst_offset)
    end
end

function UTCOffset(std_offset::Integer, dst_offset::Integer=0)
    UTCOffset(Second(std_offset), Second(dst_offset))
end

value(offset::UTCOffset) = value(offset.std + offset.dst)

(+)(dt::DateTime, offset::UTCOffset) = dt + (offset.std + offset.dst)
(-)(dt::DateTime, offset::UTCOffset) = dt - (offset.std + offset.dst)

# Determines if the given `UTCOffset` is an offset for daylight saving time.
isdst(offset::UTCOffset) = offset.dst != Second(0)

# Two `UTCOffset`s can be considered equal if the total offset is the same and they are
# both either offsets for standard time or daylight saving time.
function isequal(x::UTCOffset, y::UTCOffset)
    x == y || value(x) == value(y) && isdst(x) == isdst(y)
end

function convert{S<:AbstractString}(::Type{S}, offset::UTCOffset)
    v = value(offset)
    h, v = divrem(v, 3600)
    m, s  = divrem(abs(v), 60)

    if s == 0
        return @sprintf("%+03d:%02d", h, m)
    else
        return @sprintf("%+03d:%02d:%02d", h, m, s)
    end
end
string(offset::UTCOffset) = convert(AbstractString, offset)

function format_offset(seconds::Second)
    v = value(seconds)
    h, v = divrem(v, 3600)
    m, s  = divrem(abs(v), 60)

    if m == 0 && s == 0
        return @sprintf("%+03d", h)
    elseif s == 0
        return @sprintf("%+03d:%02d", h, m)
    else
        return @sprintf("%+03d:%02d:%02d", h, m, s)
    end
end

function show(io::IO, o::UTCOffset)
    # Show DST as an offset since we want to distinguish between normal daylight saving
    # time offsets and midsummer time offsets.
    print(io, "UTC", format_offset(o.std), "/", format_offset(o.dst))
end
