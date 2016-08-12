utc = FixedTimeZone("UTC")
warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)

# Converting a ZonedDateTime into a DateTime
dt = DateTime(2015, 1, 1, 0)
zdt = ZonedDateTime(dt, warsaw)
@test DateTime(zdt) == dt

# Converting from ZonedDateTime to DateTime isn't possible as it is always inexact.
@test_throws MethodError convert(DateTime, zdt)

# Vectorized accessors
arr = repmat([zdt], 10)
@test Dates.DateTime(arr) == repmat([dt], 10)

# now function
dt = Dates.unix2datetime(time())  # Base.now in UTC
zdt = now(warsaw)
@test zdt.timezone == warsaw
@test isapprox(map(Dates.datetime2unix, [dt, TimeZones.utc(zdt)])...)


# Changing time zones
dt = DateTime(2015, 1, 1, 0)
zdt_utc = ZonedDateTime(dt, utc; from_utc=true)
zdt_warsaw = ZonedDateTime(dt, warsaw; from_utc=true)

# Identical since ZonedDateTime is immutable
@test astimezone(zdt_utc, warsaw) === zdt_warsaw
@test astimezone(zdt_warsaw, utc) === zdt_utc
