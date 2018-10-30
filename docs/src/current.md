# Current Time

## `now` / System Time Zone

Julia provides the `now()` method to retrieve your current system's time as a `DateTime`. The TimeZones.jl package provides an additional `now(::TimeZone)` method providing the current time as a `ZonedDateTime`:

```julia
now(tz"Europe/Warsaw")
```

To get the `TimeZone` currently specified on you system you can use `localzone()`. Combining this method with the new `now` method produces the current system time in the current system's time zone:

```julia
now(localzone())
```

## `today`

Similar to `now` the TimeZones package also provides a `today(::TimeZone)` method which allows you to determine the current date as a `Date` in the specified `TimeZone`.

```julia
julia> a, b = now(tz"Pacific/Midway"), now(tz"Pacific/Apia")
(2018-01-29T12:01:53.504-11:00, 2018-01-30T13:01:53.504+14:00)

julia> a - b
0 milliseconds

julia> today(tz"Pacific/Midway"), today(tz"Pacific/Apia")
(2018-01-29, 2018-01-30)
```

You should be careful not to use `today()` when working with `ZonedDateTime`s as you may end up using the wrong day. For example:

```julia
julia> midway, apia = tz"Pacific/Midway", tz"Pacific/Apia"
(Pacific/Midway (UTC-11), Pacific/Apia (UTC+13/UTC+14))

julia> ZonedDateTime(today() + Time(11), midway)
2018-01-29T11:00:00-11:00

julia> ZonedDateTime(today() + Time(11), apia)  # Should be 2018-01-30
2018-01-29T11:00:00+14:00

julia> ZonedDateTime(today(midway) + Time(11), midway)
2018-01-29T11:00:00-11:00

julia> ZonedDateTime(today(apia) + Time(11), apia)
2018-01-30T11:00:00+14:00
```

Alternatively, you can use the `todayat` function which takes care of this for you:

```julia
julia> todayat(Time(11), tz"Pacific/Midway")
2018-01-29T11:00:00-11:00

julia> todayat(Time(11), tz"Pacific/Apia")
2018-01-30T11:00:00+14:00
```
