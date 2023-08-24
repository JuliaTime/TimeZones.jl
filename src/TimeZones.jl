module TimeZones

using Dates
using Printf
using Scratch: @get_scratch!
using Unicode
using InlineStrings: InlineString15
using TZJData: TZJData

import Dates: TimeZone, UTC

export TimeZone, @tz_str, istimezone, FixedTimeZone, VariableTimeZone, ZonedDateTime,
    DateTime, Date, Time, UTC, Local, TimeError, AmbiguousTimeError, NonExistentTimeError,
    UnhandledTimeError, TZFile,
    # discovery.jl
    timezone_names, all_timezones, timezones_from_abbr, timezone_abbrs,
    next_transition_instant, show_next_transition,
    # accessors.jl
    timezone, hour, minute, second, millisecond,
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

_scratch_dir() = @get_scratch!("build")

const _COMPILED_DIR = Ref{String}()

# TimeZone types used to disambiguate the context of a DateTime
# abstract type UTC <: TimeZone end  # Already defined in the Dates stdlib
abstract type Local <: TimeZone end

function __init__()
    # Write out our compiled tzdata representations into a scratchspace
    desired_version = TZData.tzdata_version()

    _COMPILED_DIR[] = if desired_version == TZJData.TZDATA_VERSION
        TZJData.ARTIFACT_DIR
    else
        @info "Loading tzdata $desired_version"
        TZData.build(desired_version, _scratch_dir())
    end

    # Load the pre-computed TZData into memory. Skip pre-fetching the first time
    # TimeZones.jl is loaded by `deps/build.jl` as we have yet to compile the tzdata.
    isdir(_COMPILED_DIR[]) && _reload_cache(_COMPILED_DIR[])

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
include("indexable_generator.jl")

include("class.jl")
include("utcoffset.jl")
include(joinpath("types", "timezone.jl"))
include(joinpath("types", "fixedtimezone.jl"))
include(joinpath("types", "variabletimezone.jl"))
include(joinpath("types", "zoneddatetime.jl"))
include(joinpath("tzfile", "TZFile.jl"))
include(joinpath("tzjfile", "TZJFile.jl"))
include("exceptions.jl")
include(joinpath("tzdata", "TZData.jl"))
Sys.iswindows() && include(joinpath("winzone", "WindowsTimeZoneIDs.jl"))
include("build.jl")
include("interpret.jl")
include("accessors.jl")
include("arithmetic.jl")
include("io.jl")
include("adjusters.jl")
include("conversions.jl")
include("local.jl")
include("ranges.jl")
include("discovery.jl")
include("rounding.jl")
include("parse.jl")
include("deprecated.jl")

# Required to support Julia `VERSION < v"1.9"`
if !isdefined(Base, :get_extension)
    include("../ext/TimeZonesRecipesBaseExt.jl")
end

end # module
