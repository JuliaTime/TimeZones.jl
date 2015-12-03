## ZonedDateTime-Period Arithmetic

`ZonedDateTime` uses calendrical arithmetic in a [similar manner to `DateTime`](http://julia.readthedocs.org/en/latest/manual/dates/#timetype-period-arithmetic) but with some key differences. Lets look at these differences by adding a day to March 30th 2014 in Europe/Warsaw.

```julia
julia> warsaw = TimeZone("Europe/Warsaw")
Europe/Warsaw

julia> spring = ZonedDateTime(DateTime(2014,3,30), warsaw)
2014-03-30T00:00:00+01:00

julia> spring + Dates.Day(1)
2014-03-31T00:00:00+02:00
```

Adding a day to the `ZonedDateTime` changed the date from the 30th to the 31st as expected. Looking closely however you'll notice that the timezone offset changed from +01:00 to +02:00. The reason for this change is because the timezone "Europe/Warsaw" switched from standard time (+01:00) to daylight saving time (+02:00) on the 30th. The change in the offset caused the local DateTime 2014-03-31T02:00:00 to be skipped effectively making the 30th a day which only contained 23 hours. Alternatively if we added hours we can see the difference:

```julia
julia> spring + Dates.Hour(24)
2014-03-31T01:00:00+02:00

julia> spring + Dates.Hour(23)
2014-03-31T00:00:00+02:00
```

A potential cause of confusion regarding this behaviour is the loss in associativity. For example:

```julia
julia> (spring + Day(1)) + Hour(24)
2014-04-01T00:00:00+02:00

julia> (spring + Hour(24)) + Day(1)
2014-04-01T01:00:00+02:00

julia> spring + Hour(24) + Day(1)
2014-04-01T00:00:00+02:00
```

Take particular note of the last example which ends up merging the two periods into a single unit of 2 days.
