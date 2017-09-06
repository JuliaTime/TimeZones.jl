import Base: convert, promote_rule, string, print, show
import Base.Dates: Period, TimePeriod, Week, Day, Hour, Minute, Second, Millisecond,
    value, toms, hour, minute, second

# Convenience type for working with HH:MM:SS.
struct TimeOffset <: TimePeriod
    seconds::Int
end
const ZERO = TimeOffset(0)

function TimeOffset(hour::Integer, minute::Integer, second::Integer)
    TimeOffset(hour * 3600 + minute * 60 + second)
end

function TimeOffset(s::AbstractString)
    # "-" represents 0:00 for some DST rules
    s == "-" && return ZERO
    parsed = map(n -> parse(Int, n), split(s, ':'))

    # Only can handle up to hour, minute, second.
    length(parsed) > 3 && throw(ArgumentError("Invalid TimeOffset string"))
    any(parsed[2:end] .< 0) && throw(ArgumentError("Invalid TimeOffset string"))

    # Handle variations where minutes and seconds may be excluded.
    values = [0,0,0]
    values[1:length(parsed)] = parsed

    if values[1] < 0
        for i in 2:length(values)
            values[i] = -values[i]
        end
    end

    return TimeOffset(values...)
end

# TimePeriod methods
value(t::TimeOffset) = t.seconds
toms(t::TimeOffset) = value(t) * 1000

hour(t::TimeOffset) = div(value(t), 3600)
minute(t::TimeOffset) = rem(div(value(t), 60), 60)
second(t::TimeOffset) = rem(value(t), 60)

function hourminutesecond(t::TimeOffset)
    h, r = divrem(value(t), 3600)
    m, s = divrem(r, 60)
    return h, m, s
end

convert(::Type{Second}, t::TimeOffset) = Second(value(t))
convert(::Type{Millisecond}, t::TimeOffset) = Millisecond(value(t) * 1000)
promote_rule(::Type{<:Union{Week,Day,Hour,Minute,Second}}, ::Type{TimeOffset}) = Second
promote_rule(::Type{Millisecond}, ::Type{TimeOffset}) = Millisecond

# https://en.wikipedia.org/wiki/ISO_8601#Times
function string(t::TimeOffset)
    neg = value(t) < 0 ? "-" : ""
    h, m, s = map(abs, hourminutesecond(t))
    @sprintf("%s%02d:%02d:%02d", neg, h, m, s)
end
print(io::IO, t::TimeOffset) = print(io, string(t))
show(io::IO, t::TimeOffset) = print(io, t)


# min/max offsets across all zones and all time.
# Note: A warning is given when we find an Olson zone that exceeds these values.
const MIN_GMT_OFFSET = TimeOffset("-15:56:00")  # Asia/Manilla
const MAX_GMT_OFFSET = TimeOffset("15:13:42")   # America/Metlakatla

# min/max save across all zones/rules and all time.
# Note: A warning is given when we find an Olson rule that exceeds these values.
const MIN_SAVE = TimeOffset("00:00")
const MAX_SAVE = TimeOffset("02:00")  # France, Germany, Port, Spain

const MIN_OFFSET = MIN_GMT_OFFSET + MIN_SAVE
const MAX_OFFSET = MAX_GMT_OFFSET + MAX_SAVE
const ABS_DIFF_OFFSET = abs(MAX_OFFSET - MIN_OFFSET)
