import Base: string, show, showcompact
import Base.Dates: value, DateFormat, Slot, slotparse, slotformat, SLOT_RULE

string(tz::TimeZone) = string(tz.name)
string(tz::FixedTimeZone) = (s = string(tz.name); isempty(s) ? "UTC" * string(tz.offset) : s)
string(dt::ZonedDateTime) = string(localtime(dt), string(dt.zone.offset))

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
        return ismatch(r"[\-\+\d\:]", x) ? FixedTimeZone(x): throw(SLOTERROR)
    elseif slot.letter == 'Z'
        # Note: TimeZones without the slash aren't well defined during parsing.
        return contains(x, "/") ? TimeZone(x) : throw(ArgumentError("Ambiguous time zone"))
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
