import Base.Dates: trunc, DatePeriod, TimePeriod
import Base.Dates: firstdayofweek, lastdayofweek, firstdayofmonth, lastdayofmonth,
    firstdayofyear, lastdayofyear, firstdayofquarter, lastdayofquarter


# Truncation
function trunc{P<:DatePeriod}(zdt::ZonedDateTime, ::Type{P})
    ZonedDateTime(trunc(localtime(zdt), P), timezone(zdt))
end
function trunc{P<:TimePeriod}(zdt::ZonedDateTime, ::Type{P})
    ZonedDateTime(trunc(utc(zdt), P), timezone(zdt), from_utc=true)
end
trunc(zdt::ZonedDateTime, ::Type{Millisecond}) = zdt

# Adjusters
for prefix in ("firstdayof", "lastdayof"), suffix in ("week", "month", "year", "quarter")
    func = Symbol(prefix * suffix)
    @eval begin
        $func(dt::ZonedDateTime) = ZonedDateTime($func(localtime(dt)), dt.timezone)
    end
end

"""
    closest(dt::DateTime, tz::TimeZone, step::Period)

Always construct a valid `ZonedDateTime` by adjusting local datetime `dt` by the given
`step` when `dt` lands on a non-existent or ambiguous hour. Currently only meant for
internal use.
"""
function closest(dt::DateTime, tz::TimeZone, step::Period)
    return ZonedDateTime(dt, tz)
end

function closest(dt::DateTime, tz::VariableTimeZone, step::Period)
    possible = interpret(dt, tz, Local)

    # Skip all non-existent local datetimes.
    while isempty(possible)
        dt -= step
        possible = interpret(dt, tz, Local)
    end

    # Is step positive?
    return step == abs(step) ? last(possible) : first(possible)
end


