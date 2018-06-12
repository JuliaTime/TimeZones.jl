import Compat.Dates: DateFormat, DatePart, tryparsenext, format, min_width, max_width,
    default_format
using Compat: isletter

# Handle Nullable deprecation on Julia 0.7
if VERSION < v"0.7.0-DEV.3017"
    nullable(T::Type, x) = Nullable{T}(x)
else
    nullable(T::Type, x) = x  # Ignore nullable container type T
end

# https://github.com/JuliaLang/julia/pull/25261
if VERSION < v"0.7.0-DEV.5126"
    iterate(str::AbstractString, i::Int) = next(str, i)
end

function tryparsenext_fixedtz(str, i, len, min_width::Int=1, max_width::Int=0)
    tz_start, tz_end = i, 0
    min_pos = min_width <= 0 ? i : i + min_width - 1
    max_pos = max_width <= 0 ? len : min(chr2ind(str, ind2chr(str,i) + max_width - 1), len)
    state = 1
    @inbounds while i <= max_pos
        c, ii = iterate(str, i)::Tuple{Char, Int}
        if state == 1 && (c == '-' || c == '+')
            state = 2
            tz_end = i
        elseif (state == 1 || state == 2) && '0' <= c <= '9'
            state = 3
            tz_end = i
        elseif state == 3 && c == ':'
            state = 4
            tz_end = i
        elseif (state == 3 || state == 4) && '0' <= c <= '9'
            tz_end = i
        else
            break
        end
        i = ii
    end

    if tz_end <= min_pos
        return @static if VERSION < v"0.7.0-DEV.4797"
            nullable(String, nothing), i
        else
            nothing
        end
    else
        tz = SubString(str, tz_start, tz_end)
        return nullable(String, tz), i
    end
end

function tryparsenext_tz(str, i, len, min_width::Int=1, max_width::Int=0)
    tz_start, tz_end = i, 0
    min_pos = min_width <= 0 ? i : i + min_width - 1
    max_pos = max_width <= 0 ? len : min(chr2ind(str, ind2chr(str,i) + max_width - 1), len)
    @inbounds while i <= max_pos
        c, ii = iterate(str, i)::Tuple{Char, Int}
        if c == '/' || c == '_' || isletter(c)
            tz_end = i
        else
            break
        end
        i = ii
    end

    if tz_end == 0
        return @static if VERSION < v"0.7.0-DEV.4797"
            nullable(String, nothing), i
        else
            nothing
        end
    else
        name = SubString(str, tz_start, tz_end)

        # If the time zone is recognized make sure that it is well-defined. For our
        # purposes we'll treat all abbreviations except for UTC and GMT as ambiguous.
        # e.g. "MST": "Mountain Standard Time" (UTC-7) or "Moscow Summer Time" (UTC+3:31).
        if occursin("/", name) || name in ("UTC", "GMT")
            return nullable(String, name), i
        else
            return @static if VERSION < v"0.7.0-DEV.4797"
                nullable(String, nothing), i
            else
                nothing
            end
        end
    end
end

function tryparsenext(d::DatePart{'z'}, str, i, len)
    tryparsenext_fixedtz(str, i, len, min_width(d), max_width(d))
end

function tryparsenext(d::DatePart{'Z'}, str, i, len)
    tryparsenext_tz(str, i, len, min_width(d), max_width(d))
end

function format(io::IO, d::DatePart{'z'}, zdt, locale)
    write(io, string(zdt.zone.offset))
end

function format(io::IO, d::DatePart{'Z'}, zdt, locale)
    write(io, string(zdt.zone))  # In most cases will be an abbreviation.
end

# Note: ISOZonedDateTimeFormat is defined in the module __init__ which means that this
# function can not be called from within this module. TODO: Ignore linting for this line
function ZonedDateTime(str::AbstractString, df::DateFormat=ISOZonedDateTimeFormat)
    parse(ZonedDateTime, str, df)
end
function ZonedDateTime(str::AbstractString, format::AbstractString; locale::AbstractString="english")
    ZonedDateTime(str, DateFormat(format,locale))
end

default_format(::Type{ZonedDateTime}) = ISOZonedDateTimeFormat
