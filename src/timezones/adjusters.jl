import Base.Dates: Year, Month, Day, Hour, Minute, Second, Millisecond
import Base.Dates: firstdayofweek, lastdayofweek, firstdayofmonth, lastdayofmonth,
    firstdayofyear, lastdayofyear, firstdayofquarter, lastdayofquarter

# Truncation
function Base.trunc{P<:DatePeriod}(zdt::ZonedDateTime, ::Type{P})
    ZonedDateTime(trunc(localtime(zdt), P), timezone(zdt))
end
function Base.trunc{P<:TimePeriod}(zdt::ZonedDateTime, ::Type{P})
    ZonedDateTime(trunc(utc(zdt), P), timezone(zdt), from_utc=true)
end
Base.trunc(zdt::ZonedDateTime, ::Type{Millisecond}) = zdt

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
    possible = possible_dates(dt, tz)

    # Skip all non-existent local datetimes.
    while isempty(possible)
        dt -= step
        possible = possible_dates(dt, tz)
    end

    # Is step positive?
    dt, fixed = step == abs(step) ? last(possible) : first(possible)
    return ZonedDateTime(dt, tz, fixed)
end


