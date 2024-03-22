# TimeZones Public API

## TimeZone

```@docs
TimeZone(::AbstractString)
@tz_str
localzone
FixedTimeZone
VariableTimeZone
TimeZones.build
```

## Legacy Time Zones

```@docs
TimeZone(::AbstractString, ::TimeZones.Class)
TimeZones.Class
istimezone
```

## ZonedDateTime

```@docs
ZonedDateTime
ZonedDateTime(::DateTime, ::VariableTimeZone)
ZonedDateTime(::DateTime, ::VariableTimeZone, ::Integer)
ZonedDateTime(::DateTime, ::VariableTimeZone, ::Bool)
ZonedDateTime(::Date, ::Vararg)
astimezone
TimeZones.timezone(::ZonedDateTime)
TimeZone(::ZonedDateTime)
FixedTimeZone(::ZonedDateTime)
DateTime(::ZonedDateTime)
DateTime(::ZonedDateTime, ::Type{UTC})
Date(::ZonedDateTime)
Date(::ZonedDateTime, ::Type{UTC})
Time(::ZonedDateTime)
Time(::ZonedDateTime, ::Type{UTC})
```

## Current Time

```@docs
now(::TimeZone)
today(::TimeZone)
todayat
```

## Rounding

```@docs
round(::ZonedDateTime, ::Period)
floor(::ZonedDateTime, ::Period)
ceil(::ZonedDateTime, ::Period)
```

## Exceptions

```@docs
NonExistentTimeError
AmbiguousTimeError
UnhandledTimeError
```

## Discovery

```@docs
timezone_names
all_timezones
timezones_from_abbr
timezone_abbrs
next_transition_instant
show_next_transition
```
