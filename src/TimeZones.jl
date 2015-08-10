module TimeZones

include("timezones/types.jl")
include("timezones/accessors.jl")
include("timezones/arithmetic.jl")
include("timezones/io.jl")
include("timezones/Olsen.jl")

function TimeZone(name::String)
    compiled_dir = joinpath(dirname(@__FILE__), "..", "deps", "compiled")
    tz_path = joinpath(compiled_dir, split(name, "/")...)

    isfile(tz_path) || error("Unknown timezone $name")

    open(tz_path, "r") do fp
        return deserialize(fp)
    end
end

function timezone_names()
    names = String[]

    compiled_dir = joinpath(dirname(@__FILE__), "..", "deps", "compiled")
    check = Tuple{String,String}[(compiled_dir, "")]

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

export TimeZone, FixedTimeZone, VariableTimeZone, Transition, ZonedDateTime,
    AmbiguousTimeError, NonExistentTimeError

end # module