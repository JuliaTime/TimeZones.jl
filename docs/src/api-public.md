# TimeZones Public API

```@meta
DocTestSetup = quote
    using TimeZones
end
```

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
astimezone
TimeZones.timezone(::ZonedDateTime)
TimeZones.utc
TimeZones.localtime
DateTime(::ZonedDateTime)
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
