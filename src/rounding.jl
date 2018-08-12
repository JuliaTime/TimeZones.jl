import Compat.Dates: Period, DatePeriod, TimePeriod

function Base.floor(ldt::Localized, p::DatePeriod)
    return Localized(floor(localtime(ldt), p), timezone(ldt))
end

function Base.floor(ldt::Localized, p::TimePeriod)
    # Rounding is done using the current fixed offset to avoid transitional ambiguities.
    dt = floor(localtime(ldt), p)
    utc_dt = dt - ldt.zone.offset
    return Localized(utc_dt, timezone(ldt); from_utc=true)
end

function Base.ceil(ldt::Localized, p::DatePeriod)
    return Localized(ceil(localtime(ldt), p), timezone(ldt))
end

#function Dates.floorceil(ldt::Localized, p::Dates.DatePeriod)
    #return floor(ldt, p), ceil(ldt, p)
#end

"""
    floor(ldt::Localized, p::Period) -> Localized
    floor(ldt::Localized, p::Type{Period}) -> Localized

Returns the nearest `Localized` less than or equal to `ldt` at resolution `p`. The
result will be in the same time zone as `ldt`.

For convenience, `p` may be a type instead of a value: `floor(ldt, Dates.Hour)` is a
shortcut for `floor(ldt, Dates.Hour(1))`.

`VariableTimeZone` transitions are handled as for `round`.

### Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```julia
julia> ldt = Localized(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg"))
2016-03-13T01:45:00-06:00

julia> floor(ldt, Dates.Day)
2016-03-13T00:00:00-06:00

julia> floor(ldt, Dates.Hour)
2016-03-13T01:00:00-06:00
```
"""
Base.floor(::TimeZones.Localized, ::Union{Period, Type{Period}})

"""
    ceil(ldt::Localized, p::Period) -> Localized
    ceil(ldt::Localized, p::Type{Period}) -> Localized

Returns the nearest `Localized` greater than or equal to `ldt` at resolution `p`.
The result will be in the same time zone as `ldt`.

For convenience, `p` may be a type instead of a value: `ceil(ldt, Dates.Hour)` is a
shortcut for `ceil(ldt, Dates.Hour(1))`.

`VariableTimeZone` transitions are handled as for `round`.

### Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```julia
julia> ldt = Localized(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg"))
2016-03-13T01:45:00-06:00

julia> ceil(ldt, Dates.Day)
2016-03-14T00:00:00-05:00

julia> ceil(ldt, Dates.Hour)
2016-03-13T03:00:00-05:00
```
"""
Base.ceil(::TimeZones.Localized, ::Union{Period, Type{Period}})

"""
    round(ldt::Localized, p::Period, [r::RoundingMode]) -> Localized
    round(ldt::Localized, p::Type{Period}, [r::RoundingMode]) -> Localized

Returns the `Localized` nearest to `ldt` at resolution `p`. The result will be in the
same time zone as `ldt`. By default (`RoundNearestTiesUp`), ties (e.g., rounding 9:30 to the
nearest hour) will be rounded up.

For convenience, `p` may be a type instead of a value: `round(ldt, Dates.Hour)` is a
shortcut for `round(ldt, Dates.Hour(1))`.

Valid rounding modes for `round(::TimeType, ::Period, ::RoundingMode)` are
`RoundNearestTiesUp` (default), `RoundDown` (`floor`), and `RoundUp` (`ceil`).

### `VariableTimeZone` Transitions

Instead of performing rounding operations on the `Localized`'s internal UTC `DateTime`,
which would be computationally less expensive, rounding is done in the local time zone.
This ensures that rounding behaves as expected and is maximally meaningful.

If rounding were done in UTC, consider how rounding to the nearest day would be resolved for
non-UTC time zones: the result would be 00:00 UTC, which wouldn't be midnight local time.
Similarly, when rounding to the nearest hour in `Australia/Eucla (UTC+08:45)`, the result
wouldn't be on the hour in the local time zone.

When `p` is a `DatePeriod` rounding is done in the local time zone in a straightforward
fashion. When `p` is a `TimePeriod` the likelihood of encountering an ambiguous or
non-existent time (due to daylight saving time transitions) is increased. To resolve this
issue, rounding a `Localized` with a `VariableTimeZone` to a `TimePeriod` uses the
`DateTime` value in the appropriate `FixedTimeZone`, then reconverts it to a `Localized`
in the appropriate `VariableTimeZone` afterward.

Rounding is not an entirely "safe" operation for `Localized`s, as in some cases
historical transitions for some time zones (such as `Asia/Colombo`) occur at midnight. In
such cases rounding to a `DatePeriod` may still result in an `AmbiguousTimeError` or a
`NonExistentTimeError`. (But these events should be relatively rare.)

Regular daylight saving time transitions should be safe.

### Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```julia
julia> ldt = Localized(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg"))
2016-03-13T01:45:00-06:00

julia> round(ldt, Dates.Hour)
2016-03-13T03:00:00-05:00

julia> round(ldt, Dates.Day)
2016-03-13T00:00:00-06:00
```

The `Asia/Colombo` time zone revised the definition of Lanka Time from UTC+6:30 to UTC+6:00
on 1996-10-26, moving from 00:29:59 back to 00:00:00.

```julia
julia> ldt = Localized(1996, 10, 25, 23, 45, TimeZone("Asia/Colombo"))
1996-10-25T23:45:00+06:30

julia> round(ldt, Dates.Hour)
1996-10-26T00:00:00+06:30

julia> round(ldt, Dates.Day)
ERROR: Local DateTime 1996-10-26T00:00:00 is ambiguous
```
"""     # Defined in base/dates/rounding.jl
Base.round(::TimeZones.Localized, ::Union{Period, Type{Period}})
