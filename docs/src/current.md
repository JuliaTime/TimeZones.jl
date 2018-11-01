# Current Time

```@setup tz
using TimeZones
using Dates
```

## `now` / System Time Zone

Julia provides the `now()` method to retrieve your current system's time as a `DateTime`. The TimeZones.jl package provides an additional `now(::TimeZone)` method providing the current time as a `ZonedDateTime`:

```@example tz
now(tz"Europe/Warsaw")
nothing; # hide
```

To get the `TimeZone` currently specified on you system you can use `localzone()`. Combining this method with the new `now` method produces the current system time in the current system's time zone:

```@example tz
now(localzone())
nothing; # hide
```

## `today`

Similar to `now` the TimeZones package also provides a `today(::TimeZone)` method which allows you to determine the current date as a `Date` in the specified `TimeZone`.

```@repl tz
a, b = now(tz"Pacific/Midway"), now(tz"Pacific/Apia")
a - b
today(tz"Pacific/Midway"), today(tz"Pacific/Apia")
```

You should be careful not to use `today()` when working with `ZonedDateTime`s as you may end up using the wrong day. For example:

```@repl tz
midway, apia = tz"Pacific/Midway", tz"Pacific/Apia"
ZonedDateTime(today() + Time(11), midway)
ZonedDateTime(today() + Time(11), apia)  # Wrong date; with the current rules apia should be one day ahead of midway
ZonedDateTime(today(midway) + Time(11), midway)
ZonedDateTime(today(apia) + Time(11), apia)
```

Alternatively, you can use the `todayat` function which takes care of this for you:

```@repl tz
todayat(Time(11), tz"Pacific/Midway")
todayat(Time(11), tz"Pacific/Apia")
```
