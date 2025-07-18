using Dates: DateFormat, DatePart, min_width, max_width, tryparsenext_base10
using TimeZones.TZData: MIN_YEAR, MAX_YEAR

function init_dates_extension()
    Dates.CONVERSION_SPECIFIERS['z'] = TimeZone
    Dates.CONVERSION_SPECIFIERS['Z'] = TimeZone
    Dates.CONVERSION_DEFAULTS[TimeZone] = ""
    Dates.CONVERSION_TRANSLATIONS[ZonedDateTime] = (
        Year, Month, Day, Hour, Minute, Second, Millisecond, TimeZone,
    )
end

begin
    # Needs to be initialized to construct formats
    init_dates_extension()

    # Follows the ISO 8601 standard for date and time with an offset. See
    # `Dates.ISODateTimeFormat` for the `DateTime` equivalent.
    const ISOZonedDateTimeFormat = DateFormat("yyyy-mm-dd\\THH:MM:SS.ssszzz")
    const ISOZonedDateTimeNoMillisecondFormat = DateFormat("yyyy-mm-dd\\THH:MM:SSzzz")
end

@doc """
    DateFormat(format::AbstractString, locale="english") --> DateFormat

When the `TimeZones` package is loaded, 2 extra character codes are available
for constructing the `format` string:

| Code | Matches                    | Comment                                               |
|:-----|:---------------------------|:------------------------------------------------------|
| `z`  | +02:00, -0100, +14         | Parsing matches a fixed numeric UTC offset `±hh:mm`, `±hhmm`, or `±hh`. Formatting outputs `±hh:mm` |
| `Z`  | UTC, GMT, America/New_York | Name of a time zone as specified in the IANA tz database |
""" DateFormat

function Base.parse(::Type{ZonedDateTime}, str::AbstractString)
    # Works as the format should only contain a period when milliseconds are included
    return if contains(str, '.')
        parse(ZonedDateTime, str, ISOZonedDateTimeFormat)
    else
        parse(ZonedDateTime, str, ISOZonedDateTimeNoMillisecondFormat)
    end
end

function Base.parse(::Type{ZonedDateTime}, str::AbstractString, df::DateFormat)
    argtypes = Tuple{Type{<:TimeType},AbstractString,DateFormat}
    try
        invoke(parse, argtypes, ZonedDateTime, str, df)
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

# Supported fixed offset formats from UTC include. Most of these are ISO8601 time zone
# designators:
#
# - `Z`
# - `±hh:mm`
# - `±hhmm`
# - `±hh`
# - `hh:mm`
# - `hhmm`
#
# Normally the the `FixedTimeZone(::AbstractString)` constructor is responsible for
# converting the string output produced here into the Julia representation of a fixed time
# zone. Any further restrictions imposed by that constructor maybe should be reflected here.
function tryparsenext_fixedtz(str, i, len, min_width::Int=1, max_width::Int=0)
    tz_start, tz_end = i, 0
    min_pos = min_width <= 0 ? i : i + min_width - 1
    max_pos = max_width <= 0 ? len : min(nextind(str, 0, length(str, 1, i) + max_width - 1), len)
    state = :start
    has_sign = false
    num_digits = 0
    @inbounds while i <= max_pos
        c, ii = iterate(str, i)::Tuple{Char, Int}
        if state === :start && c === 'Z'
            tz_end = i
            break
        elseif state === :start && (c === '-' || c === '+')
            state = :hour
            has_sign = true
        elseif (state === :start || state === :hour) && '0' <= c <= '9'
            num_digits += 1
            if num_digits == 2
                state = :minute_or_colon
                has_sign && (tz_end = i)
            else
                state = :hour
            end
        elseif state === :minute_or_colon && c === ':'
            state = :minute
        elseif (state === :minute_or_colon || state === :minute) && '0' <= c <= '9'
            num_digits += 1
            if num_digits == 4
                tz_end = i
                break
            else
                state = :minute
            end
        else
            break
        end
        i = ii
    end

    if tz_end < min_pos
        return nothing
    else
        tz = SubString(str, tz_start, tz_end)
        return tz, nextind(str, tz_end)
    end
end

