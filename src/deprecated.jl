using Base: @deprecate

# BEGIN TimeZones 1.0 deprecations

@deprecate DateTime(zdt::ZonedDateTime, ::Type{Local}) DateTime(zdt)
@deprecate Date(zdt::ZonedDateTime, ::Type{Local}) Date(zdt)
@deprecate Time(zdt::ZonedDateTime, ::Type{Local}) Time(zdt)

const TZFILE_MAX = TZFile.TZFILE_CUTOFF
const TransitionTimeInfo = TZFile.TransitionTimeInfo
@deprecate abbreviation TZFile.get_designation false
@deprecate read_tzfile(io::IO, name::AbstractString) TZFile.read(io)(name) false

@deprecate build(; force=false) build(TZJData.TZDATA_VERSION; force)

# END TimeZones 1.0 deprecations
