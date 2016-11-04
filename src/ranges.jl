import Base: steprem
import Base.Dates: guess, len

"""
    guess(start::ZonedDateTime, finish::ZonedDateTime, step) -> Integer

Given a start and end date, indicates how many steps/periods are between them. Defining this
function allows `StepRange`s to be defined for `ZonedDateTime`s.
"""
function guess(start::ZonedDateTime, finish::ZonedDateTime, step)
    guess(start.utc_datetime, finish.utc_datetime, step)
end

function len(a::ZonedDateTime,b::ZonedDateTime,c::DatePeriod)
    len(localtime(a), localtime(b), c)
end

function steprem{T<:ZonedDateTime}(a::T,b::T,c::DatePeriod)
    b - last_valid(localtime(a) + c*len(a,b,c), timezone(a), c)
end
