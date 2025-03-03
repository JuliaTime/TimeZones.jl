using Base: @deprecate, depwarn

# BEGIN TimeZones 1.0 deprecations

@deprecate Dates.DateTime(zdt::ZonedDateTime, ::Type{Local}) DateTime(zdt) false
@deprecate Dates.Date(zdt::ZonedDateTime, ::Type{Local}) Date(zdt) false
@deprecate Dates.Time(zdt::ZonedDateTime, ::Type{Local}) Time(zdt) false

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
