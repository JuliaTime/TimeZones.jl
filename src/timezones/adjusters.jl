import Base.Dates: Year, Month, Day, Hour, Minute, Second, Millisecond
import Base.Dates: firstdayofweek, lastdayofweek, firstdayofmonth, lastdayofmonth,
    firstdayofyear, lastdayofyear, firstdayofquarter, lastdayofquarter

# Truncation
function Base.trunc(dt::ZonedDateTime, t::Union{Type{Year}, Type{Month}, Type{Day}})
    ZonedDateTime(trunc(localtime(dt), t), dt.timezone)
end
function Base.trunc(dt::ZonedDateTime, t::Union{Type{Hour}, Type{Minute}, Type{Second}})
    ZonedDateTime(trunc(utc(dt), t), dt.timezone, from_utc=true)
end
Base.trunc(dt::ZonedDateTime,::Type{Millisecond}) = dt

# Adjusters
for prefix in ("firstdayof", "lastdayof"), suffix in ("week", "month", "year", "quarter")
    func = symbol(prefix * suffix)
    @eval begin
        $func(dt::ZonedDateTime) = ZonedDateTime($func(localtime(dt)), dt.timezone)
    end
end
