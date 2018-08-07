VERSION < v"0.7.0-beta2.199" && __precompile__()

module TimeZones

import Compat: Sys, occursin, undef, @info, @warn

using Compat.Dates, Compat.Printf, Compat.Serialization, Compat.Unicode
import Compat.Dates: TimeZone, AbstractTime
using Nullables

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
    guess,
    # TZData
    build

const PKG_DIR = normpath(joinpath(dirname(@__FILE__), ".."))
const DEPS_DIR = joinpath(PKG_DIR, "deps")
const ARCHIVE_DIR = joinpath(DEPS_DIR, "tzarchive")
const TZ_SOURCE_DIR = joinpath(DEPS_DIR, "tzsource")
const COMPILED_DIR = joinpath(DEPS_DIR, "compiled")
const TIME_ZONES = Dict{AbstractString,TimeZone}()

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
        if occursin(FIXED_TIME_ZONE_REGEX, str)
            return FixedTimeZone(str)
        end

        tz_path = joinpath(COMPILED_DIR, split(str, "/")...)
        isfile(tz_path) || throw(ArgumentError("Unknown time zone \"$str\""))

        open(tz_path, "r") do fp
            return deserialize(fp)
        end
    end
end

"""
    @tz_str -> TimeZone

Constructs a `TimeZone` subtype based upon the string at parse time. See docstring of
`TimeZone` for more details.

```julia
julia> tz"Africa/Nairobi"
Africa/Nairobi (UTC+3)
```
"""
macro tz_str(str)
    TimeZone(str)
end

"""
    istimezone(str::AbstractString) -> Bool

Tests whether a string is a valid name for constructing a `TimeZone`.
"""
function istimezone(str::AbstractString)
    return (
        haskey(TIME_ZONES, str) ||
        occursin(FIXED_TIME_ZONE_REGEX, str) ||
        isfile(joinpath(COMPILED_DIR, split(str, "/")...))
    )
end

"""
    build(version="latest", regions=REGIONS; force=false) -> Void

Builds the TimeZones package with the specified tzdata `version` and `regions`. The
`version` is typically a 4-digit year followed by a lowercase ASCII letter (e.g. "2016j").
Users can also specify which `regions`, or tz source files, should be compiled. Available
regions are listed under `TimeZones.REGIONS` and `TimeZones.LEGACY_REGIONS`. The `force`
flag is used to re-download tzdata archives.
"""
function build(version::AbstractString="latest", regions=REGIONS; force::Bool=false)
    TimeZones.TZData.build(version, regions)

    if Sys.iswindows()
        TimeZones.WindowsTimeZoneIDs.build(force=force)
    end

    @info "Successfully built TimeZones"
end

include("utils.jl")
include("utcoffset.jl")
include("types.jl")
include("exceptions.jl")
include(joinpath("tzdata", "TZData.jl"))
Sys.iswindows() && include(joinpath("winzone", "WindowsTimeZoneIDs.jl"))
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

import TimeZones.TZData: REGIONS, LEGACY_REGIONS

end # module
