import Base.Dates: DateFormat, Slot, slotrule, slotparse, slotformat

Base.string(tz::TimeZone) = string(tz.name)
Base.show(io::IO,tz::VariableTimeZone) = print(io,string(tz))

function Base.string(dt::ZonedDateTime)
    v = offset(dt.zone).value
    h, v = divrem(v, 3600)
    m, s  = divrem(abs(v), 60)

    hh = @sprintf("%+03i", h)
    mm = lpad(m, 2, "0")
    ss = s != 0 ? lpad(s, 2, "0") : ""

    local_dt = localtime(dt)
    return "$local_dt$hh:$mm$(ss)"
end
Base.show(io::IO,dt::ZonedDateTime) = print(io,string(dt))

# NOTE: The changes below require Base.Dates to be updated to include slotrule.

# DateTime Parsing
const ISOZonedDateTimeFormat = DateFormat("yyyy-mm-ddTHH:MM:SS.szzz")

slotrule(::Type{Val{'z'}}) = TimeZone
slotrule(::Type{Val{'Z'}}) = TimeZone

function slotparse(slot::Slot{TimeZone},x,locale)
    if slot.letter == 'z'
        return ismatch(r"[\-\+\d\:]", x) ? FixedTimeZone(x): throw(SLOTERROR)
    elseif slot.letter == 'Z'
        # Note: TimeZones without the slash aren't well defined during parsing.
        return contains(x, "/") ? TimeZone(x) : throw(ArgumentError("Ambiguious timezone"))
    end
end

# TODO: Currently prints out the entire ZonedDateTime
slotformat(slot::Slot{TimeZone},x,locale) = string(x)

ZonedDateTime(dt::AbstractString,df::DateFormat=ISOZonedDateTimeFormat) = ZonedDateTime(Base.Dates.parse(dt,df)...)
ZonedDateTime(dt::AbstractString,format::AbstractString;locale::AbstractString="english") = ZonedDateTime(dt,DateFormat(format,locale))
