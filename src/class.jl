"""
    Class

A type used for controlling which classes of `TimeZone` are considered valid. Instances of
`Class` can be combined using bitwise operators to generate a mask which allows multiple
classes to be considered valid at once.

Currently supported masks are:

- `Class.FIXED`: Class indicating the time zone name is parsable as a fixed UTC offset.
- `Class.STANDARD`: The time zone name is included in the primary IANA tz source files.
- `Class.LEGACY`: The time zone name is included in the deprecated IANA tz source files.
- `Class.NONE`: Mask that will match nothing.
- `Class.DEFAULT`: Default mask used by functions: `Class.FIXED | Class.STANDARD`
- `Class.ALL`: Mask allowing all supported classes.
"""
struct Class
    val::UInt8
end

function Base.getproperty(::Type{Class}, field::Symbol)
    if field == :NONE
        Class(0x00)
    elseif field == :FIXED
        Class(0x01)
    elseif field == :STANDARD
        Class(0x02)
    elseif field == :LEGACY
        Class(0x04)
    elseif field == :DEFAULT
        Class.FIXED | Class.STANDARD
    elseif field == :ALL
        Class.FIXED | Class.STANDARD | Class.LEGACY
    else
        getfield(Class, field)
    end
end

function classify(str::AbstractString, regions::AbstractSet{<:AbstractString})
    class = Class.NONE
    occursin(FIXED_TIME_ZONE_REGEX, str) && (class |= Class.FIXED)
    !isempty(intersect(regions, TZData.STANDARD_REGIONS)) && (class |= Class.STANDARD)
    !isempty(intersect(regions, TZData.LEGACY_REGIONS)) && (class |= Class.LEGACY)
    return class
end

classify(str::AbstractString, regions::AbstractVector) = classify(str, Set{String}(regions))

Base.:(|)(a::Class, b::Class) = Class(a.val | b.val)
Base.:(&)(a::Class, b::Class) = Class(a.val & b.val)
Base.:(==)(a::Class, b::Class) = a.val == b.val

function labels(mask::Class)
    names = String[]
    mask & Class.FIXED == Class.FIXED && push!(names, "FIXED")
    mask & Class.STANDARD == Class.STANDARD && push!(names, "STANDARD")
    mask & Class.LEGACY == Class.LEGACY && push!(names, "LEGACY")
    mask == Class.NONE && push!(names, "NONE")
    return names
end

Base.print(io::IO, mask::Class) = join(io, labels(mask), " | ")
Base.show(io::IO, mask::Class) = join(io, string.("Class.", labels(mask)), " | ")
