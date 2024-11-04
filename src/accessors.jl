using Dates: Hour, Minute, Second, Millisecond, days, hour, minute, second, millisecond

"""
    timezone(::ZonedDateTime) -> TimeZone

Returns the `TimeZone` used by the `ZonedDateTime`.
"""
timezone(zdt::ZonedDateTime) = zdt.timezone

for accessor in (:days, :hour, :minute, :second, :millisecond)
    @eval Dates.$accessor(zdt::ZonedDateTime) = Dates.$accessor(DateTime(zdt))
end

for period in (:Year, :Quarter, :Month, :Week, :Day, :Hour, :Minute, :Second, :Millisecond)
    accessor = Symbol(lowercase(string(period)))
    @eval Dates.$period(zdt::ZonedDateTime) = Dates.$period(Dates.$accessor(zdt))
end

Base.eps(::ZonedDateTime) = Millisecond(1)

"""
    DateTime(zdt::ZonedDateTime) -> DateTime

Construct a `DateTime` based on the "local time" representation of the provided
`ZonedDateTime`.

!!! warning

    Any arithmetic performed on the returned `DateTime` will be timezone unaware and will
    not reflect an accurate local time if the operation would cross a DST transition.

See also: [`DateTime(::ZonedDateTime, ::Type{UTC})`](@ref).

# Example

```jldoctest
julia> zdt = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> DateTime(zdt)
2014-05-30T21:00:00
```
"""
Dates.DateTime(zdt::ZonedDateTime) = zdt.utc_datetime + zdt.zone.offset

"""
    DateTime(zdt::ZonedDateTime, ::Type{UTC}) -> DateTime

Construct a `DateTime` based on the UTC representation of the provided `ZonedDateTime`.

See also: [`DateTime(::ZonedDateTime)`](@ref).

# Example

```jldoctest
julia> zdt = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> DateTime(zdt, UTC)
2014-05-31T01:00:00
```
"""
Dates.DateTime(zdt::ZonedDateTime, ::Type{UTC}) = zdt.utc_datetime


"""
    Date(zdt::ZonedDateTime) -> Date

Construct a `Date` based on the "local time" representation of the provided `ZonedDateTime`.

See also: [`Date(::ZonedDateTime, ::Type{UTC})`](@ref).

# Example

```jldoctest
julia> zdt = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> Date(zdt)
2014-05-30
```
"""
Dates.Date(zdt::ZonedDateTime) = Date(DateTime(zdt))


"""
    Date(zdt::ZonedDateTime, ::Type{UTC}) -> Date

Construct a `Date` based on the UTC representation of the provided `ZonedDateTime`.

See also: [`Date(::ZonedDateTime)`](@ref).

# Example

```jldoctest
julia> zdt = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> Date(zdt, UTC)
2014-05-31
```
"""
Dates.Date(zdt::ZonedDateTime, ::Type{UTC}) = Date(DateTime(zdt, UTC))


"""
    Time(zdt::ZonedDateTime) -> Time

Construct a `Time` based on the "local time" representation of the provided `ZonedDateTime`.

See also: [`Time(::ZonedDateTime, ::Type{UTC})`](@ref).

# Example

```jldoctest
julia> zdt = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> Time(zdt)
21:00:00
```
"""
Dates.Time(zdt::ZonedDateTime) = Time(DateTime(zdt))


"""
    Time(zdt::ZonedDateTime, ::Type{UTC}) -> Date

Construct a `Time` based on the UTC representation of the provided `ZonedDateTime`.

See also: [`Time(::ZonedDateTime)`](@ref).

# Example

```jldoctest
julia> zdt = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> Time(zdt, UTC)
01:00:00
```
"""
Dates.Time(zdt::ZonedDateTime, ::Type{UTC}) = Time(DateTime(zdt, UTC))


"""
    FixedTimeZone(zdt::ZonedDateTime) -> FixedTimeZone

Construct a `FixedTimeZone` using the UTC offset for the timestamp provided by the
`ZonedDateTime`. If the timezone used by the `ZonedDateTime` has UTC offsets that change
over time the returned `FixedTimeZone` will vary based upon the timestamp.

See also: [`TimeZone(::ZonedDateTime)`](@ref).

# Example

```jldoctest
julia> zdt1 = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> FixedTimeZone(zdt1)
EDT (UTC-4)

julia> zdt2 = ZonedDateTime(2014, 2, 18, 6, tz"America/New_York")
2014-02-18T06:00:00-05:00

julia> FixedTimeZone(zdt2)
EST (UTC-5)
```
"""
FixedTimeZone(zdt::ZonedDateTime) = zdt.zone


"""
    TimeZone(zdt::ZonedDateTime) -> TimeZone

Extract the `TimeZone` associated with the `ZonedDateTime`.

See also: [`timezone(::ZonedDateTime)`](@ref), [`FixedTimeZone(::ZonedDateTime)`](@ref).

# Examples

```jldoctest
julia> zdt = ZonedDateTime(2014, 5, 30, 21, tz"America/New_York")
2014-05-30T21:00:00-04:00

julia> TimeZone(zdt)
America/New_York (UTC-5/UTC-4)
```
"""
TimeZone(zdt::ZonedDateTime) = zdt.timezone
