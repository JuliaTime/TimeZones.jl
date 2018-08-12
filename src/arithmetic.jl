import Base: +, -
import Compat: @static

if VERSION < v"0.7.0-DEV.4955"
    import Base: broadcast
    const broadcasted = broadcast
else
    import Base.Broadcast: broadcasted
end

# Localized arithmetic
(+)(x::Localized) = x
(-)(x::Localized, y::Localized) = x.utc_datetime - y.utc_datetime

function (+)(ldt::Localized, p::DatePeriod)
    return Localized(localtime(ldt) + p, timezone(ldt))
end
function (+)(ldt::Localized, p::TimePeriod)
    return Localized(ldt.utc_datetime + p, timezone(ldt); from_utc=true)
end
function (-)(ldt::Localized, p::DatePeriod)
    return Localized(localtime(ldt) - p, timezone(ldt))
end
function (-)(ldt::Localized, p::TimePeriod)
    return Localized(ldt.utc_datetime - p, timezone(ldt); from_utc=true)
end

function broadcasted(::typeof(+), r::StepRange{<:Localized}, p::DatePeriod)
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

broadcasted(::typeof(-), r::StepRange{Localized}, p::DatePeriod) = broadcast(+, r, -p)
