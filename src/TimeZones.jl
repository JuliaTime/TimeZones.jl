module TimeZones

using Artifacts: Artifacts
using Dates
using PrecompileTools: @compile_workload, @setup_workload
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

# Resolve the TZJData artifact directory using direct function calls that the
# juliac trimmer can trace. We intentionally avoid TZJData.artifact_dir() which
# uses the @artifact_str macro — that macro expands to Base.invokelatest(...),
# an opaque dynamic dispatch barrier the trimmer cannot follow through, causing
# the callee to be removed from trimmed binaries.
function _resolve_tzjdata_dir()
    pkg = Base.identify_package(TZJData, "TZJData")
    pkg_dir = dirname(dirname(Base.locate_package(pkg)))
    artifact_dict = Artifacts.parse_toml(joinpath(pkg_dir, "Artifacts.toml"))
    hash = Base.SHA1(artifact_dict["tzjdata"]["git-tree-sha1"])
    return Artifacts.artifact_path(hash)
end

function __init__()
    # Set at runtime to ensure relocatability
    _COMPILED_DIR[] = _resolve_tzjdata_dir()

    # Dates extension needs to happen everytime the module is loaded (issue #24)
    init_dates_extension()

    if haskey(ENV, "JULIA_TZ_VERSION")
        @info "Using tzdata $(TZData.tzdata_version())"
    end
end

include("utils.jl")
include("indexable_generator.jl")

include("class.jl")
include("utcoffset.jl")
include(joinpath("types", "timezone.jl"))
include(joinpath("types", "fixedtimezone.jl"))
include(joinpath("types", "variabletimezone.jl"))
include(joinpath("types", "timezonecache.jl"))
include(joinpath("types", "zoneddatetime.jl"))
include(joinpath("tzfile", "TZFile.jl"))
include(joinpath("tzjfile", "TZJFile.jl"))
include("exceptions.jl")
include(joinpath("tzdata", "TZData.jl"))
include("windows_zones.jl")
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

# Ensure methods used in __init__ are preserved by juliac --trim (requires Julia >= 1.12).
# The trimmer only keeps methods reachable from @ccallable entry points and precompiled
# methods. This workload exercises the __init__ code paths so the trimmer retains them.
# On Julia < 1.9, @compile_workload still executes the code but doesn't cache native code
@setup_workload begin
    @compile_workload begin
        # Preserve artifact resolution methods needed by __init__.
        _resolve_tzjdata_dir()

        @static if VERSION >= v"1.9"
            # Also sets _COMPILED_DIR so the TimeZone("UTC") call below can load tzdata.
            _COMPILED_DIR[] = _resolve_tzjdata_dir()

            # Exercise core timezone functionality so timezone loading methods
            # are also preserved.
            TimeZone("UTC")
        end
    end
end

end # module
