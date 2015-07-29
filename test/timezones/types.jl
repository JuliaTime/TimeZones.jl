# # Create "test" check manually
# na, r = TimeZones.Olsen.tzparse(joinpath(Pkg.dir("TimeZones"), "deps", "tzdata", "northamerica"));
# tz = z["America/Winnipeg"]

# test = TimeZones.Zoned(Dates.UTM(63492681600000))
# # Test DateTime construction by parts
# @test ZonedDateTime(DateTime(1918,10,27,0), tz) == ZonedDateTime(DateTime(1918,10,27,0), tz) ==
# @test Dates.DateTime(2013,1) == test
# @test Dates.DateTime(2013,1,1) == test
# @test Dates.DateTime(2013,1,1,0) == test
# @test Dates.DateTime(2013,1,1,0,0) == test
# @test Dates.DateTime(2013,1,1,0,0,0) == test
# @test Dates.DateTime(2013,1,1,0,0,0,0) == test


# Note: Switch currently occurs are the wrong time.
europe, r = TimeZones.Olsen.tzparse(joinpath(Pkg.dir("TimeZones"), "deps", "tzdata", "europe"));
warsaw = europe["Europe/Warsaw"]

@test_throws AmbiguousTimeError ZonedDateTime(DateTime(1942,11,2,3), warsaw)
@test_throws AmbiguousTimeError ZonedDateTime(DateTime(1942,11,2,3), warsaw, true)
@test_throws AmbiguousTimeError ZonedDateTime(DateTime(1942,11,2,3), warsaw, false)
@test ZonedDateTime(DateTime(1942,11,2,3), warsaw, 1).zone.name == :EET
@test ZonedDateTime(DateTime(1942,11,2,3), warsaw, 2).zone.name == :CET