function tryparsenext_tz(str, i, len, min_width::Int=1, max_width::Int=0)
    tz_start, tz_end = i, 0
    min_pos = min_width <= 0 ? i : i + min_width - 1
    max_pos = max_width <= 0 ? len : min(nextind(str, 0, length(str, 1, i) + max_width - 1), len)
    state = :uppercase
    num_seq_digits = 0
    @inbounds while i <= max_pos
        c, ii = iterate(str, i)::Tuple{Char, Int}
        if state === :uppercase && isuppercase(c)
            state = :letter_or_symbol
            tz_end = i
        elseif (state === :letter_or_digit || state === :digit) && '0' <= c <= '9' && num_seq_digits < 2
            state = :digit
            num_seq_digits += 1  # Reset not required as we cannot leave the `:digit` state
            tz_end = i
        elseif state === :letter_or_symbol && c === '/'
            state = :uppercase
        elseif state === :letter_or_symbol && c === '_'
            state = :letter
        elseif state === :letter_or_symbol && c === '-'
            state = :letter_or_digit
        elseif state === :letter_or_symbol && c === '+'
            state = :digit
        elseif state in (:letter, :letter_or_digit, :letter_or_symbol) && isletter(c)
            state = :letter_or_symbol
            tz_end = i
        else
            break
        end
        i = ii
    end

    if tz_end < min_pos
        return nothing
    else
        name = SubString(str, tz_start, tz_end)

        # If the time zone is recognized make sure that it is well-defined. For our
        # purposes we'll treat all abbreviations except for UTC and GMT as ambiguous.
        # e.g. "MST": "Mountain Standard Time" (UTC-7) or "Moscow Summer Time" (UTC+3:31).
        if name == "UTC" || name == "GMT" || '/' in name
            return name, nextind(str, tz_end)
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

"""
    _parsesub_tzabbr(str, [i, len]) -> Union{Tuple{AbstractString, Integer}, Exception}

Parses a section of a string as a time zone abbreviation as defined in the tzset(3) man
page. An abbreviation must be at least three or more alphabetic characters. When enclosed by
the less-than (<) and greater-than (>) signs the character set is expanded to include the
plus (+) sign, the minus (-) sign, and digits.

# Examples
```jldoctest; setup = :(using TimeZones: _parsesub_tzabbr)
julia> _parsesub_tzabbr("ABC+1")
("ABC", 4)

julia> _parsesub_tzabbr("<ABC+1>+2")
("ABC+1", 8)
```
"""
function _parsesub_tzabbr(
    str::AbstractString,
    i::Integer=firstindex(str),
    len::Integer=lastindex(str),
)
    state = :started
    name_start = i
    name_end = prevind(str, i)

    @inbounds while i <= len
        c, ii = iterate(str, i)::Tuple{Char, Int}
        isascii(c) || break  # Restricts abbreviation support to ASCII characters

        if state == :simple && isletter(c)
            name_end = i
        elseif state == :expanded && (isletter(c) || isdigit(c) || c === '+' || c === '-')
            name_end = i
        elseif state == :started && c === '<'
            name_start = ii
            name_end = i
            state = :expanded
        elseif state == :started && isletter(c)
            name_end = i
            state = :simple
        elseif state == :expanded && c === '>'
            i = ii
            state = :closed
            break
        else
            break
        end
        i = ii
    end

    if state == :expanded
        return ParseNextError("Expected expanded time zone abbreviation end with the greater-than sign (>)", str, prevind(str, name_start), i)
    elseif state != :closed && name_start > name_end
        return ParseNextError("Time zone abbreviation must start with a letter or the less-than (<) character", str, i)
    elseif length(str, name_start, name_end) < 3
        char_type = if state == :simple
            "alphabetic characters"
        else
            "characters which are either alphanumeric, the plus sign (+), or the minus sign (-)"
        end

        return ParseNextError("Time zone abbreviation must be at least three $char_type", str, name_start, name_end)
    else
        name = SubString(str, name_start, name_end)
        return name, i
    end
end


