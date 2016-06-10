module TimeZones

using Base.Dates
import Base.Dates: TimeZone, AbstractTime, days, hour, minute, second, millisecond
import Compat: is_windows

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
    now, astimezone,
    # local.jl
    localzone,
    # ranges.jl
    guess

const PKG_DIR = normpath(joinpath(dirname(@__FILE__), ".."))
const TZDATA_DIR = joinpath(PKG_DIR, "deps", "tzdata")
const COMPILED_DIR = joinpath(PKG_DIR, "deps", "compiled")
const TIME_ZONES = Dict{AbstractString,TimeZone}()

if is_windows()
    const WIN_TRANSLATION_FILE = joinpath(PKG_DIR, "deps", "windows_to_posix")
end

function __init__()
    # SLOT_RULE extension needs to happen everytime the module is loaded (issue #24)
    Base.Dates.SLOT_RULE['z'] = TimeZone
    Base.Dates.SLOT_RULE['Z'] = TimeZone

    global const ISOZonedDateTimeFormat = DateFormat("yyyy-mm-ddTHH:MM:SS.szzz")
end

include(joinpath("timezones", "utils.jl"))
include(joinpath("timezones", "time.jl"))
include(joinpath("timezones", "utcoffset.jl"))
include(joinpath("timezones", "types.jl"))
include(joinpath("timezones", "accessors.jl"))
include(joinpath("timezones", "arithmetic.jl"))
include(joinpath("timezones", "io.jl"))
include(joinpath("timezones", "tzfile.jl"))
include(joinpath("timezones", "adjusters.jl"))
include(joinpath("timezones", "Olson.jl"))
include(joinpath("timezones", "conversions.jl"))
include(joinpath("timezones", "local.jl"))
include(joinpath("timezones", "ranges.jl"))
include(joinpath("timezones", "discovery.jl"))

"""
    TimeZone(name::AbstractString) -> TimeZone

Constructs a `TimeZone` instance based upon its `name`. A list of available time zones can
be determined using `timezone_names()`.

See `FixedTimeZone(::AbstractString)` for making a custom `TimeZone` instances.
"""
function TimeZone(name::AbstractString)
    return get!(TIME_ZONES, name) do
        tz_path = joinpath(COMPILED_DIR, split(name, "/")...)
        isfile(tz_path) || throw(ArgumentError("Unknown time zone named $name"))

        open(tz_path, "r") do fp
            return deserialize(fp)
        end
    end
end

end # module
