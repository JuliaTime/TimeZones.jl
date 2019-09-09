using Base: @deprecate, @deprecate_binding

# BEGIN TimeZones 0.9 deprecations

@deprecate build(version::AbstractString, regions; kwargs...) build(version; kwargs...) false

# END TimeZones 0.9 deprecations