"""
    _parsesub_offset(str, [i, len]) -> Union{Tuple{Integer, Integer}, Exception}

Parses a section of a string as an offset of the form `[+|-]hh[:mm[:ss]]`. The hour must be
between 0 and 24, and the minutes and seconds 00 and 59. This follows specification for
offsets as defined in the tzset(3) man page.

# Example
```jldoctest; setup = :(using TimeZones: _parsesub_offset)
julia> _parsesub_offset("1:0:0")
(3600, 6)

julia> _parsesub_offset("-0:1:2")
(-62, 7)
```
"""
function _parsesub_offset(
    str::AbstractString,
    i::Integer=firstindex(str),
    len::Integer=lastindex(str);
    name::AbstractString="offset",
)
    coefficient = 1
    hour = minute = second = 0

    if i > len
        return ParseNextError("Expected $name and instead found end of string", str, i)
    end

    # Optional sign
    c, ii = iterate(str, i)::Tuple{Char, Int}
    if c === '+' || c === '-'
        coefficient = c === '-' ? -1 : 1
        if ii > len
            return ParseNextError("$(uppercasefirst(name)) sign ($c) is not followed by a value", str, i)
        end
        i = ii
    end

    # Hours
    val = tryparsenext_base10(str, i, len)
    if val === nothing
        return ParseNextError("Expected $name hour digits", str, i)
    end
    hour, ii = val
    if hour < 0 || hour > 24
        return ParseNextError("Hours outside of expected range [0, 24]", str, i, prevind(str, ii))
    end
    i = ii
    i > len && @goto done

    c, ii = iterate(str, i)::Tuple{Char, Int}
    c !== ':' && @goto done
    i = ii

    # Minutes
    val = tryparsenext_base10(str, i, len)
    if val === nothing
        return ParseNextError("Expected $name minute digits after colon delimiter", str, i)
    end
    minute, ii = val
    if minute < 0 || minute > 59
        return ParseNextError("Minutes outside of expected range [0, 59]", str, i, prevind(str, ii))
    end
    i = ii
    i > len && @goto done

    c, ii = iterate(str, i)::Tuple{Char, Int}
    c !== ':' && @goto done
    i = ii

    # Seconds
    val = tryparsenext_base10(str, i, len)
    if val === nothing
        return ParseNextError("Expected $name second digits after colon delimiter", str, i)
    end
    second, ii = val
    if second < 0 || second > 59
        return ParseNextError("Seconds outside of expected range [0, 59]", str, i, prevind(str, ii))
    end
    i = ii

    @label done
    duration = coefficient * (hour * 3600 + minute * 60 + second)
    return duration, i
end

