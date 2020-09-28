using Base: @deprecate

# BEGIN TimeZones 1.0 deprecations

@deprecate DateTime(zdt::ZonedDateTime, ::Type{Local}) DateTime(zdt)
@deprecate Date(zdt::ZonedDateTime, ::Type{Local}) Date(zdt)
@deprecate Time(zdt::ZonedDateTime, ::Type{Local}) Time(zdt)

# END TimeZones 1.0 deprecations
