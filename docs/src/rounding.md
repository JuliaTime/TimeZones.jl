# Rounding a ZonedDateTime

```@meta
DocTestSetup = quote
    using TimeZones, Dates
end
```

Rounding operations (`floor`, `ceil`, and `round`) on `ZonedDateTime`s are performed in a
[similar manner to `DateTime`](https://docs.julialang.org/en/v1/stdlib/Dates/#Rounding-1)
and should generally behave as expected. When `VariableTimeZone` transitions are involved,
however, unexpected behaviour may be encountered.

Instead of performing rounding operations on a UTC representation of the `ZonedDateTime`,
which would in some cases be computationally less expensive, rounding is done in the local
time zone. This ensures that rounding behaves as expected and is maximally meaningful.

If rounding were done in UTC, consider how rounding to the nearest day would be resolved for
non-UTC time zones: the result would be 00:00 UTC, which wouldn't be midnight local time.
Similarly, when rounding to the nearest hour in `Australia/Eucla (UTC+08:45)`, the result
wouldn't be on the hour in the local time zone.

## Rounding to a TimePeriod

When the target resolution is a `TimePeriod` the likelihood of encountering an ambiguous or
non-existent time (due to daylight saving time transitions) is increased. To resolve this
issue, rounding a `ZonedDateTime` with a `VariableTimeZone` to a `TimePeriod` uses the
`DateTime` value in the appropriate `FixedTimeZone`, then reconverts it to a `ZonedDateTime`
in the appropriate `VariableTimeZone` afterward. (See [Examples](@ref Examples) below.)

## Rounding to a DatePeriod

When the target resolution is a `DatePeriod` rounding is done in the local time zone in a
straightforward fashion.

Rounding is not an entirely "safe" operation for `ZonedDateTime`s, as in some cases
historical transitions for some time zones (`Asia/Colombo`, for example) occur at midnight.
In such cases rounding to a `DatePeriod` may still result in an `AmbiguousTimeError` or a
`NonExistentTimeError`s. (But such occurrences should be relatively rare.)

Regular daylight saving time transitions should be safe.

## Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```jldoctest
julia> zdt = ZonedDateTime(2016, 3, 13, 1, 45, tz"America/Winnipeg")
2016-03-13T01:45:00-06:00

julia> floor(zdt, Dates.Day)
2016-03-13T00:00:00-06:00

julia> ceil(zdt, Dates.Day)
2016-03-14T00:00:00-05:00

julia> round(zdt, Dates.Day)
2016-03-13T00:00:00-06:00

julia> floor(zdt, Dates.Hour)
2016-03-13T01:00:00-06:00

julia> ceil(zdt, Dates.Hour)
2016-03-13T03:00:00-05:00

julia> round(zdt, Dates.Hour)
2016-03-13T03:00:00-05:00
```

The `Asia/Colombo` time zone revised the definition of Lanka Time from UTC+6:30 to UTC+6:00
on 1996-10-26, moving from 00:29:59 back to 00:00:00.

```jldoctest
julia> zdt = ZonedDateTime(1996, 10, 25, 23, 45, tz"Asia/Colombo")
1996-10-25T23:45:00+06:30

julia> round(zdt, Dates.Hour)
1996-10-26T00:00:00+06:30

julia> round(zdt, Dates.Day)
ERROR: AmbiguousTimeError: Local DateTime 1996-10-26T00:00:00 is ambiguous within Asia/Colombo
```
