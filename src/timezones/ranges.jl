import Base.Dates: guess, toms

"""
Given a start and end date, indicates how many steps/periods are between them. Defining this
function allows `StepRange`s to be defined for `ZonedDateTime`s.
"""
function guess(start::ZonedDateTime, finish::ZonedDateTime, step)
    floor(Int64, (Int128(finish.utc_datetime) - Int128(start.utc_datetime)) / toms(step))
end
