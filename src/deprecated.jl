using Base: @deprecate

# BEGIN TimeZones 1.0 deprecations

@deprecate localtime(zdt::ZonedDateTime) DateTime(zdt, Local) false
@deprecate utc(zdt::ZonedDateTime) DateTime(zdt, UTC) false
@deprecate DateTime(zdt::ZonedDateTime) DateTime(zdt, Local)

# END TimeZones 1.0 deprecations
