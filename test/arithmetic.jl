import Compat.Dates: Day, Hour

warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)

normal = DateTime(2015, 1, 1, 0)   # a 24 hour day in warsaw
spring = DateTime(2015, 3, 29, 0)  # a 23 hour day in warsaw
fall = DateTime(2015, 10, 25, 0)   # a 25 hour day in warsaw

# Unary plus
@test +Localized(normal, warsaw) == Localized(normal, warsaw)

# Period arithmetic
@test Localized(normal, warsaw) + Day(1) == Localized(normal + Day(1), warsaw)
@test Localized(spring, warsaw) + Day(1) == Localized(spring + Day(1), warsaw)
@test Localized(fall, warsaw) + Day(1) == Localized(fall + Day(1), warsaw)

@test Localized(normal, warsaw) + Hour(24) == Localized(normal + Hour(24), warsaw)
@test Localized(spring, warsaw) + Hour(24) == Localized(spring + Hour(25), warsaw)
@test Localized(fall, warsaw) + Hour(24) == Localized(fall + Hour(23), warsaw)

# Do the same calculations but backwards over the transitions.
@test Localized(normal + Day(1), warsaw) - Day(1) == Localized(normal, warsaw)
@test Localized(spring + Day(1), warsaw) - Day(1) == Localized(spring, warsaw)
@test Localized(fall + Day(1), warsaw) - Day(1) == Localized(fall, warsaw)

@test Localized(normal + Day(1), warsaw) - Hour(24) == Localized(normal, warsaw)
@test Localized(spring + Day(1), warsaw) - Hour(23) == Localized(spring, warsaw)
@test Localized(fall + Day(1), warsaw) - Hour(25) == Localized(fall, warsaw)

# Ensure that arithmetic around transitions works.
@test Localized(spring, warsaw) + Hour(1) == Localized(spring + Hour(1), warsaw)
@test Localized(spring, warsaw) + Hour(2) == Localized(spring + Hour(3), warsaw)
@test Localized(fall, warsaw) + Hour(2) == Localized(fall + Hour(2), warsaw, 1)
@test Localized(fall, warsaw) + Hour(3) == Localized(fall + Hour(2), warsaw, 2)

# Non-Associativity
explicit_hour_day = (Localized(spring, warsaw) + Hour(24)) + Day(1)
explicit_day_hour = (Localized(spring, warsaw) + Day(1)) + Hour(24)
implicit_hour_day = Localized(spring, warsaw) + Hour(24) + Day(1)
implicit_day_hour = Localized(spring, warsaw) + Day(1) + Hour(24)

@test explicit_hour_day == Localized(2015, 3, 31, 1, warsaw)
@test explicit_day_hour == Localized(2015, 3, 31, 0, warsaw)
@test implicit_hour_day == Localized(2015, 3, 31, 0, warsaw)
@test implicit_day_hour == Localized(2015, 3, 31, 0, warsaw)

# CompoundPeriod canonicalization interacting with period arithmetic. Since `spring_loc` is
# a 23 hour day this means adding `Day(1)` and `Hour(23)` are equivalent.
spring_loc = Localized(spring, warsaw)
@test spring_loc + Day(1) + Minute(1) == spring_loc + Hour(23) + Minute(1)

# When canonicalization happens automatically `Hour(24) + Minute(1)` is converted into
# `Day(1) + Minute(1)`. Fixed in `JuliaLang/julia#19268`
if VERSION >= v"0.6.0-dev.1874"
    @test spring_loc + Hour(23) + Minute(1) < spring_loc + Hour(24) + Minute(1)
else
    @test spring_loc + Hour(23) + Minute(1) == spring_loc + Hour(24) + Minute(1)
end

# Arithmetic with a StepRange should always work even when the start/stop lands on
# ambiguous or non-existent DateTimes.
ambiguous = DateTime(2015, 10, 25, 2)   # Ambiguous hour in Warsaw
nonexistent = DateTime(2014, 3, 30, 2)  # Non-existent hour in Warsaw

range = Localized(ambiguous - Day(1), warsaw):Hour(1):Localized(ambiguous - Day(1) + Hour(1), warsaw)
@test range .+ Day(1) == Localized(ambiguous, warsaw, 1):Hour(1):Localized(ambiguous + Hour(1), warsaw)

range = Localized(ambiguous - Day(1) - Hour(1), warsaw):Hour(1):Localized(ambiguous - Day(1), warsaw)
@test range .+ Day(1) == Localized(ambiguous - Hour(1), warsaw, 1):Hour(1):Localized(ambiguous, warsaw, 2)

range = Localized(nonexistent - Day(1), warsaw):Hour(1):Localized(nonexistent - Day(1) + Hour(1), warsaw)
@test range .+ Day(1) == Localized(nonexistent + Hour(1), warsaw):Hour(1):Localized(nonexistent + Hour(1), warsaw)

range = Localized(nonexistent - Day(1) - Hour(1), warsaw):Hour(1):Localized(nonexistent - Day(1), warsaw)
@test range .+ Day(1) == Localized(nonexistent - Hour(1), warsaw):Hour(1):Localized(nonexistent - Hour(1), warsaw)
