Frequently Asked Questions
==========================

## Why are the "Etc/*" timezones unsupported?

According to [IANA](ftp://ftp.iana.org/tz/data/etcetera) the "Etc/*" timezones are only included in the Olson time zone database for "historical reasons". Furthermore the time zones offsets provided the Etc/GMT±HH can be misleading. For example the Etc/GMT+4 time zone is 4 hours **behind** UTC rather than 4 hours **ahead** as most people expect. Since TimeZones.jl already provides an easy way of constructing fixed offset time zones using `FixedTimeZone` it was decided to leave these time zones out.

If you truly do want to include the "Etc/*" time zones you just need to download the Olson database file and re-compile:

```julia
using TimeZones
download("ftp://ftp.iana.org/tz/data/etcetera", joinpath(TimeZones.TZDATA_DIR, "etcetera"))
TimeZones.Olson.compile()
```

## Why do some timezones only work up to the year 2037?

Due to the internal representation of a `VariableTimeZone` it is infeasible to determine a time zones transitions to infinity. The date [2037](https://en.wikipedia.org/wiki/Year_2038_problem) is the last full year that can be represented by a `Int32` it was decided that was a good year to stop determining transition dates. Additionally, since we are talking about future dates it can not be guaranteed that the transition dates computed from the current rules will be accurate on any future date. Since transitions are not calculated past this year a time zone that is known to have transitions after this year will raise an exception if you try to create a date or use arithmetic to get the `ZonedDateTime` to the year 2038.

If you still want to use time zones past the year 2037 you can do so by re-compiling time zones using the `max_year` keyword:

```julia
using TimeZones
TimeZones.Olson.compile(max_year=2200)
```
