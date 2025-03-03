using Base: @deprecate, depwarn

# Needed as `@deprecate` can't use qualified function calls
import Dates: DateTime, Date, Time

# BEGIN TimeZones 1.0 deprecations

@deprecate DateTime(zdt::ZonedDateTime, ::Type{Local}) DateTime(zdt)
@deprecate Date(zdt::ZonedDateTime, ::Type{Local}) Date(zdt)
@deprecate Time(zdt::ZonedDateTime, ::Type{Local}) Time(zdt)

const TZFILE_MAX = TZFile.TZFILE_CUTOFF
const TransitionTimeInfo = TZFile.TransitionTimeInfo
@deprecate abbreviation TZFile.get_designation false
@deprecate read_tzfile(io::IO, name::AbstractString) TZFile.read(io)(name) false

@deprecate build(; force=false) build(TZJData.TZDATA_VERSION; force)

function Dates.default_format(::Type{ZonedDateTime})
    depwarn(
        "`Dates.default_format(ZonedDateTime)` is deprecated and has no direct " *
        "replacement. Consider using refactoring to use " *
        "`parse(::Type{ZonedDateTime}, ::AbstractString)` as an alternative.",
        :default_format,
    )
    return ISOZonedDateTimeFormat
end

# END TimeZones 1.0 deprecations
