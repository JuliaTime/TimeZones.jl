module TimeZones

using Base.Dates
import Base.Dates: AbstractTime, days, hour, minute, second, millisecond

export TimeZone, FixedTimeZone, VariableTimeZone, ZonedDateTime, DateTime,
    TimeError, AmbiguousTimeError, NonExistentTimeError, UnhandledTimeError,
    # discovery.jl
    timezone_names, all_timezones, timezones_from_abbr, timezone_abbrs,
    # accessors.jl
    hour, minute, second, millisecond,
    # adjusters.jl
    firstdayofweek, lastdayofweek,
    firstdayofmonth, lastdayofmonth,
    firstdayofyear, lastdayofyear,
    firstdayofquarter, lastdayofquarter,
    # Re-export from Base.Dates
    yearmonthday, yearmonth, monthday, year, month, week, day, dayofmonth,
    # conversion.jl
    now,
    # local.jl
    localzone,
    # ranges.jl
    guess

const PKG_DIR = normpath(joinpath(dirname(@__FILE__), ".."))
const TZDATA_DIR = joinpath(PKG_DIR, "deps", "tzdata")
const COMPILED_DIR = joinpath(PKG_DIR, "deps", "compiled")

@windows_only begin
    const WIN_TRANSLATION_FILE = joinpath(PKG_DIR, "deps", "windows_to_posix")
end

include("timezones/utils.jl")
include("timezones/time.jl")
include("timezones/utcoffset.jl")
include("timezones/types.jl")
include("timezones/accessors.jl")
include("timezones/arithmetic.jl")
include("timezones/io.jl")
include("timezones/tzfile.jl")
include("timezones/adjusters.jl")
include("timezones/Olson.jl")
include("timezones/conversions.jl")
include("timezones/local.jl")
include("timezones/ranges.jl")
include("timezones/discovery.jl")

"""
    TimeZone(name::AbstractString) -> TimeZone

Constructs a `TimeZone` instance based upon its `name`. A list of available time zones can
be determined using `timezone_names()`.

See `FixedTimeZone(::AbstractString)` for making a custom `TimeZone` instances.
"""
function TimeZone(name::AbstractString)
    tz_path = joinpath(COMPILED_DIR, split(name, "/")...)

    isfile(tz_path) || error("Unknown time zone $name")

    # Workaround for bug with Mocking.jl. Ideally should be using `do` syntax
    fp = open(tz_path, "r")
    try
        return deserialize(fp)
    finally
        close(fp)
    end
end

end # module
