using Mocking
using Compat: stdout

"""
    timezone_names() -> Array{AbstractString}

Returns a sorted list of all of the valid names for constructing a `TimeZone`.
"""
function timezone_names()
    # Note: IANA time zone names are typically encoded only in ASCII.
    names = AbstractString[]
    check = Tuple{AbstractString,AbstractString}[(COMPILED_DIR, "")]

    for (dir, partial) in check
        for filename in readdir(dir)
            startswith(filename, ".") && continue

            path = joinpath(dir, filename)
            name = partial == "" ? filename : join([partial, filename], "/")

            if isdir(path)
                push!(check, (path, name))
            else
                push!(names, name)
            end
        end
    end

    return sort!(names)
end

"""
    all_timezones() -> Array{TimeZone}

Returns all pre-computed `TimeZone`s.
"""
function all_timezones()
    results = TimeZone[]
    for name in timezone_names()
        push!(results, TimeZone(name))
    end
    return results
end

"""
    all_timezones(criteria::Function) -> Array{TimeZone}

Returns `TimeZone`s that match the given `criteria` function. The `criteria` function takes
two parameters: UTC transition (`DateTime`) and transition zone (`FixedTimeZone`).

## Examples

Find all time zones which contain an absolute UTC offset greater than 15 hours:

```julia
all_timezones() do dt, zone
    abs(zone.offset.std) > Dates.Second(Dates.Hour(15))
end
```

Determine all time zones which have a non-hourly daylight saving time offset:

```julia
all_timezones() do dt, zone
    zone.offset.dst % Dates.Second(Dates.Hour(1)) != 0
end
```
"""
function all_timezones(criteria::Function)
    results = TimeZone[]
    for tz in all_timezones()
        if isa(tz, FixedTimeZone)
            criteria(typemin(DateTime), tz) && push!(results, tz)
        else
            for t in tz.transitions
                if criteria(t.utc_datetime, t.zone)
                    push!(results, tz)
                    break
                end
            end
        end
    end
    return results
end

"""
    timezones_from_abbr(abbr) -> Array{TimeZone}

Returns all `TimeZone`s that have the specified abbrevation
"""
function timezones_from_abbr end

function timezones_from_abbr(abbr::Symbol)
    results = TimeZone[]
    for tz in all_timezones()
        if isa(tz, FixedTimeZone)
            tz.name == abbr && push!(results, tz)
        else
            for t in tz.transitions
                if t.zone.name == abbr
                    push!(results, tz)
                    break
                end
            end
        end
    end
    return results
end
timezones_from_abbr(abbr::AbstractString) = timezones_from_abbr(Symbol(abbr))

"""
    timezone_abbrs -> Array{AbstractString}

Returns a sorted list of all pre-computed time zone abbrevations.
"""
function timezone_abbrs()
    abbrs = Set{AbstractString}()
    for tz in all_timezones()
        if isa(tz, FixedTimeZone)
            push!(abbrs, string(tz.name))
        else
            for t in tz.transitions
                push!(abbrs, string(t.zone.name))
            end
        end
    end
    return sort!(collect(abbrs))
end


"""
    next_transition_instant(zdt::ZonedDateTime) -> ZonedDateTime
    next_transition_instant(tz::TimeZone=localzone()) -> ZonedDateTime

Determine the next instant at which a time zone transition occurs (typically
due to daylight-savings time).

Note that the provided `ZonedDateTime` isn't normally constructable:

```julia
julia> instant = next_transition_instant(ZonedDateTime(2018, 3, 1, tz"Europe/London"))
2018-03-25T01:00:00+00:00

julia> instant - Millisecond(1)  # Instant prior to the change
2018-03-25T00:59:59.999+00:00

julia> instant - Millisecond(0)  # Instant after the change
2018-03-25T02:00:00+01:00

julia> ZonedDateTime(2018, 3, 25, 1, tz"Europe/London")  # Cannot normally construct the `instant`
ERROR: NonExistentTimeError: Local DateTime 2018-03-25T01:00:00 does not exist within Europe/London
...
```
"""
next_transition_instant

