# Frequently Asked Questions

```@meta
DocTestSetup = quote
    using TimeZones
end
```

## [Where are the "Etc/\*" time zones?](@id etc_tzs)

According to [IANA](ftp://ftp.iana.org/tz/data/etcetera) the "Etc/\*" time zones are only included in the tz database for "historical reasons". Furthermore the time zones offsets provided the Etc/GMT±HH can be misleading. For example the Etc/GMT+4 time zone is 4 hours _behind_ UTC rather than 4 hours _ahead_ as most people expect. Since TimeZones.jl already provides an easy way of constructing fixed offset time zones using `FixedTimeZone` it was decided to only allow users to create these time zones if they explicitly ask for them.

```jldoctest
julia> TimeZone("Etc/GMT+4")
ERROR: ArgumentError: The time zone "Etc/GMT+4" is of class `TimeZones.Class(:LEGACY)` which is currently not allowed by the mask: `TimeZones.Class(:FIXED) | TimeZones.Class(:STANDARD)`

julia> TimeZone("Etc/GMT+4", TimeZones.Class(:LEGACY))
Etc/GMT+4 (UTC-4)
```

## [Far-future ZonedDateTime with VariableTimeZone](@id future_tzs)

Due to the internal representation of a `VariableTimeZone` it is infeasible to determine a time zones transitions to infinity. Since [2038-01-19T03:14:07](https://en.wikipedia.org/wiki/Year_2038_problem) is the last `DateTime` that can be represented by an `Int32` (`Dates.unix2datetime(typemax(Int32))`) it was decided that 2037 would be the last year in which all transition dates are computed. If additional transitions are known to exist after the last transition then a cutoff date is specified.

```jldoctest
julia> warsaw = tz"Europe/Warsaw"
Europe/Warsaw (UTC+1/UTC+2)

julia> last(warsaw.transitions)
2037-10-25T01:00:00 UTC+1/+0 (CET)

julia> warsaw.cutoff  # DateTime up until the last transition is effective
2038-03-28T01:00:00

julia> ZonedDateTime(DateTime(2039), warsaw)
ERROR: UnhandledTimeError: TimeZone Europe/Warsaw does not handle dates on or after 2038-03-28T01:00:00 UTC
```

It is important to note that since we are taking about future time zone transitions and the rules dictating these transitions are subject to change and may not be accurate. If you still want to work with future `ZonedDateTime` past the default cutoff you can re-compile the `TimeZone` objects and specify the `max_year` keyword:

```julia-repl
julia> using TimeZones

julia> TimeZones.TZData.compile(max_year=2200)

julia> ZonedDateTime(DateTime(2100), tz"Europe/Warsaw")
2100-01-01T00:00:00+01:00
```

Warning: since the `tz` string macro loads the `TimeZone` at compile time the time zone will be loaded before the tz data is recompiled. You can avoid this problem by using the `TimeZone` constructor.

```julia-repl
julia> begin
           TimeZones.TZData.compile(max_year=2210)
           ZonedDateTime(DateTime(2205), tz"Europe/Warsaw")
       end
ERROR: UnhandledTimeError: TimeZone Europe/Warsaw does not handle dates on or after 2038-03-28T01:00:00 UTC

julia> begin
           TimeZones.TZData.compile(max_year=2220)
           ZonedDateTime(DateTime(2215), TimeZone("Europe/Warsaw"))
       end
2215-01-01T00:00:00+01:00
```
