typealias LocalPeriod Union{Year,Month,Week,Day}
typealias UTCPeriod Union{Hour,Minute,Second,Millisecond}

# ZonedDateTime arithmetic
(+)(x::ZonedDateTime) = x
(-)(x::ZonedDateTime,y::ZonedDateTime) = x.utc_datetime - y.utc_datetime

function (+)(dt::ZonedDateTime,p::LocalPeriod)
    return ZonedDateTime(localtime(dt) + p, dt.timezone)
end
function (+)(dt::ZonedDateTime,p::UTCPeriod)
    return ZonedDateTime(dt.utc_datetime + p, dt.timezone; from_utc=true)
end
function (-)(dt::ZonedDateTime,p::LocalPeriod)
    return ZonedDateTime(localtime(dt) - p, dt.timezone)
end
function (-)(dt::ZonedDateTime,p::UTCPeriod)
    return ZonedDateTime(dt.utc_datetime - p, dt.timezone; from_utc=true)
end