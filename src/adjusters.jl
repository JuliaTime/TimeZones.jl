import Compat.Dates: trunc, DatePeriod, TimePeriod
import Compat.Dates: firstdayofweek, lastdayofweek, firstdayofmonth, lastdayofmonth,
    firstdayofyear, lastdayofyear, firstdayofquarter, lastdayofquarter


# Truncation
# TODO: Just utilize floor code for truncation?
function trunc(zdt::Localized, ::Type{P}) where P<:DatePeriod
    Localized(trunc(localtime(zdt), P), timezone(zdt))
end
function trunc(zdt::Localized, ::Type{P}) where P<:TimePeriod
    local_dt = trunc(localtime(zdt), P)
    utc_dt = local_dt - zdt.zone.offset
    Localized(utc_dt, timezone(zdt); from_utc=true)
end
trunc(zdt::Localized, ::Type{Millisecond}) = zdt

# Adjusters
for prefix in ("firstdayof", "lastdayof"), suffix in ("week", "month", "year", "quarter")
    func = Symbol(prefix * suffix)
    @eval begin
        $func(dt::Localized) = Localized($func(localtime(dt)), dt.timezone)
    end
end
