import Base.Dates: Slot, AbstractTime, FixedWidthSlot, DelimitedSlot, DayOfWeekSlot, duplicates, getslot, periodisless

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


# DateTime Parsing

# Note: Ideally Base.Dates.Slot definition should just be: "abstract Slot{P<:Any}" which
# would allow for custom Slots to be of any type.
immutable TimeZoneSlot <: AbstractTime end

function Base.Dates.slotparse(slot::Slot{TimeZoneSlot},x)
    if slot.option == 1
        return ismatch(r"[\-\+\d\:]", x) ? FixedTimeZone(x): throw(SLOTERROR)
    elseif slot.option == 2
        # Note: TimeZones without the slash aren't well defined during parsing.
        return contains(x, "/") ? TimeZone(x) : throw(ArgumentError("Ambiguious timezone"))
    end
end

SLOT_TYPE = Dict(
    'y' => Year,
    'm' => Month,
    'u' => Month,
    'U' => Month,
    'E' => DayOfWeekSlot,
    'e' => DayOfWeekSlot,
    'd' => Day,
    'H' => Hour,
    'M' => Minute,
    'S' => Second,
    's' => Millisecond,
    'z' => TimeZoneSlot,
    'Z' => TimeZoneSlot,
)

SLOT_OPTION = Dict(
    'e' => 1,
    'E' => 2,
    'u' => 1,
    'U' => 2,
    'z' => 1,
    'Z' => 2,
)

# Overwritten to allow for extensibility.
function Base.Dates.DateFormat(f::AbstractString, locale::AbstractString="english")
    slots = Slot[]
    trans = []
    ids = join(keys(SLOT_TYPE), "")
    begtran, format = match(Regex("(^[^$ids]*)(.*)"), f).captures
    s = split(format, Regex("[^$ids]+|(?<=([$ids])(?!\\1))"))
    for (i,k) in enumerate(s)
        k == "" && break
        tran = i >= endof(s) ? r"$" : match(Regex("(?<=$(s[i])).*(?=$(s[i+1]))"),f).match
        slot = tran == "" ? FixedWidthSlot : DelimitedSlot
        width = length(k)
        c = k[1]
        typ = SLOT_TYPE[c]
        option = get(SLOT_OPTION, c, 0)
        push!(slots,slot(i,typ,width,option,locale))
        push!(trans,tran)
    end
    duplicates(slots) && throw(ArgumentError("Two separate periods of the same type detected"))
    return DateFormat(slots,begtran,trans)
end

# Overwritten to allow non-Period types to be returned.
function Base.Dates.parse(x::AbstractString,df::DateFormat)
    x = strip(replace(x, r"#.*$", ""))
    x = replace(x,df.begtran,"")
    isempty(x) && throw(ArgumentError("Cannot parse empty format string"))
    (typeof(df.slots[1]) <: DelimitedSlot && first(search(x,df.trans[1])) == 0) && throw(ArgumentError("Delimiter mismatch. Couldn't find first delimiter, \"$(df.trans[1])\", in date string"))
    periods = Period[]
    extra = []
    cursor = 1
    for slot in df.slots
        cursor, pe = getslot(x,slot,df,cursor)
        pe != nothing && isa(pe,Period) ? push!(periods,pe) : push!(extra,pe)
        cursor > endof(x) && break
    end
    return vcat(sort!(periods,rev=true,lt=periodisless), extra)
end
