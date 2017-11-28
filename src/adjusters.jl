import Compat.Dates: trunc, DatePeriod, TimePeriod
import Compat.Dates: firstdayofweek, lastdayofweek, firstdayofmonth, lastdayofmonth,
    firstdayofyear, lastdayofyear, firstdayofquarter, lastdayofquarter


# Truncation
# TODO: Just utilize floor code for truncation?
function trunc(zdt::ZonedDateTime, ::Type{P}) where P<:DatePeriod
    ZonedDateTime(trunc(localtime(zdt), P), timezone(zdt))
end
function trunc(zdt::ZonedDateTime, ::Type{P}) where P<:TimePeriod
    local_dt = trunc(localtime(zdt), P)
    utc_dt = local_dt - zdt.zone.offset
    ZonedDateTime(utc_dt, timezone(zdt); from_utc=true)
end
trunc(zdt::ZonedDateTime, ::Type{Millisecond}) = zdt

# Adjusters
for prefix in ("firstdayof", "lastdayof"), suffix in ("week", "month", "year", "quarter")
    func = Symbol(prefix * suffix)
    @eval begin
        $func(dt::ZonedDateTime) = ZonedDateTime($func(localtime(dt)), dt.timezone)
    end
end
