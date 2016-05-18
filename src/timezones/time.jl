import Base: convert, promote_rule, string, print, show
import Base.Dates: value, toms

# Convenience type for working with HH:MM:SS.
immutable Time <: TimePeriod
    seconds::Int
end
const ZERO = Time(0)

function Time(hour::Integer, minute::Integer, second::Integer)
    Time(hour * 3600 + minute * 60 + second)
end

function Time(s::AbstractString)
    # "-" represents 0:00 for some DST rules
    s == "-" && return ZERO
    parsed = map(n -> parse(Int, n), split(s, ':'))

    # Only can handle up to hour, minute, second.
    length(parsed) > 3 && throw(ArgumentError("Invalid Time string"))
    any(parsed[2:end] .< 0) && throw(ArgumentError("Invalid Time string"))

    # Handle variations where minutes and seconds may be excluded.
    values = [0,0,0]
    values[1:length(parsed)] = parsed

    if values[1] < 0
        for i in 2:length(values)
            values[i] = -values[i]
        end
    end

    return Time(values...)
end

# TimePeriod methods
value(t::Time) = t.seconds
toms(t::Time) = value(t) * 1000

hour(t::Time) = div(value(t), 3600)
minute(t::Time) = rem(div(value(t), 60), 60)
second(t::Time) = rem(value(t), 60)

function hourminutesecond(t::Time)
    h, r = divrem(value(t), 3600)
    m, s = divrem(r, 60)
    return h, m, s
end

convert(::Type{Second}, t::Time) = Second(value(t))
convert(::Type{Millisecond}, t::Time) = Millisecond(value(t) * 1000)
promote_rule{P<:Union{Week,Day,Hour,Minute,Second}}(::Type{P}, ::Type{Time}) = Second
promote_rule(::Type{Millisecond}, ::Type{Time}) = Millisecond

# Should be defined in Base.Dates
Base.isless(x::Period, y::Period) = isless(promote(x,y)...)

# https://en.wikipedia.org/wiki/ISO_8601#Times
function string(t::Time)
    neg = value(t) < 0 ? "-" : ""
    h, m, s = map(abs, hourminutesecond(t))
    @sprintf("%s%02d:%02d:%02d", neg, h, m, s)
end
print(io::IO, t::Time) = print(io, string(t))
show(io::IO, t::Time) = print(io, t)


# min/max offsets across all zones and all time.
# Note: A warning is given when we find an Olson zone that exceeds these values.
const MIN_GMT_OFFSET = Time("-15:56:00")  # Asia/Manilla
const MAX_GMT_OFFSET = Time("15:13:42")   # America/Metlakatla

# min/max save across all zones/rules and all time.
# Note: A warning is given when we find an Olson rule that exceeds these values.
const MIN_SAVE = Time("00:00")
const MAX_SAVE = Time("02:00")  # France, Germany, Port, Spain

const MIN_OFFSET = MIN_GMT_OFFSET + MIN_SAVE
const MAX_OFFSET = MAX_GMT_OFFSET + MAX_SAVE
const ABS_DIFF_OFFSET = abs(MAX_OFFSET - MIN_OFFSET)
