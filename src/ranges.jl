import Base: steprem, collect
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

function collect{P<:DatePeriod}(r::OrdinalRange{ZonedDateTime,P}; non_existent=:invalid, ambiguous=:invalid)
    lo, s, hi = first(r), step(r), last(r)
    results = ZonedDateTime[lo]

    op = s > zero(s) ? (<=) : (>=)

    local_dt, tz = localtime(lo) + s, timezone(lo)
    last_local_dt = localtime(hi)
    while op(local_dt, last_local_dt)
        possible = interpret(local_dt, tz, Local)

        num = length(possible)
        if num == 1
            push!(results, first(possible))
        elseif num == 0
            if non_existent != :skip
                throw(NonExistentTimeError(local_dt, tz))
            end
        else
            if ambiguous == :all
                append!(results, possible)
            elseif ambiguous == :first
                push!(results, first(possible))
            elseif ambiguous == :last
                push!(results, last(possible))
            elseif ambiguous != :skip
                throw(AmbiguousTimeError(local_dt, tz))
            end
        end

        local_dt += s
    end

    return results
end

function collect{P<:TimePeriod}(r::OrdinalRange{ZonedDateTime,P}; non_existent=:invalid, ambiguous=:invalid)
    invoke(collect, (OrdinalRange,), r)
end
