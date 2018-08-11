import Compat.Dates: trunc, DatePeriod, TimePeriod
import Compat.Dates: firstdayofweek, lastdayofweek, firstdayofmonth, lastdayofmonth,
    firstdayofyear, lastdayofyear, firstdayofquarter, lastdayofquarter


# Truncation
# TODO: Just utilize floor code for truncation?
function trunc(ldt::Localized, ::Type{P}) where P<:DatePeriod
    Localized(trunc(localtime(ldt), P), timezone(ldt))
end
function trunc(ldt::Localized, ::Type{P}) where P<:TimePeriod
    local_dt = trunc(localtime(ldt), P)
    utc_dt = local_dt - ldt.zone.offset
    Localized(utc_dt, timezone(ldt); from_utc=true)
end
trunc(ldt::Localized, ::Type{Millisecond}) = ldt

# Adjusters
for prefix in ("firstdayof", "lastdayof"), suffix in ("week", "month", "year", "quarter")
    func = Symbol(prefix * suffix)
    @eval begin
        $func(dt::Localized) = Localized($func(localtime(dt)), dt.timezone)
    end
end
