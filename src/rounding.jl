using Dates: Period, DatePeriod, TimePeriod

function Base.floor(zdt::ZonedDateTime, p::DatePeriod)
    return ZonedDateTime(floor(DateTime(zdt), p), timezone(zdt))
end

function Base.floor(zdt::ZonedDateTime, p::TimePeriod)
    # Rounding is done using the current fixed offset to avoid transitional ambiguities.
    dt = floor(DateTime(zdt), p)
    utc_dt = dt - zdt.zone.offset
    return ZonedDateTime(utc_dt, timezone(zdt); from_utc=true)
end

function Base.ceil(zdt::ZonedDateTime, p::DatePeriod)
    return ZonedDateTime(ceil(DateTime(zdt), p), timezone(zdt))
end

#function Dates.floorceil(zdt::ZonedDateTime, p::Dates.DatePeriod)
    #return floor(zdt, p), ceil(zdt, p)
#end

"""
    floor(zdt::ZonedDateTime, p::Period) -> ZonedDateTime
    floor(zdt::ZonedDateTime, p::Type{Period}) -> ZonedDateTime

Returns the nearest `ZonedDateTime` less than or equal to `zdt` at resolution `p`. The
result will be in the same time zone as `zdt`.

For convenience, `p` may be a type instead of a value: `floor(zdt, Dates.Hour)` is a
shortcut for `floor(zdt, Dates.Hour(1))`.

`VariableTimeZone` transitions are handled as for `round`.

### Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```julia
julia> zdt = ZonedDateTime(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg"))
2016-03-13T01:45:00-06:00

julia> floor(zdt, Dates.Day)
2016-03-13T00:00:00-06:00

julia> floor(zdt, Dates.Hour)
2016-03-13T01:00:00-06:00
```
"""
Base.floor(::TimeZones.ZonedDateTime, ::Union{Period, Type{Period}})

"""
    ceil(zdt::ZonedDateTime, p::Period) -> ZonedDateTime
    ceil(zdt::ZonedDateTime, p::Type{Period}) -> ZonedDateTime

Returns the nearest `ZonedDateTime` greater than or equal to `zdt` at resolution `p`.
The result will be in the same time zone as `zdt`.

For convenience, `p` may be a type instead of a value: `ceil(zdt, Dates.Hour)` is a
shortcut for `ceil(zdt, Dates.Hour(1))`.

`VariableTimeZone` transitions are handled as for `round`.

### Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```julia
julia> zdt = ZonedDateTime(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg"))
2016-03-13T01:45:00-06:00

julia> ceil(zdt, Dates.Day)
2016-03-14T00:00:00-05:00

julia> ceil(zdt, Dates.Hour)
2016-03-13T03:00:00-05:00
```
"""
Base.ceil(::TimeZones.ZonedDateTime, ::Union{Period, Type{Period}})

"""
    round(zdt::ZonedDateTime, p::Period, [r::RoundingMode]) -> ZonedDateTime
    round(zdt::ZonedDateTime, p::Type{Period}, [r::RoundingMode]) -> ZonedDateTime

Returns the `ZonedDateTime` nearest to `zdt` at resolution `p`. The result will be in the
same time zone as `zdt`. By default (`RoundNearestTiesUp`), ties (e.g., rounding 9:30 to the
nearest hour) will be rounded up.

For convenience, `p` may be a type instead of a value: `round(zdt, Dates.Hour)` is a
shortcut for `round(zdt, Dates.Hour(1))`.

Valid rounding modes for `round(::TimeType, ::Period, ::RoundingMode)` are
`RoundNearestTiesUp` (default), `RoundDown` (`floor`), and `RoundUp` (`ceil`).

### `VariableTimeZone` Transitions

Instead of performing rounding operations on the `ZonedDateTime`'s internal UTC `DateTime`,
which would be computationally less expensive, rounding is done in the local time zone.
This ensures that rounding behaves as expected and is maximally meaningful.

If rounding were done in UTC, consider how rounding to the nearest day would be resolved for
non-UTC time zones: the result would be 00:00 UTC, which wouldn't be midnight local time.
Similarly, when rounding to the nearest hour in `Australia/Eucla (UTC+08:45)`, the result
wouldn't be on the hour in the local time zone.

When `p` is a `DatePeriod` rounding is done in the local time zone in a straightforward
fashion. When `p` is a `TimePeriod` the likelihood of encountering an ambiguous or
non-existent time (due to daylight saving time transitions) is increased. To resolve this
issue, rounding a `ZonedDateTime` with a `VariableTimeZone` to a `TimePeriod` uses the
`DateTime` value in the appropriate `FixedTimeZone`, then reconverts it to a `ZonedDateTime`
in the appropriate `VariableTimeZone` afterward.

Rounding is not an entirely "safe" operation for `ZonedDateTime`s, as in some cases
historical transitions for some time zones (such as `Asia/Colombo`) occur at midnight. In
such cases rounding to a `DatePeriod` may still result in an `AmbiguousTimeError` or a
`NonExistentTimeError`. (But these events should be relatively rare.)

Regular daylight saving time transitions should be safe.

### Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```julia
julia> zdt = ZonedDateTime(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg"))
2016-03-13T01:45:00-06:00

julia> round(zdt, Dates.Hour)
2016-03-13T03:00:00-05:00

julia> round(zdt, Dates.Day)
2016-03-13T00:00:00-06:00
```

The `Asia/Colombo` time zone revised the definition of Lanka Time from UTC+6:30 to UTC+6:00
on 1996-10-26, moving from 00:29:59 back to 00:00:00.

```julia
julia> zdt = ZonedDateTime(1996, 10, 25, 23, 45, TimeZone("Asia/Colombo"))
1996-10-25T23:45:00+06:30

julia> round(zdt, Dates.Hour)
1996-10-26T00:00:00+06:30

julia> round(zdt, Dates.Day)
ERROR: Local DateTime 1996-10-26T00:00:00 is ambiguous
```
"""     # Defined in base/dates/rounding.jl
Base.round(::TimeZones.ZonedDateTime, ::Union{Period, Type{Period}})
