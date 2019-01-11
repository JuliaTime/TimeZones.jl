utc = FixedTimeZone("UTC")
fixed = FixedTimeZone("UTC-06:00")
winnipeg = first(compile("America/Winnipeg", tzdata["northamerica"]))   # UTC-6:00 (or UTC-5:00)
st_johns = first(compile("America/St_Johns", tzdata["northamerica"]))   # UTC-3:30 (or UTC-2:30)
eucla = first(compile("Australia/Eucla", tzdata["australasia"]))        # UTC+8:45
colombo = first(compile("Asia/Colombo", tzdata["asia"]))                # See note below

# On 1996-05-25 at 00:00, the Asia/Colombo time zone in Sri Lanka moved from Indian Standard
# Time (UTC+5:30) to Lanka Time (UTC+6:30). On 1996-10-26 at 00:30, Lanka Time was revised
# from UTC+6:30 to UTC+6:00, marking a -00:30 transition. Transitions like these are doubly
# unusual (compared to the more common DST transitions) as it is both an half-hour
# transition and a transition that lands at midnight (causing 1996-10-26T00:00 to be
# ambiguous; midnights are rarely ambiguous). In 2006, Asia/Colombo returned to Indian
# Standard Time, causing another -00:30 transition from 00:30 to 00:00.

##################
# NO TRANSITIONS #
##################

# Test rounding where no rounding is necessary.

dt = DateTime(2016)

for tz in [utc, fixed, winnipeg, st_johns, eucla, colombo]
    local tz
    local zdt = ZonedDateTime(dt, tz)
    for p in [Dates.Year, Dates.Month, Dates.Day, Dates.Hour, Dates.Minute, Dates.Second]
        @test floor(zdt, p) == zdt
        @test ceil(zdt, p) == zdt
        @test round(zdt, p) == zdt
    end
end

# Test rounding non-controversial ZonedDateTimes (no transitions).

dt = DateTime(2016, 2, 5, 13, 10, 20, 500)

for tz in [utc, fixed, winnipeg, st_johns, eucla, colombo]
    local tz
    local zdt = ZonedDateTime(dt, tz)

    @test floor(zdt, Dates.Year) == ZonedDateTime(2016, tz)
    @test floor(zdt, Dates.Month) == ZonedDateTime(2016, 2, tz)
    @test floor(zdt, Dates.Week) == ZonedDateTime(2016, 2, tz)      # Previous Monday
    @test floor(zdt, Dates.Day) == ZonedDateTime(2016, 2, 5, tz)
    @test floor(zdt, Dates.Hour) == ZonedDateTime(2016, 2, 5, 13, tz)
    @test floor(zdt, Dates.Minute) == ZonedDateTime(2016, 2, 5, 13, 10, tz)
    @test floor(zdt, Dates.Second) == ZonedDateTime(2016, 2, 5, 13, 10, 20, tz)

    @test ceil(zdt, Dates.Year) == ZonedDateTime(2017, tz)
    @test ceil(zdt, Dates.Month) == ZonedDateTime(2016, 3, tz)
    @test ceil(zdt, Dates.Week) == ZonedDateTime(2016, 2, 8, tz)    # Following Monday
    @test ceil(zdt, Dates.Day) == ZonedDateTime(2016, 2, 6, tz)
    @test ceil(zdt, Dates.Hour) == ZonedDateTime(2016, 2, 5, 14, tz)
    @test ceil(zdt, Dates.Minute) == ZonedDateTime(2016, 2, 5, 13, 11, tz)
    @test ceil(zdt, Dates.Second) == ZonedDateTime(2016, 2, 5, 13, 10, 21, tz)

    @test round(zdt, Dates.Year) == ZonedDateTime(2016, tz)
    @test round(zdt, Dates.Month) == ZonedDateTime(2016, 2, tz)
    @test round(zdt, Dates.Week) == ZonedDateTime(2016, 2, 8, tz)   # Following Monday
    @test round(zdt, Dates.Day) == ZonedDateTime(2016, 2, 6, tz)
    @test round(zdt, Dates.Hour) == ZonedDateTime(2016, 2, 5, 13, tz)
    @test round(zdt, Dates.Minute) == ZonedDateTime(2016, 2, 5, 13, 10, tz)
    @test round(zdt, Dates.Second) == ZonedDateTime(2016, 2, 5, 13, 10, 21, tz)
