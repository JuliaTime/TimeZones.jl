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
@test @compat Dates.DateTime.(arr) == repmat([dt], 10)

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

# ZonedDateTime to Unix timestamp (and vice versa)
@test TimeZones.zdt2unix(ZonedDateTime(1970, utc)) == 0
@test TimeZones.unix2zdt(0) == ZonedDateTime(1970, utc)

for dt in (DateTime(2013, 2, 13), DateTime(2016, 8, 11))
    zdt = ZonedDateTime(dt, warsaw)
    offset = TimeZones.value(zdt.zone.offset)   # Total offset in seconds
    @test TimeZones.zdt2unix(zdt) == datetime2unix(dt) - offset
end

@test isa(TimeZones.zdt2unix(ZonedDateTime(1970, utc)), Float64)
@test isa(TimeZones.zdt2unix(Float32, ZonedDateTime(1970, utc)), Float32)
@test isa(TimeZones.zdt2unix(Int64, ZonedDateTime(1970, utc)), Int64)
@test isa(TimeZones.zdt2unix(Int32, ZonedDateTime(1970, utc)), Int32)

@test TimeZones.zdt2unix(ZonedDateTime(1970, 1, 1, 0, 0, 0, 750, utc)) == 0.75
@test TimeZones.zdt2unix(Float32, ZonedDateTime(1970, 1, 1, 0, 0, 0, 750, utc)) == 0.75
@test TimeZones.zdt2unix(Int64, ZonedDateTime(1970, 1, 1, 0, 0, 0, 750, utc)) == 0
@test TimeZones.zdt2unix(Int32, ZonedDateTime(1970, 1, 1, 0, 0, 0, 750, utc)) == 0

# round-trip
zdt = ZonedDateTime(2010, 1, 2, 3, 4, 5, utc)
round_trip = TimeZones.unix2zdt(TimeZones.zdt2unix(Int64, zdt))
@test round_trip == zdt

# millisecond loss
zdt = ZonedDateTime(2010, 1, 2, 3, 4, 5, 999, utc)
round_trip = TimeZones.unix2zdt(TimeZones.zdt2unix(Int64, zdt))
@test round_trip != zdt
@test round_trip == floor(zdt, Dates.Second(1))

# timezone loss
zdt = ZonedDateTime(2010, 1, 2, 3, 4, 5, warsaw)
round_trip = TimeZones.unix2zdt(TimeZones.zdt2unix(Int64, zdt))
@test round_trip == zdt
@test !isequal(round_trip, zdt)
