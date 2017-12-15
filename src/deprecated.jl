import Base: @deprecate, @deprecate_binding, colon

# BEGIN TimeZones 0.4 deprecations

import TimeZones.TZData: REGIONS, LEGACY_REGIONS

# We forgot to remove these deprecates during the switch to 0.5
@deprecate_binding Olson TZData
@deprecate_binding TZDATA_DIR TZ_SOURCE_DIR

# END TimeZones 0.4 deprecations

# BEGIN TimeZones 0.5 deprecations
# END TimeZones 0.5 deprecations

# JuliaLang/julia#24258
if VERSION < v"0.7.0-DEV.2778"
    # Only remove this method when support for Julia 0.6 is dropped.
    colon(start::T, stop::T) where {T<:ZonedDateTime} = start:Day(1):stop
else
    # Only remove this deprecation when support for Julia 0.7 is dropped.
    @deprecate colon(start::T, stop::T) where {T<:ZonedDateTime}   start:Day(1):stop   false
end
