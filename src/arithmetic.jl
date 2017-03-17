import Base: +, -, .+, .-, broadcast
import Compat: @static

# ZonedDateTime arithmetic
(+)(x::ZonedDateTime) = x
(-)(x::ZonedDateTime, y::ZonedDateTime) = x.utc_datetime - y.utc_datetime

function (+)(zdt::ZonedDateTime, p::DatePeriod)
    return ZonedDateTime(localtime(zdt) + p, timezone(zdt))
end
function (+)(zdt::ZonedDateTime, p::TimePeriod)
    return ZonedDateTime(zdt.utc_datetime + p, timezone(zdt); from_utc=true)
end
function (-)(zdt::ZonedDateTime, p::DatePeriod)
    return ZonedDateTime(localtime(zdt) - p, timezone(zdt))
end
function (-)(zdt::ZonedDateTime, p::TimePeriod)
    return ZonedDateTime(zdt.utc_datetime - p, timezone(zdt); from_utc=true)
end

function _dot_add(r::StepRange{ZonedDateTime}, p::DatePeriod)
    start, step, stop = first(r), Base.step(r), last(r)

    # Since the localtime + period can result in an invalid local datetime when working with
    # VariableTimeZones we will use `first_valid` and `last_valid` which avoids issues with
    # non-existent and ambiguous dates.

    tz = timezone(start)
    if isa(tz, VariableTimeZone)
        start = first_valid(localtime(start) + p, tz, step)
    else
        start = start + p
    end

    tz = timezone(stop)
    if isa(tz, VariableTimeZone)
        stop = last_valid(localtime(stop) + p, tz, step)
    else
        stop = stop + p
    end

    return StepRange(start, step, stop)
end

# static needed to stop 0.6 from complaining about `.+` and `.-` definitions
@static if VERSION < v"0.6-"
    (.+)(r::StepRange{ZonedDateTime}, p::DatePeriod) = _dot_add(r, p)
    (.-)(r::StepRange{ZonedDateTime}, p::DatePeriod) = _dot_add(r, -p)
else
    broadcast(::typeof(+), r::StepRange{ZonedDateTime}, p::DatePeriod) = _dot_add(r, p)
    broadcast(::typeof(-), r::StepRange{ZonedDateTime}, p::DatePeriod) = _dot_add(r, -p)
end
