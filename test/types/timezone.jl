using TimeZones: TZData

@test istimezone("Europe/Warsaw")
@test istimezone("UTC+02")
@test !istimezone("Europe/Camelot")

# Deserialization can cause us to have two immutables that are not using the same memory
@test TimeZone("Europe/Warsaw") === TimeZone("Europe/Warsaw")
@test tz"Africa/Nairobi" === TimeZone("Africa/Nairobi")
