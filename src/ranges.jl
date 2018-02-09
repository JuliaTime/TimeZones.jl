using Dates: guess

"""
    guess(start::ZonedDateTime, finish::ZonedDateTime, step) -> Integer

Given a start and end date, indicates how many steps/periods are between them. Defining this
function allows `StepRange`s to be defined for `ZonedDateTime`s.
"""
function Dates.guess(start::ZonedDateTime, finish::ZonedDateTime, step)
    guess(start.utc_datetime, finish.utc_datetime, step)
end
