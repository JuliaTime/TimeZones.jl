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


# Note: ParseNextError should avoid raising exceptions when start/end index aren't
# unreasonable to attempt and always show the actual parsing error instead of an internal
# error.

"""
    ParseNextError

An exception which displays the portion of a string which could not be parsed successfully.
"""
struct ParseNextError <: Exception
    msg::AbstractString
    str::AbstractString
    s::Int
    e::Int
end

function ParseNextError(msg, str, s)
    len = lastindex(str)
    ParseNextError(msg, str, s, s >= len ? len : s)
end

function Base.showerror(io::IO, e::ParseNextError)
    print(io, "$ParseNextError: ")
    if !isempty(e.msg)
        print(io, "$(e.msg): ")
    end

    str = e.str
    len = lastindex(str)
    u_start = e.s
    u_end = e.e > len || e.e < e.s ? len : e.e

    print(io, "\"", str[firstindex(str):prevind(str, u_start)])
    printstyled(io, str[u_start:u_end], color=:underline)
    print(io, str[nextind(str, u_end):len])
    if e.s > len
        printstyled(io, "\"", color=:underline)
    else
        print(io, "\"")
    end
end

function Base.show(io::IO, ::MIME"text/plain", e::ParseNextError)
    showerror(io, e)
    print(io, " ($(e.s), $(e.e))")
end
