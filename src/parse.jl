using Dates: DateFormat, DatePart, min_width, max_width

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
        return nothing
    else
        tz = SubString(str, tz_start, tz_end)
        return tz, i
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
        return nothing
    else
        name = SubString(str, tz_start, tz_end)

        # If the time zone is recognized make sure that it is well-defined. For our
        # purposes we'll treat all abbreviations except for UTC and GMT as ambiguous.
        # e.g. "MST": "Mountain Standard Time" (UTC-7) or "Moscow Summer Time" (UTC+3:31).
        if occursin("/", name) || name in ("UTC", "GMT")
            return name, i
        else
            return nothing
        end
    end
end

function Dates.tryparsenext(d::DatePart{'z'}, str, i, len)
    tryparsenext_fixedtz(str, i, len, min_width(d), max_width(d))
end

function Dates.tryparsenext(d::DatePart{'Z'}, str, i, len)
    tryparsenext_tz(str, i, len, min_width(d), max_width(d))
end

function Dates.format(io::IO, d::DatePart{'z'}, zdt, locale)
    write(io, string(zdt.zone.offset))
end

function Dates.format(io::IO, d::DatePart{'Z'}, zdt, locale)
    write(io, string(zdt.zone))  # In most cases will be an abbreviation.
end

# Note: ISOZonedDateTimeFormat is defined in the module __init__ which means that this
# function can not be called from within this module. TODO: Ignore linting for this line
function ZonedDateTime(str::AbstractString, df::DateFormat=ISOZonedDateTimeFormat)
    try
        parse(ZonedDateTime, str, df)
    catch e
        if e isa ArgumentError
            rethrow(ArgumentError(
                "Unable to parse string \"$str\" using format $df. $(e.msg)"
            ))
        else
            rethrow()
        end
    end
end

function ZonedDateTime(str::AbstractString, format::AbstractString; locale::AbstractString="english")
    ZonedDateTime(str, DateFormat(format, locale))
end

Dates.default_format(::Type{ZonedDateTime}) = ISOZonedDateTimeFormat
