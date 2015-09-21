# Convenience type for working with HH:MM:SS.
immutable Time <: TimePeriod
    seconds::Int
end
const ZERO = Time(0)

function Time(hour::Int, minute::Int, second::Int)
    Time(hour * 3600 + minute * 60 + second)
end

function Time(s::AbstractString)
    # "-" represents 0:00 for some DST rules
    s == "-" && return ZERO
    parsed = map(n -> parse(Int, n), split(s, ':'))

    # Only can handle up to hour, minute, second.
    length(parsed) > 3 && error("Invalid Time string")
    any(parsed[2:end] .< 0) && error("Invalid Time string")

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
Base.Dates.value(t::Time) = t.seconds
Base.Dates.toms(t::Time) = t.seconds * 1000

toseconds(t::Time) = t.seconds
hour(t::Time) = div(toseconds(t), 3600)
minute(t::Time) = rem(div(toseconds(t), 60), 60)
second(t::Time) = rem(toseconds(t), 60)

function hourminutesecond(t::Time)
    h, r = divrem(toseconds(t), 3600)
    m, s = divrem(r, 60)
    return h, m, s
end

Base.convert(::Type{Second}, t::Time) = Second(toseconds(t))
Base.convert(::Type{Millisecond}, t::Time) = Millisecond(toseconds(t) * 1000)
Base.promote_rule{P<:Union{Week,Day,Hour,Minute,Second}}(::Type{P}, ::Type{Time}) = Second
Base.promote_rule(::Type{Millisecond}, ::Type{Time}) = Millisecond

# Should be defined in Base.Dates
Base.isless(x::Period, y::Period) = isless(promote(x,y)...)

# https://en.wikipedia.org/wiki/ISO_8601#Times
function Base.string(t::Time)
    neg = toseconds(t) < 0 ? "-" : ""
    h, m, s = map(abs, hourminutesecond(t))
    @sprintf("%s%02d:%02d:%02d", neg, h, m, s)
end

Base.show(io::IO, t::Time) = print(io, string(t))


# min/max offsets across all zones and all time.
const MIN_GMT_OFFSET = Time("-15:56:00")  # Asia/Manilla
const MAX_GMT_OFFSET = Time("15:13:42")   # America/Metlakatla

# min/max save across all zones/rules and all time.
const MIN_SAVE = Time("00:00")
const MAX_SAVE = Time("02:00")  # France, Germany, Port, Spain

const MIN_OFFSET = MIN_GMT_OFFSET + MIN_SAVE
const MAX_OFFSET = MAX_GMT_OFFSET + MAX_SAVE
const ABS_DIFF_OFFSET = abs(MAX_OFFSET - MIN_OFFSET)
