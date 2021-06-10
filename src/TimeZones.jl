module TimeZones

using Dates
using Printf
using Serialization
using RecipesBase: RecipesBase, @recipe
using Unicode
using Pkg.TOML
using Scratch

import Dates: TimeZone, UTC

export TimeZone, @tz_str, istimezone, FixedTimeZone, VariableTimeZone, ZonedDateTime,
    DateTime, Date, Time, UTC, Local, TimeError, AmbiguousTimeError, NonExistentTimeError,
    UnhandledTimeError,
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

# Compile the deps files contents into the precompiled module for relocatability.
const DEPS_CONTENTS = Dict{String,String}()
let deps = joinpath(@__DIR__, "..", "deps")
    for (root, dirs, files) in walkdir(deps), file in files
        path = joinpath(relpath(root, deps), file)
        include_dependency(joinpath(deps, path))
        DEPS_CONTENTS[path] = read(joinpath(deps, path), String)
    end
end

# TimeZone types used to disambiguate the context of a DateTime
# abstract type UTC <: TimeZone end  # Already defined in the Dates stdlib
abstract type Local <: TimeZone end

const PKG_VERSION = VersionNumber(TOML.parsefile(joinpath(dirname(@__DIR__), "Project.toml"))["version"])

function __init__()
    global DEPS_DIR = @get_scratch!("timezones-$PKG_VERSION")
    isdir(DEPS_DIR) || mkpath(DEPS_DIR)
    TZData._init()
    @static Sys.iswindows() && WindowsTimeZoneIDs._init()
    if !isdir(joinpath(DEPS_DIR, "compiled", string(VERSION)))
        cd(DEPS_DIR) do
            for (path, contents) in DEPS_CONTENTS
                mkpath(dirname(path))
                write(path, contents)
            end
        end
        build()
    end

    # Base extension needs to happen everytime the module is loaded (issue #24)
    Dates.CONVERSION_SPECIFIERS['z'] = TimeZone
    Dates.CONVERSION_SPECIFIERS['Z'] = TimeZone
    Dates.CONVERSION_DEFAULTS[TimeZone] = ""
    Dates.CONVERSION_TRANSLATIONS[ZonedDateTime] = (
        Year, Month, Day, Hour, Minute, Second, Millisecond, TimeZone,
    )

    global ISOZonedDateTimeFormat = DateFormat("yyyy-mm-ddTHH:MM:SS.ssszzz")
end

include("compat.jl")
include("utils.jl")
include("indexable_generator.jl")

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
include("plotting.jl")
include("deprecated.jl")

end # module
