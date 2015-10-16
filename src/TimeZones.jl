module TimeZones

using Base.Dates
import Base.Dates: AbstractTime, days, hour, minute, second, millisecond

export TimeZone, FixedTimeZone, VariableTimeZone, ZonedDateTime, DateTime, timezone_names,
    TimeError, AmbiguousTimeError, NonExistentTimeError,
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
    localzone

const PKG_DIR = normpath(joinpath(dirname(@__FILE__), ".."))
const TZDATA_DIR = joinpath(PKG_DIR, "deps", "tzdata")
const COMPILED_DIR = joinpath(PKG_DIR, "deps", "compiled")

@windows_only begin
    const WIN_TRANSLATION_FILE = joinpath(PKG_DIR, "deps", "windows_to_posix")
end

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

doc"""
`TimeZone(name::AbstractString) -> TimeZone`

Construct `TimeZone` information based upon its `name`.
See `FixedTimeZone(::AbstractString)` for making a custom `TimeZone`.
"""
function TimeZone(name::AbstractString)
    tz_path = joinpath(COMPILED_DIR, split(name, "/")...)

    isfile(tz_path) || error("Unknown timezone $name")

    open(tz_path, "r") do fp
        return deserialize(fp)
    end
end

doc"""
`timezone_names() -> Array{AbstractString}`

Returns all of the valid names for constructing a `TimeZone`.
"""
function timezone_names()
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

    return sort(names)
end

end # module
