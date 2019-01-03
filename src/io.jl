using Dates: value

Base.print(io::IO, tz::TimeZone) = print(io, tz.name)
function Base.print(io::IO, tz::FixedTimeZone)
    isempty(tz.name) ? print(io, "UTC", tz.offset) : print(io, tz.name)
end
Base.print(io::IO, zdt::ZonedDateTime) = print(io, localtime(zdt), zdt.zone.offset)

function Base.show(io::IO, t::Transition)
    print(io, t.utc_datetime, " ")
    show(io, t.zone.offset)
    !isempty(t.zone.name) && print(io, " (", t.zone.name, ")")
end

function Base.show(io::IO, tz::FixedTimeZone)
    if get(io, :compact, false)
        print(io, tz)
    else
        offset_str = "UTC" * offset_string(tz.offset, true)  # Use ISO 8601 for comparision
        if isempty(tz.name)
            print(io, offset_str)
        elseif tz.name != offset_str && !(value(tz.offset) == 0 && tz.name in ("UTC", "GMT"))
            print(io, tz.name, " (UTC", offset_string(tz.offset), ")")
        else
            print(io, tz.name)
        end
    end
end

function Base.show(io::IO, tz::VariableTimeZone)
    if get(io, :compact, false)
        print(io, tz)
    else
        trans = tz.transitions

        # Retrieve the "modern" time zone transitions. We'll treat the latest transitions as
        # the same as the transitions for `now()` since these future transitions should be
        # based upon the same rules.
        if tz.cutoff === nothing || length(trans) == 1
            trans = trans[end:end]
        else
            trans = trans[end-1:end]

            # Attempt to show a standard time offset before daylight saving time offset.
            # Sorting should work as long as the DST adjustment is always positive. Fixes
            # differences between the north and south hemispheres.
            sort!(trans, by=el -> el.zone.offset)
        end

        # Show standard time offset before daylight saving time offset.
        print(
            io,
            tz.name,
            " (", join(["UTC" * offset_string(t.zone.offset) for t in trans], "/"), ")",
        )
    end
end

Base.show(io::IO,dt::ZonedDateTime) = print(io, string(dt))
