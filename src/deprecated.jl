import Base: @deprecate, @deprecate_binding

if VERSION < v"0.7.0-DEV.4003"
    import Base: colon
else
    import Base: (:)
end

# BEGIN TimeZones 0.6 deprecations

# JuliaLang/julia#24258
if VERSION < v"0.7.0-DEV.2778"
    # Only remove this method when support for Julia 0.6 is dropped.
    colon(start::T, stop::T) where {T <: Localized} = start:Day(1):stop
elseif VERSION < v"0.7.0-DEV.4003"  # JuliaLang/julia#26074
    @deprecate colon(start::T, stop::T) where {T <: Localized} start:Day(1):stop  false
else
    # Only remove this deprecation when support for Julia 0.7 is dropped.
    @deprecate (:)(start::T, stop::T) where {T <: Localized}   start:Day(1):stop  false
end

@deprecate_binding ZonedDateTime Localized
@deprecate julian2zdt julian2localized
@deprecate zdt2julia localized2julian
@deprecate unix2zdt unix2localized
@deprecate zdt2unix localized2unix

# END TimeZones 0.6 deprecations
