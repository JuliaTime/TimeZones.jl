const TZ_ABBR_MAX = 6

"""
    TimeZoneAbbr

A three to six character string containing only ASCII alphanumerics, '+', and '-'.

# https://data.iana.org/time-zones/theory.html#abbreviations
"""
struct TZAbbr <: AbstractString
    chars::NTuple{TZ_ABBR_MAX, UInt8}
end

function TZAbbr(str::AbstractString)
    if length(str) > TZ_ABBR_MAX
        throw(ArgumentError("String length ($(length(str)) exceeds maximum abbreviation length ($TZ_ABBR_MAX)"))
    end
    chars = fill(tz_abbr_encode('\0'), TZ_ABBR_MAX)
    i = 1
    for c in str
        chars[i] = tz_abbr_encode(c)
        i += 1
    end
    return TZAbbr(Tuple(chars))
end

Base.iterate(a::TZAbbr) = iterate(a, 1)

function Base.iterate(a::TZAbbr, i::Int)
    i > TZ_ABBR_MAX && return nothing
    c = tz_abbr_decode(a.chars[i])
    c == '\0' && return nothing
    return c, i + 1
end

function Base.ncodeunits(a::TZAbbr)
    i = 0
    for v in a.chars
        c = tz_abbr_decode(v)
        c == '\0' && return i
        i += 1
    end
    return i
end

Base.codeunit(a::TZAbbr) = UInt8
Base.codeunit(a::TZAbbr, i::Integer) = tz_abbr_decode(a.chars[i])
Base.isvalid(a::TZAbbr, i::Integer) = tz_abbr_decode(a.chars[i]) != '\0'
Base.sizeof(::TZAbbr) = TZ_ABBR_MAX

function tz_abbr_decode(v::UInt8)
    c = if v == UInt8(0)
        '\0'
    elseif v <= UInt8(26)  # A-Z
        'A' + v - 1
    elseif v <= UInt8(52)  # a-z
        'a' + v - 27
    elseif v <= UInt8(62)  # 0-9
        '0' + v - 53
    elseif v == UInt8(63)
        '+'
    elseif v == UInt8(64)
        '-'
    else
        throw(ArgumentError("Decoding for $(repr(v)) is undefined and reserved for future use"))
    end

    return c
end

function tz_abbr_encode(c::Char)
    v = if c == '\0'
        UInt8(0)
    elseif 'A' <= c <= 'Z'
        UInt8(c - 'A' + 1)
    elseif 'a' <= c <= 'z'
        UInt8(c - 'a' + 27)
    elseif '0' <= c <= '9'
        UInt8(c - '0' + 53)
    elseif c == '+'
        UInt8(63)
    elseif c == '-'
        UInt8(64)
    else
        throw(ArgumentError("Character $(repr(c)) does not have a defined TZAbbr encoding"))
    end

    return v
end
