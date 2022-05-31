using Base: @deprecate

# BEGIN TimeZones 1.0 deprecations

@deprecate DateTime(zdt::ZonedDateTime, ::Type{Local}) DateTime(zdt)
@deprecate Date(zdt::ZonedDateTime, ::Type{Local}) Date(zdt)
@deprecate Time(zdt::ZonedDateTime, ::Type{Local}) Time(zdt)

const TZFILE_MAX = TZFile.TZFILE_CUTOFF
const TransitionTimeInfo = TZFile.TransitionTimeInfo
@deprecate abbreviation TZFile.abbreviation false
@deprecate read_tzfile TZFile.read_tzfile false

# END TimeZones 1.0 deprecations
