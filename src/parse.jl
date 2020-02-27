using Dates: DateFormat, DatePart, min_width, max_width, tryparsenext_base10

function tryparsenext_fixedtz(str, i, len, min_width::Int=1, max_width::Int=0)
    i == len && str[i] == 'Z' && return ("Z", i+1)

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

function tryparsenext_fixedtz_alt(str::AbstractString, i::Int, len::Int, min_width::Int=1, max_width::Int=0)
    # TODO
    # min_pos = min_width <= 0 ? i : i + min_width - 1
    # max_pos = max_width <= 0 ? len : min(chr2ind(str, ind2chr(str,i) + max_width - 1), len)

    coefficient = 1
    hour = minute = second = 0

    i > len && @goto invalid

    # Optional offset sign
    c, ii = iterate(str, i)::Tuple{Char, Int}
    if c == 'Z'
        i = ii
        @goto zulu
    elseif c == '+' || c == '-'
        coefficient = c == '-' ? -1 : 1
        i = ii
        i > len && @goto invalid
    end

    # Hours
    let val = tryparsenext_base10(str, i, len)
        val === nothing && @goto invalid
        hour, i = val
        # (hour < -167 || hour > 167) && @goto invalid
        i > len && @goto done
    end

    c, ii = iterate(str, i)::Tuple{Char, Int}
    (c != ':' || ii > len) && @goto done
    i = ii

    # Minutes
    let val = tryparsenext_base10(str, i, len)
        val === nothing && @goto invalid
        minute, i = val
        # (minute < 0 || minute > 59) && @goto invalid
        i > len && @goto done
    end

    c, ii = iterate(str, i)::Tuple{Char, Int}
    (c != ':' || ii > len) && @goto done
    i = ii

    # Seconds
    let val = tryparsenext_base10(str, i, len)
        val === nothing && @goto invalid
        second, i = val
        # (second < 0 || second > 59) && @goto invalid
        i = ii
    end

    @label done
    offset = coefficient * (hour * 3600 + minute * 60 + second)
    name = if hour == 0 && minute == 0 && second == 0
        "UTC"
    elseif second == 0
        @sprintf("UTC%+03d:%02d", coefficient * hour, minute)
    else
        @sprintf("UTC%+03d:%02d:%02d", coefficient * hour, minute, second)
    end

    tz = FixedTimeZone(name, offset)
    return tz, i

    @label zulu
    return FixedTimeZone("Zulu", 0), i

    @label invalid
    return nothing
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

const PARSE_FAST = quote

function Base.parse(::Type{ZonedDateTime}, s::AbstractString, ::typeof(ISOZonedDateTimeFormat))
    i, end_pos = firstindex(s), lastindex(s)

    local dy, tz
    dm = dd = Int64(1)
    th = tm = ts = tms = Int64(0)

    let val = tryparsenext_base10(s, i, end_pos, 1)
        val === nothing && @goto error
        dy, i = val
        i > end_pos && @goto error
    end

    c, i = iterate(s, i)::Tuple{Char, Int}
    c != '-' && @goto error
    i > end_pos && @goto error

    let val = tryparsenext_base10(s, i, end_pos, 1, 2)
        val === nothing && @goto error
        dm, i = val
        i > end_pos && @goto error
    end

    c, i = iterate(s, i)::Tuple{Char, Int}
    c != '-' && @goto error
    i > end_pos && @goto error

    let val = tryparsenext_base10(s, i, end_pos, 1, 2)
        val === nothing && @goto error
        dd, i = val
        i > end_pos && @goto error
    end

    c, i = iterate(s, i)::Tuple{Char, Int}
    c != 'T' && @goto error
    i > end_pos && @goto error

    let val = tryparsenext_base10(s, i, end_pos, 1, 2)
        val === nothing && @goto error
        th, i = val
        i > end_pos && @goto error
    end

    c, i = iterate(s, i)::Tuple{Char, Int}
    c != ':' && @goto error
    i > end_pos && @goto error

    let val = tryparsenext_base10(s, i, end_pos, 1, 2)
        val === nothing && @goto error
        tm, i = val
        i > end_pos && @goto error
    end

    c, i = iterate(s, i)::Tuple{Char, Int}
    c != ':' && @goto error
    i > end_pos && @goto error

    let val = tryparsenext_base10(s, i, end_pos, 1, 2)
        val === nothing && @goto error
        ts, i = val
        i > end_pos && @goto error
    end

    c, i = iterate(s, i)::Tuple{Char, Int}
    c != '.' && @goto error
    i > end_pos && @goto error

    let val = tryparsenext_base10(s, i, end_pos, 1, 3)
        val === nothing && @goto error
        tms, j = val
        tms *= 10 ^ (3 - (j - i))
        i = j
        i > end_pos && @goto error
    end

    let val = tryparsenext_fixedtz_alt(s, i, end_pos, 1, 0)
        val === nothing && @goto error
        tz, i = val
        i > end_pos || @goto error
    end

    return ZonedDateTime(dy, dm, dd, th, tm, ts, tms, tz)

    @label error
    throw(ArgumentError("Invalid ZonedDateTime string"))
end

end
