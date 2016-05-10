module TimeZones

using Base.Dates
import Base.Dates: AbstractTime, days, hour, minute, second, millisecond

export TimeZone, FixedTimeZone, VariableTimeZone, ZonedDateTime, DateTime, timezone_names,
    TimeError, AmbiguousTimeError, NonExistentTimeError, UnhandledTimeError,
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

"""
    TimeZone(name::AbstractString) -> TimeZone

Constructs a `TimeZone` instance based upon its `name`. A list of available timezones can be
determined using `timezone_names()`.

See `FixedTimeZone(::AbstractString)` for making a custom `TimeZone` instances.
"""
function TimeZone(name::AbstractString)
    tz_path = joinpath(COMPILED_DIR, split(name, "/")...)

    isfile(tz_path) || error("Unknown timezone $name")

    # Workaround for bug with Mocking.jl. Ideally should be using `do` syntax
    fp = open(tz_path, "r")
    try
        return deserialize(fp)
    finally
        close(fp)
    end
end

"""
    timezone_names() -> Array{AbstractString}

Returns all of the valid names for constructing a `TimeZone`.
"""
function timezone_names()
    # Note: Olson time zone names are typically encoded only in ASCII. Using UTF8 here just
    # ensures compatibility in case things change.
    names = AbstractString[]
    check = Tuple{AbstractString,AbstractString}[(COMPILED_DIR, "")]

    for (dir, partial) in check
        for filename in readdir(dir)
            startswith(filename, ".") && continue

            path = joinpath(dir, filename)
            name = partial == "" ? filename : join([partial, filename], "/")

            if isdir(path)
                push!(check, (path, name))
            else
                push!(names, name)
            end
        end
    end

    return sort!(names)
end

end # module
