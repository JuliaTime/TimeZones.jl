## Converting Time Zones

Switching an existing `ZonedDateTime` from one `TimeZone` to another can be done with the constructor `ZonedDateTime(::ZonedDateTime, ::TimeZone)`:

```julia
julia> zdt = ZonedDateTime(2014, 1, 1, TimeZone("UTC"))
2014-01-01T00:00:00+00:00

julia> ZonedDateTime(zdt, TimeZone("Asia/Tokyo"))
2014-01-01T09:00:00+09:00
```
