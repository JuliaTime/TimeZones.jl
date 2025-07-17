using Base: @deprecate, depwarn

# BEGIN TimeZones 1.0 deprecations

# https://github.com/JuliaLang/julia/pull/44394
@static if VERSION < v"1.9.0-DEV.663"
    import Dates: DateTime, Date, Time
    @deprecate DateTime(zdt::ZonedDateTime, ::Type{Local}) DateTime(zdt) false
    @deprecate Date(zdt::ZonedDateTime, ::Type{Local}) Date(zdt) false
    @deprecate Time(zdt::ZonedDateTime, ::Type{Local}) Time(zdt) false
else
    @deprecate Dates.DateTime(zdt::ZonedDateTime, ::Type{Local}) DateTime(zdt) false
    @deprecate Dates.Date(zdt::ZonedDateTime, ::Type{Local}) Date(zdt) false
    @deprecate Dates.Time(zdt::ZonedDateTime, ::Type{Local}) Time(zdt) false
end

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