end

##########################
# DST TRANSITION FORWARD #
##########################

# Test rounding over spring transition (missing hour). FixedTimeZones have no transitions,
# but ZonedDateTimes with VariableTimeZones will round in their current (fixed) time zone
# and then adjust to the new time zone if a transition has occurred (DST, for example).

# Test rounding backward, toward the missing hour.

dt = DateTime(2016, 3, 13, 3, 15)             # 15 minutes after transition

zdt = ZonedDateTime(dt, fixed)
@test floor(zdt, Dates.Day) == ZonedDateTime(2016, 3, 13, fixed)
@test floor(zdt, Dates.Hour(2)) == ZonedDateTime(2016, 3, 13, 2, fixed)

for tz in [winnipeg, st_johns]
    local tz
    local zdt = ZonedDateTime(dt, tz)
    @test floor(zdt, Dates.Day) == ZonedDateTime(2016, 3, 13, tz)
    @test floor(zdt, Dates.Hour(2)) == ZonedDateTime(2016, 3, 13, 1, tz)
end

# Test rounding forward, toward the missing hour.

dt = DateTime(2016, 3, 13, 1, 55)             # 5 minutes before transition

zdt = ZonedDateTime(dt, fixed)
@test ceil(zdt, Dates.Day) == ZonedDateTime(2016, 3, 14, fixed)
@test ceil(zdt, Dates.Hour) == ZonedDateTime(2016, 3, 13, 2, fixed)
@test ceil(zdt, Dates.Minute(30)) == ZonedDateTime(2016, 3, 13, 2, fixed)
@test round(zdt, Dates.Minute(30)) == ZonedDateTime(2016, 3, 13, 2, fixed)

for tz in [winnipeg, st_johns]
    local tz
    local zdt = ZonedDateTime(dt, tz)

    @test ceil(zdt, Dates.Day) == ZonedDateTime(2016, 3, 14, tz)
    @test ceil(zdt, Dates.Hour) == ZonedDateTime(2016, 3, 13, 3, tz)
    @test ceil(zdt, Dates.Minute(30)) == ZonedDateTime(2016, 3, 13, 3, tz)
    @test round(zdt, Dates.Minute(30)) == ZonedDateTime(2016, 3, 13, 3, tz)
end

# Test rounding from "midday".

dt = DateTime(2016, 3, 13, 12)                # Noon on day of transition

# Noon is the middle of the day, and ties round up by default.
@test round(ZonedDateTime(dt, fixed), Dates.Day) == ZonedDateTime(2016, 3, 14, fixed)

# Noon isn't the middle of the day, as 2:00 through 2:59:59.999 are missing in these zones.
@test round(ZonedDateTime(dt, winnipeg), Dates.Day) == ZonedDateTime(2016, 3, 13, winnipeg)
@test round(ZonedDateTime(dt, st_johns), Dates.Day) == ZonedDateTime(2016, 3, 13, st_johns)

###########################
# DST TRANSITION BACKWARD #
###########################

# Test rounding over autumn transition (additional, ambiguous hour).

# Test rounding backward, toward the ambiguous hour.

dt = DateTime(2015, 11, 1, 2, 15)             # 15 minutes after ambiguous hour

zdt = ZonedDateTime(dt, fixed)
@test floor(zdt, Dates.Day) == ZonedDateTime(2015, 11, 1, fixed)
@test floor(zdt, Dates.Hour(3)) == ZonedDateTime(2015, 11, 1, fixed)
# Rounding to Hour(3) will give 00:00, 03:00, 06:00, 09:00, etc.

