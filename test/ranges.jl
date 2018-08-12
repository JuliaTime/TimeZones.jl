import Compat.Dates: Day, Hour, Minute


utc = FixedTimeZone("UTC", 0)
dst = resolve("America/Winnipeg", tzdata["northamerica"]...)
no_dst = resolve("America/Regina", tzdata["northamerica"]...)
fixed = FixedTimeZone("Fixed", -5 * 3600)


# Test date ranges for dates in which no DST transition occurs.
d = DateTime(2013, 2, 13)
raw_range = collect(d:Hour(1):d + Day(1))

utc_range = Localized(d, utc):Hour(1):Localized(d, utc) + Day(1)
dst_range = Localized(d, dst):Hour(1):Localized(d, dst) + Day(1)
no_dst_range = Localized(d, no_dst):Hour(1):Localized(d, no_dst) + Day(1)
fixed_range = Localized(d, fixed):Hour(1):Localized(d, fixed) + Day(1)

# Each range should have 25 elements.
@test length(utc_range) == 25
@test length(dst_range) == 25
@test length(no_dst_range) == 25
@test length(fixed_range) == 25

# Values in ZoneDateTime range should match raw DateTime range with appropriate offsets.
@test TimeZones.utc.(utc_range) == raw_range
@test TimeZones.utc.(dst_range) == raw_range .+ Hour(6)
@test TimeZones.utc.(no_dst_range) == raw_range .+ Hour(6)
@test TimeZones.utc.(fixed_range) == raw_range .+ Hour(5)


# Test date ranges for the day of the DST "spring forward".
d = DateTime(2013, 3, 10)
raw_range = collect(d:Hour(1):d + Day(1))

utc_range = Localized(d, utc):Hour(1):Localized(d, utc) + Day(1)
dst_range = Localized(d, dst):Hour(1):Localized(d, dst) + Day(1)
no_dst_range = Localized(d, no_dst):Hour(1):Localized(d, no_dst) + Day(1)
fixed_range = Localized(d, fixed):Hour(1):Localized(d, fixed) + Day(1)

# The range that observes DST should have only 24 elements because 02:00 is skipped.
@test length(utc_range) == 25
@test length(dst_range) == 24
@test length(no_dst_range) == 25
@test length(fixed_range) == 25

# Values in ZoneDateTime range should match raw DateTime range with appropriate offsets.
@test TimeZones.utc.(utc_range) == raw_range
@test TimeZones.utc.(dst_range) == [
    raw_range[1:2] .+ Hour(6);
    raw_range[4:end] .+ Hour(5)
]
@test TimeZones.utc.(no_dst_range) == raw_range .+ Hour(6)
@test TimeZones.utc.(fixed_range) == raw_range .+ Hour(5)


# Test date ranges for the day of the DST "fall back".
d = DateTime(2013, 11, 3)
raw_range = collect(d:Hour(1):d + Day(1))

utc_range = Localized(d, utc):Hour(1):Localized(d, utc) + Day(1)
dst_range = Localized(d, dst):Hour(1):Localized(d, dst) + Day(1)
no_dst_range = Localized(d, no_dst):Hour(1):Localized(d, no_dst) + Day(1)
fixed_range = Localized(d, fixed):Hour(1):Localized(d, fixed) + Day(1)

# The range that observes DST should have 26 elements because of the two instances of 01:00.
@test length(utc_range) == 25
@test length(dst_range) == 26
@test length(no_dst_range) == 25
@test length(fixed_range) == 25

# Values in ZoneDateTime range should match raw DateTime range with appropriate offsets.
@test TimeZones.utc.(utc_range) == raw_range
@test TimeZones.utc.(dst_range) == [
    raw_range[1:2] .+ Hour(5);
    raw_range[2:end] .+ Hour(6);
]
@test TimeZones.utc.(no_dst_range) == raw_range .+ Hour(6)
@test TimeZones.utc.(fixed_range) == raw_range .+ Hour(5)

# filter behaviour with a non-existent hour
range = Localized(2015, 3, 8, dst):Dates.Hour(1):Localized(2015, 3, 10, dst)
@test filter(dt -> Dates.hour(dt) == 2, range) == [
    # Localized(2015, 3, 8, 2, dst)  # Non-existent hour
    Localized(2015, 3, 9, 2, dst)
]

# filter behaviour with ambiguous hour
range = Localized(2015, 11, 1, dst):Dates.Hour(1):Localized(2015, 11, 3, dst)
@test filter(dt -> Dates.hour(dt) == 1, range) == [
    Localized(2015, 11, 1, 1, dst, 1)
    Localized(2015, 11, 1, 1, dst, 2)
    Localized(2015, 11, 2, 1, dst)
]

# default step for a Localized range
if VERSION < v"0.7.0-DEV.2778"
    range = Localized(2017, 10, 1, 9, utc):Localized(2017, 12, 8, 23, utc)
    @test step(range) == Dates.Day(1)
elseif VERSION < v"0.7-DEV+"  # Currently failing on Julia 0.7-DEV. Disabling for now.
    @test_warn(
        "colon(start::T, stop::T) where T <: Localized is deprecated, use start:Day(1):stop instead.",
        Localized(2017, 10, 1, 9, utc):Localized(2017, 12, 8, 23, utc)
    )
end
