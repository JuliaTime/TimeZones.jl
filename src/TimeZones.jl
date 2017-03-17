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
    # Base extension needs to happen everytime the module is loaded (issue #24)
    if isdefined(Base.Dates, :SLOT_RULE)
        Base.Dates.SLOT_RULE['z'] = TimeZone
        Base.Dates.SLOT_RULE['Z'] = TimeZone
    else
        Base.Dates.CONVERSION_SPECIFIERS['z'] = TimeZone
        Base.Dates.CONVERSION_SPECIFIERS['Z'] = TimeZone
        Base.Dates.CONVERSION_DEFAULTS[TimeZone] = ""
        Base.Dates.CONVERSION_TRANSLATIONS[ZonedDateTime] = (
            Year, Month, Day, Hour, Minute, Second, Millisecond, TimeZone,
        )
    end

    global const ISOZonedDateTimeFormat = DateFormat("yyyy-mm-ddTHH:MM:SS.ssszzz")
end

"""
    TimeZone(str::AbstractString) -> TimeZone

Constructs a `TimeZone` subtype based upon the string. If the string is a recognized time
zone name then data is loaded from the compiled IANA time zone database. Otherwise the
string is assumed to be a static time zone.

A list of recognized time zones names is available from `timezone_names()`. Supported static
time zone string formats can be found in `FixedTimeZone(::AbstractString)`.
"""
function TimeZone(str::AbstractString)
    return get!(TIME_ZONES, str) do
        if ismatch(FIXED_TIME_ZONE_REGEX, str)
            return FixedTimeZone(str)
        end

        tz_path = joinpath(COMPILED_DIR, split(str, "/")...)
        isfile(tz_path) || throw(ArgumentError("Unknown time zone \"$str\""))

        open(tz_path, "r") do fp
            return deserialize(fp)
        end
    end
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
VERSION < v"0.6.0-dev.2307" ? include("parse-old.jl") : include("parse.jl")

end # module
