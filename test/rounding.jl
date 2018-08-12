utc = FixedTimeZone("UTC")
fixed = FixedTimeZone("UTC-06:00")
winnipeg = resolve("America/Winnipeg", tzdata["northamerica"]...)   # UTC-6:00 (or UTC-5:00)
st_johns = resolve("America/St_Johns", tzdata["northamerica"]...)   # UTC-3:30 (or UTC-2:30)
eucla = resolve("Australia/Eucla", tzdata["australasia"]...)        # UTC+8:45
colombo = resolve("Asia/Colombo", tzdata["asia"]...)                # See note below

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
    local ldt = Localized(dt, tz)
    for p in [Dates.Year, Dates.Month, Dates.Day, Dates.Hour, Dates.Minute, Dates.Second]
        @test floor(ldt, p) == ldt
        @test ceil(ldt, p) == ldt
        @test round(ldt, p) == ldt
    end
end

# Test rounding non-controversial ZonedDateTimes (no transitions).

dt = DateTime(2016, 2, 5, 13, 10, 20, 500)

for tz in [utc, fixed, winnipeg, st_johns, eucla, colombo]
    local tz
    local ldt = Localized(dt, tz)

    @test floor(ldt, Dates.Year) == Localized(2016, tz)
    @test floor(ldt, Dates.Month) == Localized(2016, 2, tz)
    @test floor(ldt, Dates.Week) == Localized(2016, 2, tz)      # Previous Monday
    @test floor(ldt, Dates.Day) == Localized(2016, 2, 5, tz)
    @test floor(ldt, Dates.Hour) == Localized(2016, 2, 5, 13, tz)
    @test floor(ldt, Dates.Minute) == Localized(2016, 2, 5, 13, 10, tz)
    @test floor(ldt, Dates.Second) == Localized(2016, 2, 5, 13, 10, 20, tz)

    @test ceil(ldt, Dates.Year) == Localized(2017, tz)
    @test ceil(ldt, Dates.Month) == Localized(2016, 3, tz)
    @test ceil(ldt, Dates.Week) == Localized(2016, 2, 8, tz)    # Following Monday
    @test ceil(ldt, Dates.Day) == Localized(2016, 2, 6, tz)
    @test ceil(ldt, Dates.Hour) == Localized(2016, 2, 5, 14, tz)
    @test ceil(ldt, Dates.Minute) == Localized(2016, 2, 5, 13, 11, tz)
    @test ceil(ldt, Dates.Second) == Localized(2016, 2, 5, 13, 10, 21, tz)

    @test round(ldt, Dates.Year) == Localized(2016, tz)
    @test round(ldt, Dates.Month) == Localized(2016, 2, tz)
    @test round(ldt, Dates.Week) == Localized(2016, 2, 8, tz)   # Following Monday
    @test round(ldt, Dates.Day) == Localized(2016, 2, 6, tz)
    @test round(ldt, Dates.Hour) == Localized(2016, 2, 5, 13, tz)
    @test round(ldt, Dates.Minute) == Localized(2016, 2, 5, 13, 10, tz)
    @test round(ldt, Dates.Second) == Localized(2016, 2, 5, 13, 10, 21, tz)
end

##########################
# DST TRANSITION FORWARD #
##########################

# Test rounding over spring transition (missing hour). FixedTimeZones have no transitions,
# but ZonedDateTimes with VariableTimeZones will round in their current (fixed) time zone
# and then adjust to the new time zone if a transition has occurred (DST, for example).

# Test rounding backward, toward the missing hour.

dt = DateTime(2016, 3, 13, 3, 15)             # 15 minutes after transition

ldt = Localized(dt, fixed)
@test floor(ldt, Dates.Day) == Localized(2016, 3, 13, fixed)
@test floor(ldt, Dates.Hour(2)) == Localized(2016, 3, 13, 2, fixed)

for tz in [winnipeg, st_johns]
    local tz
    local ldt = Localized(dt, tz)
    @test floor(ldt, Dates.Day) == Localized(2016, 3, 13, tz)
    @test floor(ldt, Dates.Hour(2)) == Localized(2016, 3, 13, 1, tz)
end

# Test rounding forward, toward the missing hour.

dt = DateTime(2016, 3, 13, 1, 55)             # 5 minutes before transition

ldt = Localized(dt, fixed)
@test ceil(ldt, Dates.Day) == Localized(2016, 3, 14, fixed)
@test ceil(ldt, Dates.Hour) == Localized(2016, 3, 13, 2, fixed)
@test ceil(ldt, Dates.Minute(30)) == Localized(2016, 3, 13, 2, fixed)
@test round(ldt, Dates.Minute(30)) == Localized(2016, 3, 13, 2, fixed)

