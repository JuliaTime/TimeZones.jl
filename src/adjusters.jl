using Dates: DatePeriod, TimePeriod, firstdayofweek, lastdayofweek,
    firstdayofmonth, lastdayofmonth, firstdayofyear, lastdayofyear,
    firstdayofquarter, lastdayofquarter


# Truncation
# TODO: Just utilize floor code for truncation?
function Base.trunc(zdt::ZonedDateTime, ::Type{P}) where P <: DatePeriod
    ZonedDateTime(trunc(DateTime(zdt), P), timezone(zdt))
end
function Base.trunc(zdt::ZonedDateTime, ::Type{P}) where P <: TimePeriod
    local_dt = trunc(DateTime(zdt), P)
    utc_dt = local_dt - zdt.zone.offset
    ZonedDateTime(utc_dt, timezone(zdt); from_utc=true)
end
Base.trunc(zdt::ZonedDateTime, ::Type{Millisecond}) = zdt

# Adjusters
for prefix in ("firstdayof", "lastdayof"), suffix in ("week", "month", "year", "quarter")
    func = Symbol(prefix * suffix)
    @eval function Dates.$func(zdt::ZonedDateTime)
        ZonedDateTime($func(DateTime(zdt)), zdt.timezone)
    end
end
