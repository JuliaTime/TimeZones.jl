import Base: print, show, showcompact
import Base.Dates: value, DateFormat, Slot, slotparse, slotformat, SLOT_RULE

print(io::IO, tz::TimeZone) = print(io, tz.name)
function print(io::IO, tz::FixedTimeZone)
    name = string(tz.name)
    isempty(name) ? print(io, "UTC", tz.offset) : print(io, name)
end
print(io::IO, zdt::ZonedDateTime) = print(io, localtime(zdt), zdt.zone.offset)

showcompact(io::IO, tz::TimeZone) = print(io, string(tz))

function show(io::IO, t::Transition)
    name_str = string(t.zone.name)
    print(io, t.utc_datetime, " ")
    show(io, t.zone.offset)
    !isempty(name_str) && print(io, " (", name_str, ")")
end

function show(io::IO, tz::FixedTimeZone)
    offset_str = "UTC" * offset_string(tz.offset, true)  # Use ISO 8601 for comparision
    name_str = string(tz.name)
    if isempty(name_str)
        print(io, offset_str)
    elseif name_str != offset_str && !(value(tz.offset) == 0 && name_str in ("UTC", "GMT"))
        print(io, name_str, " (UTC", offset_string(tz.offset), ")")
    else
        print(io, name_str)
    end
end

function show(io::IO,tz::VariableTimeZone)
    trans = tz.transitions

    # Retrieve the "modern" time zone transitions. We'll treat the latest transitions as
    # the same as the transitions for `now()` since these future transitions should be
    # based upon the same rules.
    if isnull(tz.cutoff) || length(trans) == 1
        trans = trans[end:end]
    else
        trans = trans[end-1:end]

        # Attempt to show a standard time offset before daylight saving time offset. Sorting
        # should work as long as the DST adjustment is always positive. Fixes differences
        # between the north and south hemispheres.
        sort!(trans, by=el -> el.zone.offset)
    end

    # Show standard time offset before daylight saving time offset.
    print(
        io,
        string(tz.name),
        " (", join(["UTC" * offset_string(t.zone.offset) for t in trans], "/"), ")",
    )
end

show(io::IO,dt::ZonedDateTime) = print(io, string(dt))

# NOTE: The changes below require Base.Dates to be updated to include slotrule.

# DateTime Parsing
SLOT_RULE['z'] = TimeZone
SLOT_RULE['Z'] = TimeZone

const ISOZonedDateTimeFormat = DateFormat("yyyy-mm-ddTHH:MM:SS.szzz")

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

ZonedDateTime(dt::AbstractString,df::DateFormat=ISOZonedDateTimeFormat) = ZonedDateTime(Base.Dates.parse(dt,df)...)
ZonedDateTime(dt::AbstractString,format::AbstractString;locale::AbstractString="english") = ZonedDateTime(dt,DateFormat(format,locale))
