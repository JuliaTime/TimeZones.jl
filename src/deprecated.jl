using Base: @deprecate

# BEGIN TimeZones 1.0 deprecations

@deprecate Dates.DateTime(zdt::ZonedDateTime, ::Type{Local}) DateTime(zdt)
@deprecate Dates.Date(zdt::ZonedDateTime, ::Type{Local}) Date(zdt)
@deprecate Dates.Time(zdt::ZonedDateTime, ::Type{Local}) Time(zdt)

# END TimeZones 1.0 deprecations
