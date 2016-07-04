## Rounding ZonedDateTimes

Rounding operations (`floor`, `ceil`, and `round`) on `ZonedDateTime`s are performed in a
[similar manner to `DateTime`](http://julia.readthedocs.org/en/latest/manual/dates/#rounding)
and should generally behave as expected. When `VariableTimeZone` transitions are involved,
however, unexpected behaviour may be encountered.

Instead of performing rounding operations on the `ZonedDateTime`'s internal UTC `DateTime`,
which would be computationally less expensive, rounding is done in the local time zone.
This ensures that rounding behaves as expected and is maximally meaningful. (Consider how
rounding to the nearest day would be resolved for non-UTC time zones, or even rounding to
the nearest hour for time zones like `America/St_Johns` or `Australia/Eucla`.)

### Rounding to a TimePeriod

When the target resolution is a `TimePeriod` the likelihood of encountering an ambiguous or
non-existent time (due to daylight saving time transitions) is increased. To resolve this
issue, rounding a `ZonedDateTime` with a `VariableTimeZone` to a `TimePeriod` uses the
`DateTime` value in the appropriate `FixedTimeZone`, then reconverts it to a `ZonedDateTime`
in the appropriate `VariableTimeZone` afterward.

### Rounding to a DatePeriod

When the target resolution is a `DatePeriod` rounding is done in the local time zone in a
straightforward fashion.

Rounding is not an entirely "safe" operation for `ZonedDateTime`s, as in some cases
historical transitions for some time zones (`Asia/Colombo, for example) occur at midnight.
In such cases rounding to a `DatePeriod` may still result in an `AmbiguousTimeError` or a
`NonExistentTimeError`s. (But such occurrences should be relatively rare.)

Regular daylight saving time transitions should be safe.

### Examples

The `America/Winnipeg` time zone transitioned from Central Standard Time (UTC-6:00) to
Central Daylight Time (UTC-5:00) on 2016-03-13, moving directly from 01:59:59 to 03:00:00.

```julia
julia> floor(ZonedDateTime(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg")), Dates.Day)
2016-03-13T00:00:00-06:00

julia> ceil(ZonedDateTime(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg")), Dates.Day)
2016-03-14T00:00:00-05:00

julia> round(ZonedDateTime(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg")), Dates.Day)
2016-03-13T00:00:00-06:00

julia> ceil(ZonedDateTime(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg")), Dates.Hour)
2016-03-13T03:00:00-05:00

julia> round(ZonedDateTime(2016, 3, 13, 1, 45, TimeZone("America/Winnipeg")), Dates.Hour)
2016-03-13T03:00:00-05:00
```