function next_transition_instant(zdt::ZonedDateTime)
    tz = zdt.timezone

    # Determine the index of the transition which occurs after the UTC datetime specified
    index = searchsortedfirst(
        tz.transitions, TimeZones.utc(zdt),
        by=el -> isa(el, TimeZones.Transition) ? el.utc_datetime : el,
    )

    # Use the UTC datetime of the transition and the offset information prior to the
    # transition to create a `ZonedDateTime` which cannot be constructed with the high-level
    # constructors. The instant constructed is equivalent to the first instant after the
    # transition but visually appears to be before the transition. For example in a
    # transition where the clock changes from 01:59 → 03:00 we would return 02:00 where
    # the UTC datetime of 02:00 == 03:00.
    utc_datetime = tz.transitions[index].utc_datetime
    prev_zone = tz.transitions[index - 1].zone
    ZonedDateTime(utc_datetime, tz, prev_zone)
end

next_transition_instant(tz::TimeZone=localzone()) = next_transition_instant(@mock now(tz))


"""
    show_next_transition(io::IO=stdout, zdt::ZonedDateTime)
    show_next_transition(io::IO=stdout, tz::TimeZone=localzone())

Display useful information about the next time zone transition (typically
due to daylight-savings time). Information displayed includes:

* Transition Date: the local date at which the transition occurs (2018-10-28)
* Local Time Change: the way the local clock with change (02:00 falls back to 01:00) and
    the direction of the change ("Forward" or "Backward")
* Offset Change: the standard offset and DST offset that occurs before and after the
   transition
* Transition From: the instant before the transition occurs
* Transition To: the instant after the transition occurs

```julia
julia> show_next_transition(ZonedDateTime(2018, 8, 1, tz"Europe/London"))
Transition Date:   2018-10-28
Local Time Change: 02:00 → 01:00 (Backward)
Offset Change:     UTC+0/+1 → UTC+0/+0
Transition From:   2018-10-28T01:59:59.999+01:00 (BST)
Transition To:     2018-10-28T01:00:00.000+00:00 (GMT)

julia> show_next_transition(ZonedDateTime(2011, 12, 1, tz"Pacific/Apia"))
Transition Date:   2011-12-30
Local Time Change: 00:00 → 00:00 (Forward)
Offset Change:     UTC-11/+1 → UTC+13/+1
Transition From:   2011-12-29T23:59:59.999-10:00
Transition To:     2011-12-31T00:00:00.000+14:00
```
"""
show_next_transition

function show_next_transition(io::IO, zdt::ZonedDateTime)
    instant = next_transition_instant(zdt)
    epsilon = eps(instant)
    from, to = instant - epsilon, instant + zero(epsilon)
    direction = value(to.zone.offset - from.zone.offset) < 0 ? "Backward" : "Forward"

    function zdt_format(zdt)
        name_suffix = string(zdt.zone.name)
        !isempty(name_suffix) && (name_suffix = string(" (", name_suffix, ")"))
        string(
            Dates.format(zdt, dateformat"yyyy-mm-ddTHH:MM:SS.sss"),
            zdt.zone.offset,  # Note: "zzz" will not work in the format above as is
            name_suffix,
        )
    end
    function time_format(zdt)
        Dates.format(zdt, second(zdt) == 0 ? dateformat"HH:MM" : dateformat"HH:MM:SS")
    end

    println(io, "Transition Date:   ", Dates.format(instant, dateformat"yyyy-mm-dd"))
    println(io, "Local Time Change: ", time_format(instant), " → ", time_format(to), " (", direction, ")")
    println(io, "Offset Change:     ", repr(from.zone.offset), " → ", repr(to.zone.offset))
    println(io, "Transition From:   ", zdt_format(from))
    println(io, "Transition To:     ", zdt_format(to))

end

function show_next_transition(io::IO, tz::TimeZone=localzone())
    show_next_transition(io, @mock now(tz))
end

show_next_transition(x...) = show_next_transition(stdout, x...)
