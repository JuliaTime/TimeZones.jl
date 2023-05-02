using Dates: value

function Base.print(io::IO, tz::FixedTimeZone)
    if get(io, :compact, true)
        isempty(tz.name) ? print(io, "UTC", tz.offset) : print(io, tz.name)
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

function Base.print(io::IO, tz::VariableTimeZone)
    if get(io, :compact, true)
        print(io, tz.name)
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

function Base.print(io::IO, t::Transition)
    print(io, t.utc_datetime, " ")
    show(io, MIME("text/plain"), t.zone.offset)  # Long-form
    !isempty(t.zone.name) && print(io, " (", t.zone.name, ")")
end

Base.print(io::IO, zdt::ZonedDateTime) = print(io, DateTime(zdt), zdt.zone.offset)


function Base.show(io::IO, tz::FixedTimeZone)
    if istimezone(tz.name, Class(:ALL)) && isequal(tz, TimeZone(tz.name, Class(:ALL)))
        print(io, "tz\"$(tz.name)\"")
    else
        std = Dates.value(tz.offset.std)
        dst = Dates.value(tz.offset.dst)

        # Always show `tz.name` as a regular `String`.
        params = [repr(String(tz.name)), repr(std)]
        dst != 0 && push!(params, repr(dst))
        print(io, FixedTimeZone, "(", join(params, ", "), ")")
    end
end

function Base.show(io::IO, tz::VariableTimeZone)
    # Compat printing when the time zone can be constructed with `@tz_str`
    if istimezone(tz.name, Class(:ALL)) && isequal(tz, TimeZone(tz.name, Class(:ALL)))
        print(io, "tz\"$(tz.name)\"")

    # Compact printing of a custom time zone which is non-constructable
    elseif get(io, :compact, false)
        print(io, VariableTimeZone, "(")
        show(io, tz.name)
        print(io, ", ...)")

    # Verbose printing which should print a fully constructable `VariableTimeZone`.
    else
        # Force `:compact => false` to make the force the transition vector printing into
        # long form.
        print(io, VariableTimeZone, "(")
        show(io, tz.name)
        print(io, ", ")
        show(IOContext(io, :compact => false), tz.transitions)
        print(io, ", ")
        show(io, tz.cutoff)
        print(io, ")")
    end
end

function Base.show(io::IO, t::Transition)
    if get(io, :compact, false)
        print(io, t)
    else
        # Fallback to calling the default show instead of reimplementing it.
        invoke(show, Tuple{IO, Any}, io, t)
    end
end

function Base.show(io::IO, zdt::ZonedDateTime)
    values = [
        yearmonthday(zdt)...
        hour(zdt)
        minute(zdt)
        second(zdt)
        millisecond(zdt)
    ]
    index = something(findlast(!iszero, values), 1)
    params = [
        map(repr, values[1:index]);
        repr(timezone(zdt); context=:compact => true)
    ]

    print(io, ZonedDateTime, "(", join(params, ", "), ")")
end


Base.show(io::IO, ::MIME"text/plain", t::Transition) = print(io, t)
Base.show(io::IO, ::MIME"text/plain", tz::TimeZone) = print(IOContext(io, :compact => false), tz)
Base.show(io::IO, ::MIME"text/plain", zdt::ZonedDateTime) = print(io, zdt)

# https://github.com/JuliaLang/julia/pull/33290
Base.typeinfo_implicit(::Type{ZonedDateTime}) = true
