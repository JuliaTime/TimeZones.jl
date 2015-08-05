module TimeZones

include("timezones/types.jl")
include("timezones/accessors.jl")
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

export TimeZone, FixedTimeZone, VariableTimeZone, Transition, ZonedDateTime
    AmbiguousTimeError, NonExistentTimeError

end # module