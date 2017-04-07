Frequently Asked Questions
==========================

## Why are the "Etc/*" time zones unsupported?

According to [IANA](ftp://ftp.iana.org/tz/data/etcetera) the "Etc/*" time zones are only included in the tz database for "historical reasons". Furthermore the time zones offsets provided the Etc/GMT±HH can be misleading. For example the Etc/GMT+4 time zone is 4 hours **behind** UTC rather than 4 hours **ahead** as most people expect. Since TimeZones.jl already provides an easy way of constructing fixed offset time zones using `FixedTimeZone` it was decided to leave these time zones out.

If you truly do want to include the "Etc/*" time zones you just need to download the tz source file and re-compile:

```julia
import TimeZones.TZData: extract, active_archive, compile
extract(active_archive(), TimeZones.TZ_SOURCE_DIR, "etcetera")
compile()
```

## Far-future ZonedDateTime with VariableTimeZone

Due to the internal representation of a `VariableTimeZone` it is infeasible to determine a time zones transitions to infinity. Since [2038-01-19T03:14:07](https://en.wikipedia.org/wiki/Year_2038_problem) is the last `DateTime` that can be represented by an `Int32` (`Dates.unix2datetime(typemax(Int32))`) it was decided that 2037 would be the last year in which all transition dates are computed. If additional transitions are known to exist after the last transition then a cutoff date is specified.

```julia
julia> warsaw = TimeZone("Europe/Warsaw")
Europe/Warsaw (UTC+1/UTC+2)

julia> last(warsaw.transitions)
2037-10-25T01:00:00 UTC+1/+0 (CET)

julia> warsaw.cutoff  # DateTime up until the last transition is effective
Nullable{DateTime}(2038-03-28T01:00:00)

julia> ZonedDateTime(DateTime(2039), warsaw)
ERROR: TimeZone Europe/Warsaw does not handle dates on or after 2038-03-28T01:00:00 UTC
```

It is important to note that since we are taking about future time zone transitions and the rules dictating these transitions are subject to change and may not be accurate. If you still want to work with future `ZonedDateTime` past the default cutoff you can re-compile the `TimeZone` objects and specify the `max_year` keyword:

```julia
julia> using TimeZones

julia> TimeZones.TZData.compile(max_year=2200)

julia> ZonedDateTime(DateTime(2100), TimeZone("Europe/Warsaw"))
2100-01-01T00:00:00+01:00
```
