using Base: @deprecate, @deprecate_binding
import Base: (:)

# BEGIN TimeZones 0.6 deprecations

# Only remove this deprecation when support for Julia 0.7 is dropped (JuliaLang/julia#24258)
if VERSION < v"1.0.0-DEV.44"
    @deprecate ((:)(start::T, stop::T) where {T <: ZonedDateTime}) start:Day(1):stop false
end

# END TimeZones 0.6 deprecations

# BEGIN TimeZones 0.9 deprecations

@deprecate build(version::AbstractString, regions; kwargs...) build(version; kwargs...) false

# END TimeZones 0.9 deprecations
