import Base.Dates: DateFormat, DatePart, tryparsenext, format, min_width, max_width

function tryparsenext_fixedtz(str, i, len, min_width::Int=1, max_width::Int=0)
    tz_start, tz_end = i, 0
    min_pos = min_width <= 0 ? i : i + min_width - 1
    max_pos = max_width <= 0 ? len : min(chr2ind(str, ind2chr(str,i) + max_width - 1), len)
    state = 1
    @inbounds while i <= max_pos
        c, ii = next(str, i)
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
        return Nullable{String}(), i
    else
        tz = SubString(str, tz_start, tz_end)
        return Nullable{String}(tz), i
    end
end

function tryparsenext_tz(str, i, len, min_width::Int=1, max_width::Int=0)
    tz_start, tz_end = i, 0
    min_pos = min_width <= 0 ? i : i + min_width - 1
    max_pos = max_width <= 0 ? len : min(chr2ind(str, ind2chr(str,i) + max_width - 1), len)
    @inbounds while i <= max_pos
        c, ii = next(str, i)
        if c == '/' || c == '_' || isalpha(c)
            tz_end = i
        else
            break
        end
        i = ii
    end

    if tz_end == 0
        return Nullable{String}(), i
    else
        name = SubString(str, tz_start, tz_end)

        # If the time zone is recognized make sure that it is well-defined. For our
        # purposes we'll treat all abbreviations except for UTC and GMT as ambiguous.
        # e.g. "MST": "Mountain Standard Time" (UTC-7) or "Moscow Summer Time" (UTC+3:31).
        if contains(name, "/") || name in ("UTC", "GMT")
            return Nullable{String}(name), i
        else
            return Nullable{String}(), i
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
