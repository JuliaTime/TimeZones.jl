abstract type TimeError <: Exception end

"""
    AmbiguousTimeError(local_datetime, timezone)

The provided local datetime is ambiguous within the specified timezone. Typically occurs on
daylight saving time transitions which "fall back" causing duplicate hour long period.
"""
struct AmbiguousTimeError <: TimeError
    local_dt::DateTime
    timezone::TimeZone
end

function Base.showerror(io::IO, e::AmbiguousTimeError)
    print(io, "AmbiguousTimeError: ")
    print(io, "Local DateTime $(e.local_dt) is ambiguous within $(string(e.timezone))")
end

"""
    NonExistentTimeError(local_datetime, timezone)

The provided local datetime is does not exist within the specified timezone. Typically
occurs on daylight saving time transitions which "spring forward" causing an hour long
period to be skipped.
"""
struct NonExistentTimeError <: TimeError
    local_dt::DateTime
    timezone::TimeZone
end

function Base.showerror(io::IO, e::NonExistentTimeError)
    print(io, "NonExistentTimeError: ")
    print(io, "Local DateTime $(e.local_dt) does not exist within $(string(e.timezone))")
end

"""
    UnhandledTimeError(timezone)

The timezone calculation occurs beyond the last calculated transition.
"""
struct UnhandledTimeError <: TimeError
    tz::VariableTimeZone
end

function Base.showerror(io::IO, e::UnhandledTimeError)
    print(io, "UnhandledTimeError: ")
    print(io, "TimeZone $(string(e.tz)) does not handle dates on or after $(e.tz.cutoff) UTC")
end
