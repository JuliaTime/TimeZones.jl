using Dates: Dates, TimePeriod, Week, Day, Hour, Minute, Second, Millisecond, value

# Convenience type for working with HH:MM:SS durations which can be negative or exceed
# 24-hours.
struct TimeOffset <: TimePeriod
    seconds::Int
end
const ZERO = TimeOffset(0)

function TimeOffset(hour::Integer, minute::Integer, second::Integer)
    TimeOffset(hour * 3600 + minute * 60 + second)
end

TimeOffset(str::AbstractString) = parse(TimeOffset, str)

function Base.parse(::Type{TimeOffset}, s::AbstractString)
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
Dates.value(t::TimeOffset) = t.seconds
Dates.toms(t::TimeOffset) = value(t) * 1000

Dates.hour(t::TimeOffset) = div(value(t), 3600)
Dates.minute(t::TimeOffset) = rem(div(value(t), 60), 60)
Dates.second(t::TimeOffset) = rem(value(t), 60)

function hourminutesecond(t::TimeOffset)
    h, r = divrem(value(t), 3600)
    m, s = divrem(r, 60)
    return h, m, s
end

Base.convert(::Type{Second}, t::TimeOffset) = Second(value(t))
Base.convert(::Type{Millisecond}, t::TimeOffset) = Millisecond(value(t) * 1000)
Base.promote_rule(::Type{<:Union{Week,Day,Hour,Minute,Second}}, ::Type{TimeOffset}) = Second
Base.promote_rule(::Type{Millisecond}, ::Type{TimeOffset}) = Millisecond

# https://en.wikipedia.org/wiki/ISO_8601#Times
function Base.string(t::TimeOffset)
    neg = value(t) < 0 ? "-" : ""
    h, m, s = map(abs, hourminutesecond(t))
    @sprintf("%s%02d:%02d:%02d", neg, h, m, s)
end
Base.print(io::IO, t::TimeOffset) = print(io, string(t))
Base.show(io::IO, t::TimeOffset) = print(io, t)


# min/max offsets across all zones and all time.
# Note: A warning is given when we find an Olson zone that exceeds these values.
const MIN_GMT_OFFSET = TimeOffset("-15:56:08")  # Asia/Manilla as of 2025a
const MAX_GMT_OFFSET = TimeOffset("15:13:42")   # America/Metlakatla

# min/max save across all zones/rules and all time.
# Note: A warning is given when we find an Olson rule that exceeds these values.
const MIN_SAVE = TimeOffset("-01:00") # Eire (rule in 2018a)
const MAX_SAVE = TimeOffset("02:00")  # France, Germany, Port, Spain

const MIN_OFFSET = MIN_GMT_OFFSET + MIN_SAVE
const MAX_OFFSET = MAX_GMT_OFFSET + MAX_SAVE
const ABS_DIFF_OFFSET = abs(MAX_OFFSET - MIN_OFFSET)
