"""
    Class

A type used for controlling which classes of `TimeZone` are considered valid. Instances of
`Class` can be combined using bitwise operators to generate a mask which allows multiple
classes to be considered valid at once.

Currently supported masks are:

- `Class(:FIXED)`: Class indicating the time zone name is parsable as a fixed UTC offset.
- `Class(:STANDARD)`: The time zone name is included in the primary IANA tz source files.
- `Class(:LEGACY)`: The time zone name is included in the deprecated IANA tz source files.
- `Class(:NONE)`: Mask that will match nothing.
- `Class(:DEFAULT)`: Default mask used by functions: `Class(:FIXED) | Class(:STANDARD)`
- `Class(:ALL)`: Mask allowing all supported classes.
"""
struct Class
    val::UInt8
end

function Class(name::Symbol)
    if name === :NONE
        Class(0x00)
    elseif name === :FIXED
        Class(0x01)
    elseif name === :STANDARD
        Class(0x02)
    elseif name === :LEGACY
        Class(0x04)
    elseif name === :DEFAULT
        Class(:FIXED) | Class(:STANDARD)
    elseif name === :ALL
        Class(:FIXED) | Class(:STANDARD) | Class(:LEGACY)
    else
        throw(ArgumentError("Unknown class name: $name"))
    end
end

function Class(str::AbstractString, regions::AbstractSet{<:AbstractString})
    class = Class(:NONE)
    occursin(FIXED_TIME_ZONE_REGEX, str) && (class |= Class(:FIXED))
    !isempty(intersect(regions, TZData.STANDARD_REGIONS)) && (class |= Class(:STANDARD))
    !isempty(intersect(regions, TZData.LEGACY_REGIONS)) && (class |= Class(:LEGACY))
    return class
end

Class(str::AbstractString, regions::AbstractVector) = Class(str, Set{String}(regions))

Base.:(|)(a::Class, b::Class) = Class(a.val | b.val)
Base.:(&)(a::Class, b::Class) = Class(a.val & b.val)
Base.:(==)(a::Class, b::Class) = a.val == b.val
Base.:(~)(a::Class) = Class(~a.val)

function Base.show(io::IO, mask::Class)
    C = repr(Class)
    mask == Class(:NONE) && return print(io, "$C(:NONE)")

    names = String[]
    mask & Class(:FIXED) == Class(:FIXED) && push!(names, "$C(:FIXED)")
    mask & Class(:STANDARD) == Class(:STANDARD) && push!(names, "$C(:STANDARD)")
    mask & Class(:LEGACY) == Class(:LEGACY) && push!(names, "$C(:LEGACY)")

    unused = mask & ~Class(:ALL)
    unused != Class(:NONE) && push!(names, "$C($(repr(unused.val)))")

    join(io, names, " | ")
end
