using TimeZones

warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)

# Typical "spring-forward" behaviour
dts = (
    DateTime(1916,4,30,22),
    DateTime(1916,4,30,23),
    DateTime(1916,5,1,0),
)
@test_throws NonExistentTimeError ZonedDateTime(dts[2], warsaw)

@test ZonedDateTime(dts[1], warsaw).zone.name == :CET
@test ZonedDateTime(dts[3], warsaw).zone.name == :CEST

@test ZonedDateTime(dts[1], warsaw).utc_datetime == DateTime(1916,4,30,21)
@test ZonedDateTime(dts[3], warsaw).utc_datetime == DateTime(1916,4,30,22)


# Typical "fall-back" behaviour
dt = DateTime(1916, 10, 1, 0)
@test_throws AmbiguousTimeError ZonedDateTime(dt, warsaw)

@test ZonedDateTime(dt, warsaw, 1).zone.name == :CEST
@test ZonedDateTime(dt, warsaw, 2).zone.name == :CET
@test ZonedDateTime(dt, warsaw, true).zone.name == :CEST
@test ZonedDateTime(dt, warsaw, false).zone.name == :CET

@test ZonedDateTime(dt, warsaw, 1).utc_datetime == DateTime(1916, 9, 30, 22)
@test ZonedDateTime(dt, warsaw, 2).utc_datetime == DateTime(1916, 9, 30, 23)
@test ZonedDateTime(dt, warsaw, true).utc_datetime == DateTime(1916, 9, 30, 22)
@test ZonedDateTime(dt, warsaw, false).utc_datetime == DateTime(1916, 9, 30, 23)

# TODO: Add tests where save > 02:00:00
# TODO: Test offset changes where gap or overlap is greater than an hour


# test = TimeZones.Zoned(Dates.UTM(63492681600000))
# # Test DateTime construction by parts
# @test ZonedDateTime(DateTime(1918,10,27,0), tz) == ZonedDateTime(DateTime(1918,10,27,0), tz) ==
# @test Dates.DateTime(2013,1) == test
# @test Dates.DateTime(2013,1,1) == test
# @test Dates.DateTime(2013,1,1,0) == test
# @test Dates.DateTime(2013,1,1,0,0) == test
# @test Dates.DateTime(2013,1,1,0,0,0) == test
# @test Dates.DateTime(2013,1,1,0,0,0,0) == test


# @test_throws AmbiguousTimeError ZonedDateTime(DateTime(1942,11,2,3), warsaw)
# @test_throws AmbiguousTimeError ZonedDateTime(DateTime(1942,11,2,3), warsaw, true)
# @test_throws AmbiguousTimeError ZonedDateTime(DateTime(1942,11,2,3), warsaw, false)
# @test ZonedDateTime(DateTime(1942,11,2,3), warsaw, 1).zone.name == :EET
# @test ZonedDateTime(DateTime(1942,11,2,3), warsaw, 2).zone.name == :CET


# na_zones, na_rules = TimeZones.Olsen.tzparse(joinpath(Pkg.dir("TimeZones"), "deps", "tzdata", "northamerica"));
# winnipeg = TimeZones.Olsen.resolve("America/Winnipeg", na_zones, na_rules)
# @test ZonedDateTime(DateTime(1945,8,14,17), winnipeg).zone.name == :CWT
# @test ZonedDateTime(DateTime(1945,8,14,18), winnipeg).zone.name == :CPT
