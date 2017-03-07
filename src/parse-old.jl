import Base: parse
import Base.Dates: Slot, slotparse, slotformat

function slotparse(slot::Slot{TimeZone},x,locale)
    if slot.letter == 'z'
        # TODO: Should 'z' only parse numeric UTC offsets? e.g. disallow "UTC-7"
        if ismatch(r"\d", x)
            return FixedTimeZone(x)
        else
            throw(ArgumentError("Time zone offset contains no digits"))
        end
    elseif slot.letter == 'Z'
        # First attempt to create a timezone from the string. An error will be thrown if the
        # time zone is unrecognized.
        tz = TimeZone(x)

        # If the time zone is recognized make sure that it is well-defined. For our purposes
        # we'll treat all abbreviations except for UTC and GMT as ambiguous.
        # e.g. "MST": "Mountain Standard Time" (UTC-7) or "Moscow Summer Time" (UTC+3:31).
        if contains(x, "/") || x in ("UTC", "GMT")
            return tz
        else
            throw(ArgumentError("Time zone is ambiguous"))
        end
    end
end

function slotformat(slot::Slot{TimeZone},zdt::ZonedDateTime,locale)
    if slot.letter == 'z'
        return string(zdt.zone.offset)
    elseif slot.letter == 'Z'
        return string(zdt.zone)  # In most cases will be an abbreviation.
    end
end

function parse(::Type{ZonedDateTime}, str::AbstractString, df::DateFormat)
    ZonedDateTime(Base.Dates.parse(str, df)...)
end

# Note: ISOZonedDateTimeFormat is defined in the module __init__ which means that this
# function can not be called from within this module. TODO: Ignore linting for this line
function ZonedDateTime(str::AbstractString, df::DateFormat=ISOZonedDateTimeFormat)
    parse(ZonedDateTime, str, df)
end
function ZonedDateTime(str::AbstractString, format::AbstractString; locale::AbstractString="english")
    parse(ZonedDateTime, str, DateFormat(format, locale))
end