"""
    _parsesub_tzdate(str, [i, len]) -> Union{Tuple{Function, Integer}, Exception}

Parses a section of a string as a day of the year as defined in tzset(3). The return value
includes an anonymous function which takes the argument `year::Integer` and returns a
`Date`. The day of year includes these three supported formats:

  Jn      Specifies the Julian day where `n` is between 1 and 365. Leap days are not
          counted. In this format, February 29 can't be represented; February 28 is day 59,
          and March 1 is always day 60.

  n       Specifies the zero-based Julian day with `n` between 0 and 365. February 29 is
          counted in leap years. For non-leap years 365 is January 1 of the following year.

  Mm.w.d  Specifies day `d` (0 <= `d` <= 6) of week `w` (1 <= `w` <= 5) of month `m`
          (1 <= `m` <= 12). Week 1 is the first week in which day `d` occurs and week 5 is
          the last week in which day `d` occurs. Day 0 is a Sunday.

# Example
```jldoctest; setup = :(using TimeZones: _parsesub_tzdate)
julia> f, i = _parsesub_tzdate("J60");

julia> f.(2019:2020)
2-element Vector{Date}:
 2019-03-01
 2020-03-01

julia> f, i = _parsesub_tzdate("60");

julia> f.(2019:2020)
2-element Vector{Date}:
 2019-03-02
 2020-03-01

julia> f, i = _parsesub_tzdate("M3.3.0");  # Third Sunday in March

julia> f.(2019:2020)
2-element Vector{Date}:
 2019-03-17
 2020-03-15
```
"""
function _parsesub_tzdate(
    str::AbstractString,
    i::Integer=firstindex(str),
    len::Integer=lastindex(str),
)
    if i > len
        return ParseNextError("Expected date and instead found end of string", str, i)
    end

    # Detect prefix
    c, ii = iterate(str, i)::Tuple{Char, Int}

    if c === 'J'
        i = ii

        val = tryparsenext_base10(str, i, len)
        if val === nothing
            return ParseNextError("Expected to find number of Julian days", str, i)
        end
        days, ii = val
        if days < 1 || days > 365
            return ParseNextError("Julian days outside of expected range [1, 365]", str, i, ii)
        end
        i = ii

        # The `J` prefix denotes a day of year between 1 and 365. Leap days are not counted.
        # In this format, February 29 can't be represented; February 28 is day 59, and
        # March 1 is always day 60.
        f = function (year::Integer)
            d = days + (isleapyear(year) && days >= 60)
            Date(year, 1) + Day(d - 1)
        end
        return f, i

    elseif c === 'M'
        i = ii

        # Month
        val = tryparsenext_base10(str, i, len)
        if val === nothing
            return ParseNextError("Expected to find month", str, i)
        end
        month, ii = val
        if month < 1 || month > 12
            return ParseNextError("Month outside of expected range [1, 12]", str, i, ii)
        end
        i = ii

        c, ii = iterate(str, i)::Tuple{Char, Int}
        (c !== '.' || ii > len) && return ParseNextError("Expected to find delimiter (.)", str, i)
        i = ii

        # Week of month
        val = tryparsenext_base10(str, i, len)
        if val === nothing
            return ParseNextError("Expected to find week of month", str, i)
        end
        week_of_month, ii = val
        if week_of_month < 1 || week_of_month > 5
            return ParseNextError("Week of month outside of expected range [1, 5]", str, i, ii)
        end
        i = ii

        c, ii = iterate(str, i)::Tuple{Char, Int}
        (c !== '.' || ii > len) && return ParseNextError("Expected to find delimiter (.)", str, i)
        i = ii

        # Day of week
        val = tryparsenext_base10(str, i, len)
        if val === nothing
            return ParseNextError("Expected to find day of week", str, i)
        end
        day_of_week, ii = val
        if day_of_week < 0 || day_of_week > 6
            return ParseNextError("Day of week outside of expected range [0, 6]", str, i, ii)
        end
        i = ii

        # Convert to the Julia day-of-week used by `Dates.dayofweek`
        # Equivalent to: `dow = (dow - 7) % 7 + 7`
        day_of_week == 0 && (day_of_week = 7)

        f = function (year::Integer)
            date = Date(year, month, (week_of_month - 1) * 7 + 1)
            if week_of_month < 5
                step = Day(1)
            else
                date = lastdayofmonth(date)
                step = Day(-1)
            end
            tonext(d -> dayofweek(d) == day_of_week, date; step=step, same=true, limit=7)
        end

        return f, i
    else
        val = tryparsenext_base10(str, i, len)
        if val === nothing
            return ParseNextError("Expected to find number of Julian days", str, i)
        end
        days, ii = val
        if days < 0 || days > 365
            # Note: On non-leap years day 365 will be the first day of the next year. This
            # is only supported as the tzset(3) man page explicitly states that the
            # zero-based Julia day is between 0 and 365.
            return ParseNextError("Julian days outside of expected range [0, 365]", str, i, ii)
        end
        i = ii

        # No prefix specifies the zero-based day of year between 0 and 365. February 29 is
        # counted in leap years.
        days += 1

        f = (year::Integer) -> Date(year, 1) + Day(days - 1)
        return f, i
    end
end

"""
    _parsesub_time(str, [i, len]) -> Union{Tuple{Integer, Integer}, Exception}

Parses a section of a string as a time of the form `hh[:mm[:ss]]`. Primarily this function
is used to parse daylight saving transition times as outlined in tzset(3).
"""
function _parsesub_time(
    str::AbstractString,
    i::Integer=firstindex(str),
    len::Integer=lastindex(str);
    name::AbstractString="time",
)
    if i > len
        return ParseNextError("Expected $name and instead found end of string", str, i)
    end

    # Require time does not start with a sign.
    c, ii = iterate(str, i)::Tuple{Char, Int}
    if c === '+' || c === '-'
        return ParseNextError("$(uppercasefirst(name)) should not have a sign", str, i)
    end

    return _parsesub_offset(str, i, len; name=name)
end

