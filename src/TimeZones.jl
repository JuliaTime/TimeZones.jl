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

    global const ISOZonedDateTimeFormat = DateFormat("yyyy-mm-ddTHH:MM:SS.ssszzz")
end

include("utils.jl")
include("timeoffset.jl")
include("utcoffset.jl")
include("types.jl")
include("interpret.jl")
include("accessors.jl")
include("arithmetic.jl")
include("io.jl")
include("tzfile.jl")
include("adjusters.jl")
include("Olson.jl")
include("conversions.jl")
include("local.jl")
include("ranges.jl")
include("discovery.jl")
VERSION >= v"0.5.0-dev+5244" && include("rounding.jl")

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