for tz in [winnipeg, st_johns]
    local tz
    local ldt = Localized(dt, tz)

    @test ceil(ldt, Dates.Day) == Localized(2016, 3, 14, tz)
    @test ceil(ldt, Dates.Hour) == Localized(2016, 3, 13, 3, tz)
    @test ceil(ldt, Dates.Minute(30)) == Localized(2016, 3, 13, 3, tz)
    @test round(ldt, Dates.Minute(30)) == Localized(2016, 3, 13, 3, tz)
end

# Test rounding from "midday".

dt = DateTime(2016, 3, 13, 12)                # Noon on day of transition

# Noon is the middle of the day, and ties round up by default.
@test round(Localized(dt, fixed), Dates.Day) == Localized(2016, 3, 14, fixed)

# Noon isn't the middle of the day, as 2:00 through 2:59:59.999 are missing in these zones.
@test round(Localized(dt, winnipeg), Dates.Day) == Localized(2016, 3, 13, winnipeg)
@test round(Localized(dt, st_johns), Dates.Day) == Localized(2016, 3, 13, st_johns)

###########################
# DST TRANSITION BACKWARD #
###########################

# Test rounding over autumn transition (additional, ambiguous hour).

# Test rounding backward, toward the ambiguous hour.

dt = DateTime(2015, 11, 1, 2, 15)             # 15 minutes after ambiguous hour

ldt = Localized(dt, fixed)
@test floor(ldt, Dates.Day) == Localized(2015, 11, 1, fixed)
@test floor(ldt, Dates.Hour(3)) == Localized(2015, 11, 1, fixed)
# Rounding to Hour(3) will give 00:00, 03:00, 06:00, 09:00, etc.

for tz in [winnipeg, st_johns]
    local tz
    local ldt = Localized(dt, tz)
    @test floor(ldt, Dates.Day) == Localized(2015, 11, 1, tz)
    @test floor(ldt, Dates.Hour(3)) == Localized(2015, 11, 1, 1, tz, 1)
    # Rounding is performed in the current fixed zone, then relocalized if a transition has
    # occurred. This means that instead of 00:00, 03:00, etc., we expect 01:00, 04:00, etc.
end

# Test rounding forward, toward the ambiguous hour.

dt = DateTime(2015, 11, 1, 0, 55)             # 5 minutes before ambiguous hour

ldt = Localized(dt, fixed)
@test ceil(ldt, Dates.Day) == Localized(2015, 11, 2, fixed)
@test ceil(ldt, Dates.Hour) == Localized(2015, 11, 1, 1, fixed)
@test ceil(ldt, Dates.Minute(30)) == Localized(2015, 11, 1, 1, fixed)
@test round(ldt, Dates.Minute(30)) == Localized(2015, 11, 1, 1, fixed)

for tz in [winnipeg, st_johns]
    local tz
    local ldt = Localized(dt, tz)
    next_hour = Localized(DateTime(2015, 11, 1, 1), tz, 1)

    @test ceil(ldt, Dates.Day) == Localized(2015, 11, 2, tz)
    @test ceil(ldt, Dates.Hour) == next_hour
    @test ceil(ldt, Dates.Minute(30)) == next_hour
    @test round(ldt, Dates.Minute(30)) == next_hour
end

# Test rounding forward and backward, during the ambiguous hour.

dt = DateTime(2015, 11, 1, 1, 25)                   # During ambiguous hour

ldt = Localized(dt, fixed)
@test floor(ldt, Dates.Day) == Localized(2015, 11, 1, fixed)
@test ceil(ldt, Dates.Day) == Localized(2015, 11, 2, fixed)
@test round(ldt, Dates.Day) == Localized(2015, 11, 1, fixed)
@test floor(ldt, Dates.Hour) == Localized(2015, 11, 1, 1, fixed)
@test ceil(ldt, Dates.Hour) == Localized(2015, 11, 1, 2, fixed)
@test round(ldt, Dates.Hour) == Localized(2015, 11, 1, 1, fixed)
@test floor(ldt, Dates.Minute(30)) == Localized(2015, 11, 1, 1, fixed)
@test ceil(ldt, Dates.Minute(30)) == Localized(2015, 11, 1, 1, 30, fixed)
@test round(ldt, Dates.Minute(30)) == Localized(2015, 11, 1, 1, 30, fixed)

