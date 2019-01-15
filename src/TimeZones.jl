module TimeZones

using Dates
using Printf
using Serialization
using Unicode
import Dates: TimeZone

export TimeZone, @tz_str, istimezone, FixedTimeZone, VariableTimeZone, ZonedDateTime,
    DateTime, TimeError, AmbiguousTimeError, NonExistentTimeError, UnhandledTimeError,
    # discovery.jl
    timezone_names, all_timezones, timezones_from_abbr, timezone_abbrs,
    next_transition_instant, show_next_transition,
    # accessors.jl
    hour, minute, second, millisecond,
    # adjusters.jl
    firstdayofweek, lastdayofweek,
    firstdayofmonth, lastdayofmonth,
    firstdayofyear, lastdayofyear,
    firstdayofquarter, lastdayofquarter,
    # Re-export from Dates
    yearmonthday, yearmonth, monthday, year, month, week, day, dayofmonth,
    # conversion.jl
    now, today, todayat, astimezone,
    # local.jl
    localzone,
    # ranges.jl
    guess

const PKG_DIR = normpath(joinpath(dirname(@__FILE__), ".."))
const DEPS_DIR = joinpath(PKG_DIR, "deps")

function __init__()
    # Base extension needs to happen everytime the module is loaded (issue #24)
    Dates.CONVERSION_SPECIFIERS['z'] = TimeZone
    Dates.CONVERSION_SPECIFIERS['Z'] = TimeZone
    Dates.CONVERSION_DEFAULTS[TimeZone] = ""
    Dates.CONVERSION_TRANSLATIONS[ZonedDateTime] = (
        Year, Month, Day, Hour, Minute, Second, Millisecond, TimeZone,
    )

    global ISOZonedDateTimeFormat = DateFormat("yyyy-mm-ddTHH:MM:SS.ssszzz")
end

include("utils.jl")
include("class.jl")
include("utcoffset.jl")
include(joinpath("types", "timezone.jl"))
include(joinpath("types", "fixedtimezone.jl"))
include(joinpath("types", "variabletimezone.jl"))
include(joinpath("types", "zoneddatetime.jl"))
include("exceptions.jl")
include(joinpath("tzdata", "TZData.jl"))
Sys.iswindows() && include(joinpath("winzone", "WindowsTimeZoneIDs.jl"))
include("build.jl")
include("interpret.jl")
include("accessors.jl")
include("arithmetic.jl")
include("io.jl")
include("tzfile.jl")
include("adjusters.jl")
include("conversions.jl")
include("local.jl")
include("ranges.jl")
include("discovery.jl")
include("rounding.jl")
include("parse.jl")
include("deprecated.jl")

end # module
