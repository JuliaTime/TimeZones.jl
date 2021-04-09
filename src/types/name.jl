struct SName
    region::ShortString15
    locality1::ShortString15
    locality2::ShortString15
end

function Base.print(io::IO, name::SName)
    print(io, name.region)
    if !isempty(name.locality1)
        print(io,"/", name.locality1)
        if !isempty(name.locality2)
            print(io,"/", name.locality2)
        end
    end
end

Base.convert(::Type{String}, name::SName) = string(name)
function Base.convert(::Type{SName}, str::AbstractString)
    name = try_convert(SName, str)
    name isa Nothing && DomainError(str, "All timezone name parts must have length < 16")
    return name
end

try_convert(::Type{SName}, name::SName) = name
try_convert(::Type{String}, name::String) = name
function try_convert(::Type{SName}, str::AbstractString)
    parts = split(str, "/"; limit=3)
    all(length(parts) < 16) ||return nothing
    return if length(parts) == 3
        SName(parts[1], parts[2], parts[3])
    elseif length(parts) == 2
        SName(parts[1], parts[2], ss15"")
    else
        SName(parts[1], ss15"", ss15"")
    end
end


Base.isempty(name::SName) = isempty(name.region)  # region being empty implies all empty

name_parts(str::AbstractString) = split(str, "/")
function name_parts(name::SName)
    # TODO this could be faster by returning an iterator but not really performance critial
    parts = [name.region]
    if !isempty(name.locality1)
        push!(parts, name.locality1)
        if !isempty(name.locality2)
            push!(parts, name.locality2)
        end
    end
    return parts
end

# Short strings are broken on 32bit:
# TODO: https://github.com/JuliaString/MurmurHash3.jl/issues/12
const Name = Int === Int32 ? String : SName
