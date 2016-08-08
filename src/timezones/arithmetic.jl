import Base: +, -, .+, .-

# ZonedDateTime arithmetic
(+)(x::ZonedDateTime) = x
(-)(x::ZonedDateTime, y::ZonedDateTime) = x.utc_datetime - y.utc_datetime

function (+)(zdt::ZonedDateTime, p::DatePeriod)
    return ZonedDateTime(localtime(zdt) + p, timezone(zdt))
end
function (+)(zdt::ZonedDateTime, p::TimePeriod)
    return ZonedDateTime(zdt.utc_datetime + p, timezone(zdt); from_utc=true)
end
function (-)(zdt::ZonedDateTime, p::DatePeriod)
    return ZonedDateTime(localtime(zdt) - p, timezone(zdt))
end
function (-)(zdt::ZonedDateTime, p::TimePeriod)
    return ZonedDateTime(zdt.utc_datetime - p, timezone(zdt); from_utc=true)
end

function (.+)(r::StepRange{ZonedDateTime}, p::DatePeriod)
    start, s, finish = first(r), step(r), last(r)

    # Since the localtime + period can result in an invalid local datetime we'll use
    # `closest` to always return a valid ZonedDateTime.
    start = closest(localtime(start) + p, timezone(start), -s)
    finish = closest(localtime(finish) + p, timezone(finish), s)

    return StepRange(start, s, finish)
end

(.-)(r::StepRange{ZonedDateTime}, p::DatePeriod) = r .+ (-p)