"""
    _parsesub_tz(str, [i, len]) -> Union{Tuple{TimeZone, Integer}, Exception}

Parse a direct representation of a time zone as specified by the tzset(3) man page.

# Examples
```jldoctest; setup = :(using TimeZones: _parsesub_tz)
julia> first(_parsesub_tz("EST+5"))
EST (UTC-5)

julia> first(_parsesub_tz("NZST-12:00:00NZDT-13:00:00,M10.1.0,M3.3.0"))
NZST/NZDT (UTC+12/UTC+13)
"""
function _parsesub_tz(
    str::AbstractString,
    i::Integer=firstindex(str),
    len::Integer=lastindex(str),
)
    # An empty or unset TZ environmental variable defaults to UTC
    if len == 0
        return FixedTimeZone("UTC"), i
    end

    x = _parsesub_tzabbr(str, i, len)
    if x isa Tuple
        std_name, i = x
    else
        return x
    end

    x = _parsesub_offset(str, i, len; name="standard offset")
    if x isa Tuple
        std_offset, i = x
    else
        return x
    end

    if i <= len
        x = _parsesub_tzabbr(str, i, len)
        if x isa Tuple
            dst_name, i = x
        else
            return x
        end
    else
        dst_name = nothing
    end

    dst_offset = nothing
    if dst_name !== nothing
        iter = iterate(str, i)
        if iter !== nothing && first(iter) !== ','
            x = _parsesub_offset(str, i, len; name="daylight saving offset")
            if x isa Tuple
                dst_offset, i = x
            else
                return x
            end
        else
            dst_offset = std_offset - 3600
        end
    end

    start_dst = first(_parsesub_tzdate("M3.2.0"))::Function  # Second Sunday in March
    end_dst = first(_parsesub_tzdate("M11.1.0"))::Function   # First Sunday in November

    start_time = end_time = Hour(2)  # 02:00
    if i <= len
        c, ii = iterate(str, i)::Tuple{Char, Int}
        if c !== ','
            return ParseNextError("Expected to find delimiter (,)", str, i)
        end
        i = ii

        # Daylight saving goes into effect
        x = _parsesub_tzdate(str, i, len)
        if x isa Tuple
            start_dst, i = x
        else
            return ParseNextError(
                "Unable to parse daylight saving start date. $(x.msg)",
                x.str, x.s, x.e,
            )
        end
        i > len && return ParseNextError("Expected to find daylight saving end and instead found end of string", str, i)

        c, ii = iterate(str, i)::Tuple{Char, Int}
        if c !== '/' && c !== ','
            return ParseNextError("Expected to find delimiter (,) or (/)", str, i)
        end
        i = ii

        if c === '/'
            x = _parsesub_time(str, i, len; name="daylight saving start time")
            if x isa Tuple
                start_time, i = x
                start_time = Second(start_time)
            else
                return x
            end
            i > len && return ParseNextError("Expected to find daylight saving end and instead found end of string", str, i)

            c, ii = iterate(str, i)::Tuple{Char, Int}
            if c !== ','
                return ParseNextError("Expected to find delimiter (,)", str, i)
            end
            i = ii
        end

        x = _parsesub_tzdate(str, i, len)
        if x isa Tuple
            end_dst, i = x
        else
            return ParseNextError(
                "Unable to parse daylight saving end date. $(x.msg)",
                x.str, x.s, x.e,
            )
        end

        if i <= len
            c, ii = iterate(str, i)::Tuple{Char, Int}
            if c !== '/'
                return ParseNextError("Expected to find delimiter (/)", str, i)
            end
            i = ii

            x = _parsesub_time(str, i, len; name="daylight saving end time")
            if x isa Tuple
                end_time, i = x
                end_time = Second(end_time)
            else
                return x
            end
        end
    end

    # "The offset is positive if the local timezone is west of the Prime Meridian and
    # negative if it is east". As this is the opposite of our internal representation we
    # have to negate the values.
    # e.g. "STD+1DST+2" results in a timezone with a std/dst offset of UTC-1/UTC-2
    std = FixedTimeZone(std_name, -std_offset)

    # Note: Most of the parsing time is spent creating the `VariableTimeZone`. The way I
    # would like to address this is by introducing a new `TimeZone` subtype which
    # dynamically calculates the transitions.
    tz = if dst_offset !== nothing
        dst = FixedTimeZone(dst_name, -std_offset, -(dst_offset - std_offset))

        transitions = Transition[]
        for year in 1900:MAX_YEAR
            # Note: "The offset specifies the time value to be added to the local time to get
            # Coordinated Universal Time (UTC)".
            utc_dst = DateTime(start_dst(year)) + start_time + Second(std_offset)
            utc_std = DateTime(end_dst(year)) + end_time + Second(dst_offset)

            append!(
                transitions,
                [
                    Transition(utc_dst, dst),
                    Transition(utc_std, std),
                ]
            )
        end
        sort!(transitions)

        cutoff_year = MAX_YEAR + 1
        utc_dst = DateTime(start_dst(cutoff_year)) + start_time + Second(std_offset)
        utc_std = DateTime(end_dst(cutoff_year)) + end_time + Second(dst_offset)
        cutoff = min(utc_dst, utc_std)

        # TODO: Ideally we would use a new TimeZone subtype which computes transitions
        # on-the-fly using the functions we provided.
        VariableTimeZone("$std_name/$dst_name", transitions, cutoff)
    else
        std
    end

    return tz, i
end
