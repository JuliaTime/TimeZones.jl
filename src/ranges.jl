import Compat.Dates: guess

"""
    guess(start::Localized, finish::Localized, step) -> Integer

Given a start and end date, indicates how many steps/periods are between them. Defining this
function allows `StepRange`s to be defined for `Localized`s.
"""
function guess(start::Localized, finish::Localized, step)
    guess(start.utc_datetime, finish.utc_datetime, step)
end