for tz in [winnipeg, st_johns]
    local tz
    local zdt = ZonedDateTime(dt, tz)
    @test floor(zdt, Dates.Day) == ZonedDateTime(2015, 11, 1, tz)
    @test floor(zdt, Dates.Hour(3)) == ZonedDateTime(2015, 11, 1, 1, tz, 1)
    # Rounding is performed in the current fixed zone, then relocalized if a transition has
    # occurred. This means that instead of 00:00, 03:00, etc., we expect 01:00, 04:00, etc.
end

# Test rounding forward, toward the ambiguous hour.

dt = DateTime(2015, 11, 1, 0, 55)             # 5 minutes before ambiguous hour

zdt = ZonedDateTime(dt, fixed)
@test ceil(zdt, Dates.Day) == ZonedDateTime(2015, 11, 2, fixed)
@test ceil(zdt, Dates.Hour) == ZonedDateTime(2015, 11, 1, 1, fixed)
@test ceil(zdt, Dates.Minute(30)) == ZonedDateTime(2015, 11, 1, 1, fixed)
@test round(zdt, Dates.Minute(30)) == ZonedDateTime(2015, 11, 1, 1, fixed)

for tz in [winnipeg, st_johns]
    local tz
    local zdt = ZonedDateTime(dt, tz)
    next_hour = ZonedDateTime(DateTime(2015, 11, 1, 1), tz, 1)

    @test ceil(zdt, Dates.Day) == ZonedDateTime(2015, 11, 2, tz)
    @test ceil(zdt, Dates.Hour) == next_hour
    @test ceil(zdt, Dates.Minute(30)) == next_hour
    @test round(zdt, Dates.Minute(30)) == next_hour
end

# Test rounding forward and backward, during the ambiguous hour.

dt = DateTime(2015, 11, 1, 1, 25)                   # During ambiguous hour

zdt = ZonedDateTime(dt, fixed)
@test floor(zdt, Dates.Day) == ZonedDateTime(2015, 11, 1, fixed)
@test ceil(zdt, Dates.Day) == ZonedDateTime(2015, 11, 2, fixed)
@test round(zdt, Dates.Day) == ZonedDateTime(2015, 11, 1, fixed)
@test floor(zdt, Dates.Hour) == ZonedDateTime(2015, 11, 1, 1, fixed)
@test ceil(zdt, Dates.Hour) == ZonedDateTime(2015, 11, 1, 2, fixed)
@test round(zdt, Dates.Hour) == ZonedDateTime(2015, 11, 1, 1, fixed)
@test floor(zdt, Dates.Minute(30)) == ZonedDateTime(2015, 11, 1, 1, fixed)
@test ceil(zdt, Dates.Minute(30)) == ZonedDateTime(2015, 11, 1, 1, 30, fixed)
@test round(zdt, Dates.Minute(30)) == ZonedDateTime(2015, 11, 1, 1, 30, fixed)

for tz in [winnipeg, st_johns]
    local tz
    local zdt = ZonedDateTime(dt, tz, 1)            # First 1:25, before "falling back"
    prev_hour = ZonedDateTime(2015, 11, 1, 1, tz, 1)
    between_hours = ZonedDateTime(2015, 11, 1, 1, 30, tz, 1)
    next_hour = ZonedDateTime(2015, 11, 1, 1, tz, 2)
    @test floor(zdt, Dates.Day) == ZonedDateTime(2015, 11, 1, tz)
    @test ceil(zdt, Dates.Day) == ZonedDateTime(2015, 11, 2, tz)
    @test round(zdt, Dates.Day) == ZonedDateTime(2015, 11, 1, tz)
    @test floor(zdt, Dates.Hour) == prev_hour
    @test ceil(zdt, Dates.Hour) == next_hour
    @test round(zdt, Dates.Hour) == prev_hour
    @test floor(zdt, Dates.Minute(30)) == prev_hour
    @test ceil(zdt, Dates.Minute(30)) == between_hours
    @test round(zdt, Dates.Minute(30)) == between_hours
