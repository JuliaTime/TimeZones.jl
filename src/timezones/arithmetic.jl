import Base: +, -

# ZonedDateTime arithmetic
(+)(x::ZonedDateTime) = x
(-)(x::ZonedDateTime, y::ZonedDateTime) = x.utc_datetime - y.utc_datetime

function (+)(zdt::ZonedDateTime, p::DatePeriod)
    return ZonedDateTime(localtime(zdt) + p, zdt.timezone)
end
function (+)(zdt::ZonedDateTime, p::TimePeriod)
    return ZonedDateTime(zdt.utc_datetime + p, zdt.timezone; from_utc=true)
end
function (-)(zdt::ZonedDateTime, p::DatePeriod)
    return ZonedDateTime(localtime(zdt) - p, zdt.timezone)
end
function (-)(zdt::ZonedDateTime, p::TimePeriod)
    return ZonedDateTime(zdt.utc_datetime - p, zdt.timezone; from_utc=true)
end