for tz in [winnipeg, st_johns]
    local tz
    local ldt = Localized(dt, tz, 1)            # First 1:25, before "falling back"
    prev_hour = Localized(2015, 11, 1, 1, tz, 1)
    between_hours = Localized(2015, 11, 1, 1, 30, tz, 1)
    next_hour = Localized(2015, 11, 1, 1, tz, 2)
    @test floor(ldt, Dates.Day) == Localized(2015, 11, 1, tz)
    @test ceil(ldt, Dates.Day) == Localized(2015, 11, 2, tz)
    @test round(ldt, Dates.Day) == Localized(2015, 11, 1, tz)
    @test floor(ldt, Dates.Hour) == prev_hour
    @test ceil(ldt, Dates.Hour) == next_hour
    @test round(ldt, Dates.Hour) == prev_hour
    @test floor(ldt, Dates.Minute(30)) == prev_hour
    @test ceil(ldt, Dates.Minute(30)) == between_hours
    @test round(ldt, Dates.Minute(30)) == between_hours
end

###########################
# ASIA/COLOMBO TRANSITION #
###########################

# Test rounding to ambiguous midnight, which (unfortunately) isn't handled well when
# rounding to a DatePeriod resolution.

ldt = Localized(1996, 10, 25, 23, 55, colombo)  # 5 minutes before ambiguous half-hour
@test floor(ldt, Dates.Day) == Localized(1996, 10, 25, colombo)
@test_throws AmbiguousTimeError ceil(ldt, Dates.Day)
@test_throws AmbiguousTimeError round(ldt, Dates.Day)

ldt = Localized(1996, 10, 26, 0, 35, colombo)   # 5 minutes after ambiguous half-hour
@test_throws AmbiguousTimeError floor(ldt, Dates.Day)
@test ceil(ldt, Dates.Day) == Localized(1996, 10, 27, colombo)
@test_throws AmbiguousTimeError round(ldt, Dates.Day)

# Rounding to the ambiguous midnight works fine using a TimePeriod resolution, however.

ldt = Localized(1996, 10, 25, 23, 55, colombo)  # 5 minutes before ambiguous half-hour
@test ceil(ldt, Dates.Hour) == Localized(1996, 10, 26, colombo, 1)
@test round(ldt, Dates.Hour) == Localized(1996, 10, 26, colombo, 1)

ldt = Localized(1996, 10, 26, 0, 35, colombo)   # 5 minutes after ambiguous half-hour
@test floor(ldt, Dates.Hour) == Localized(1996, 10, 26, colombo, 2)

# Rounding during the first half-hour between 00:00 and 00:30.

ldt = Localized(1996, 10, 26, 0, 15, colombo, 1)
@test floor(ldt, Dates.Hour) == Localized(1996, 10, 26, colombo, 1)
@test ceil(ldt, Dates.Hour) == Localized(1996, 10, 26, 0, 30, colombo)
@test round(ldt, Dates.Hour) == Localized(1996, 10, 26, colombo, 1)
@test floor(ldt, Dates.Minute(30)) == Localized(1996, 10, 26, colombo, 1)
@test ceil(ldt, Dates.Minute(30)) == Localized(1996, 10, 26, colombo, 2)
@test round(ldt, Dates.Minute(30)) == Localized(1996, 10, 26, colombo, 2)

# Rounding during the second half-hour between 00:00 and 00:30.

ldt = Localized(1996, 10, 26, 0, 15, colombo, 2)
@test floor(ldt, Dates.Hour) == Localized(1996, 10, 26, colombo, 2)
@test ceil(ldt, Dates.Hour) == Localized(1996, 10, 26, 1, colombo)
@test round(ldt, Dates.Hour) == Localized(1996, 10, 26, colombo, 2)
@test floor(ldt, Dates.Minute(30)) == Localized(1996, 10, 26, colombo, 2)
@test ceil(ldt, Dates.Minute(30)) == Localized(1996, 10, 26, 0, 30, colombo)
@test round(ldt, Dates.Minute(30)) == Localized(1996, 10, 26, 0, 30, colombo)

###############
# ERROR CASES #
###############

# Test rounding to invalid resolutions.

dt = DateTime(2016, 2, 28, 12, 15, 10, 190)
for tz in [utc, fixed, winnipeg, st_johns, eucla, colombo]
    local tz
    local ldt = Localized(dt, tz)
    for p in [Dates.Year, Dates.Month, Dates.Day, Dates.Hour, Dates.Minute, Dates.Second]
        for v in [-1, 0]
            @test_throws DomainError floor(dt, p(v))
            @test_throws DomainError ceil(dt, p(v))
            @test_throws DomainError round(dt, p(v))
        end
    end
end