end

###########################
# ASIA/COLOMBO TRANSITION #
###########################

# Test rounding to ambiguous midnight, which (unfortunately) isn't handled well when
# rounding to a DatePeriod resolution.

zdt = ZonedDateTime(1996, 10, 25, 23, 55, colombo)  # 5 minutes before ambiguous half-hour
@test floor(zdt, Dates.Day) == ZonedDateTime(1996, 10, 25, colombo)
@test_throws AmbiguousTimeError ceil(zdt, Dates.Day)
@test_throws AmbiguousTimeError round(zdt, Dates.Day)

zdt = ZonedDateTime(1996, 10, 26, 0, 35, colombo)   # 5 minutes after ambiguous half-hour
@test_throws AmbiguousTimeError floor(zdt, Dates.Day)
@test ceil(zdt, Dates.Day) == ZonedDateTime(1996, 10, 27, colombo)
@test_throws AmbiguousTimeError round(zdt, Dates.Day)

# Rounding to the ambiguous midnight works fine using a TimePeriod resolution, however.

zdt = ZonedDateTime(1996, 10, 25, 23, 55, colombo)  # 5 minutes before ambiguous half-hour
@test ceil(zdt, Dates.Hour) == ZonedDateTime(1996, 10, 26, colombo, 1)
@test round(zdt, Dates.Hour) == ZonedDateTime(1996, 10, 26, colombo, 1)

zdt = ZonedDateTime(1996, 10, 26, 0, 35, colombo)   # 5 minutes after ambiguous half-hour
@test floor(zdt, Dates.Hour) == ZonedDateTime(1996, 10, 26, colombo, 2)

# Rounding during the first half-hour between 00:00 and 00:30.

zdt = ZonedDateTime(1996, 10, 26, 0, 15, colombo, 1)
@test floor(zdt, Dates.Hour) == ZonedDateTime(1996, 10, 26, colombo, 1)
@test ceil(zdt, Dates.Hour) == ZonedDateTime(1996, 10, 26, 0, 30, colombo)
@test round(zdt, Dates.Hour) == ZonedDateTime(1996, 10, 26, colombo, 1)
@test floor(zdt, Dates.Minute(30)) == ZonedDateTime(1996, 10, 26, colombo, 1)
@test ceil(zdt, Dates.Minute(30)) == ZonedDateTime(1996, 10, 26, colombo, 2)
@test round(zdt, Dates.Minute(30)) == ZonedDateTime(1996, 10, 26, colombo, 2)

# Rounding during the second half-hour between 00:00 and 00:30.

zdt = ZonedDateTime(1996, 10, 26, 0, 15, colombo, 2)
@test floor(zdt, Dates.Hour) == ZonedDateTime(1996, 10, 26, colombo, 2)
@test ceil(zdt, Dates.Hour) == ZonedDateTime(1996, 10, 26, 1, colombo)
@test round(zdt, Dates.Hour) == ZonedDateTime(1996, 10, 26, colombo, 2)
@test floor(zdt, Dates.Minute(30)) == ZonedDateTime(1996, 10, 26, colombo, 2)
@test ceil(zdt, Dates.Minute(30)) == ZonedDateTime(1996, 10, 26, 0, 30, colombo)
@test round(zdt, Dates.Minute(30)) == ZonedDateTime(1996, 10, 26, 0, 30, colombo)

###############
# ERROR CASES #
###############

# Test rounding to invalid resolutions.

dt = DateTime(2016, 2, 28, 12, 15, 10, 190)
for tz in [utc, fixed, winnipeg, st_johns, eucla, colombo]
    local tz
    local zdt = ZonedDateTime(dt, tz)
    for p in [Dates.Year, Dates.Month, Dates.Day, Dates.Hour, Dates.Minute, Dates.Second]
        for v in [-1, 0]
            @test_throws DomainError floor(dt, p(v))
            @test_throws DomainError ceil(dt, p(v))
            @test_throws DomainError round(dt, p(v))
        end
    end
end
