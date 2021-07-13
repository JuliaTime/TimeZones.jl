struct ExternalField{T}
    table::Dict{T,Int}
    data::Vector{T}
end

ExternalField{T}() where T = ExternalField{T}(Dict{T,Int}(), Vector{T}())

function add!(x::ExternalField{T}, val::T) where T
    get!(x.table, val) do
        push!(x.data, val)
        lastindex(x.data)
    end
end

Base.getindex(x::ExternalField, i::Int) = x.data[i]
