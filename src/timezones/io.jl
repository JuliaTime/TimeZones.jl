import Base.Dates: value, DateFormat, Slot, slotparse, slotformat, SLOT_RULE

function Base.string(offset::Offset)
    v = value(Second(offset))
    h, v = divrem(v, 3600)
    m, s  = divrem(abs(v), 60)

    hh = @sprintf("%+03i", h)
    mm = lpad(m, 2, "0")
    ss = s != 0 ? lpad(s, 2, "0") : ""

    return "$hh:$mm$(ss)"
end

Base.string(tz::TimeZone) = string(tz.name)
Base.string(dt::ZonedDateTime) = "$(localtime(dt))$(string(dt.zone.offset))"

Base.show(io::IO,tz::VariableTimeZone) = print(io,string(tz))
Base.show(io::IO,dt::ZonedDateTime) = print(io,string(dt))

# NOTE: The changes below require Base.Dates to be updated to include slotrule.

# DateTime Parsing
const ISOZonedDateTimeFormat = DateFormat("yyyy-mm-ddTHH:MM:SS.szzz")

SLOT_RULE['z'] = TimeZone
SLOT_RULE['Z'] = TimeZone

function slotparse(slot::Slot{TimeZone},x,locale)
    if slot.letter == 'z'
        return ismatch(r"[\-\+\d\:]", x) ? FixedTimeZone(x): throw(SLOTERROR)
    elseif slot.letter == 'Z'
        # Note: TimeZones without the slash aren't well defined during parsing.
        return contains(x, "/") ? TimeZone(x) : throw(ArgumentError("Ambiguious timezone"))
    end
end

function slotformat(slot::Slot{TimeZone},zdt::ZonedDateTime,locale)
    if slot.letter == 'z'
        return string(zdt.zone.offset)
    elseif slot.letter == 'Z'
        return string(zdt.timezone.name)
    end
end

ZonedDateTime(dt::AbstractString,df::DateFormat=ISOZonedDateTimeFormat) = ZonedDateTime(Base.Dates.parse(dt,df)...)
ZonedDateTime(dt::AbstractString,format::AbstractString;locale::AbstractString="english") = ZonedDateTime(dt,DateFormat(format,locale))
