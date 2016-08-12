import Base.Dates: Day, Hour

warsaw = resolve("Europe/Warsaw", tzdata["europe"]...)

normal = DateTime(2015, 1, 1, 0)   # 24 hour day in warsaw
spring = DateTime(2015, 3, 29, 0)  # 23 hour day in warsaw
fall = DateTime(2015, 10, 25, 0)   # 25 hour day in warsaw

# Unary plus
@test +ZonedDateTime(normal, warsaw) == ZonedDateTime(normal, warsaw)

# Period arithmetic
@test ZonedDateTime(normal, warsaw) + Day(1) == ZonedDateTime(normal + Day(1), warsaw)
@test ZonedDateTime(spring, warsaw) + Day(1) == ZonedDateTime(spring + Day(1), warsaw)
@test ZonedDateTime(fall, warsaw) + Day(1) == ZonedDateTime(fall + Day(1), warsaw)

@test ZonedDateTime(normal, warsaw) + Hour(24) == ZonedDateTime(normal + Hour(24), warsaw)
@test ZonedDateTime(spring, warsaw) + Hour(24) == ZonedDateTime(spring + Hour(25), warsaw)
@test ZonedDateTime(fall, warsaw) + Hour(24) == ZonedDateTime(fall + Hour(23), warsaw)

# Do the same calculations but backwards over the transitions.
@test ZonedDateTime(normal + Day(1), warsaw) - Day(1) == ZonedDateTime(normal, warsaw)
@test ZonedDateTime(spring + Day(1), warsaw) - Day(1) == ZonedDateTime(spring, warsaw)
@test ZonedDateTime(fall + Day(1), warsaw) - Day(1) == ZonedDateTime(fall, warsaw)

@test ZonedDateTime(normal + Day(1), warsaw) - Hour(24) == ZonedDateTime(normal, warsaw)
@test ZonedDateTime(spring + Day(1), warsaw) - Hour(23) == ZonedDateTime(spring, warsaw)
@test ZonedDateTime(fall + Day(1), warsaw) - Hour(25) == ZonedDateTime(fall, warsaw)

# Ensure that arithmetic around transitions works.
@test ZonedDateTime(spring, warsaw) + Hour(1) == ZonedDateTime(spring + Hour(1), warsaw)
@test ZonedDateTime(spring, warsaw) + Hour(2) == ZonedDateTime(spring + Hour(3), warsaw)
@test ZonedDateTime(fall, warsaw) + Hour(2) == ZonedDateTime(fall + Hour(2), warsaw, 1)
@test ZonedDateTime(fall, warsaw) + Hour(3) == ZonedDateTime(fall + Hour(2), warsaw, 2)

# Non-Associativity
hour_day = (ZonedDateTime(spring, warsaw) + Hour(24)) + Day(1)
day_hour = (ZonedDateTime(spring, warsaw) + Day(1)) + Hour(24)

@test hour_day - day_hour == Hour(1)


# Arithmetic with a StepRange should always work even when the start/stop lands on
# ambiguous or non-existent DateTimes.
ambiguous = DateTime(2015, 10, 25, 2)  # Ambiguous hour in Warsaw
nonexistent = DateTime(2014, 3, 30, 2)  # Non-existent hour in Warsaw

range = ZonedDateTime(ambiguous - Day(1), warsaw):Hour(1):ZonedDateTime(ambiguous - Day(1) + Hour(1), warsaw)
@test range .+ Day(1) == ZonedDateTime(ambiguous, warsaw, 1):Hour(1):ZonedDateTime(ambiguous + Hour(1), warsaw)

range = ZonedDateTime(ambiguous - Day(1) - Hour(1), warsaw):Hour(1):ZonedDateTime(ambiguous - Day(1), warsaw)
@test range .+ Day(1) == ZonedDateTime(ambiguous - Hour(1), warsaw, 1):Hour(1):ZonedDateTime(ambiguous, warsaw, 2)

range = ZonedDateTime(nonexistent - Day(1), warsaw):Hour(1):ZonedDateTime(nonexistent - Day(1) + Hour(1), warsaw)
@test range .+ Day(1) == ZonedDateTime(nonexistent + Hour(1), warsaw):Hour(1):ZonedDateTime(nonexistent + Hour(1), warsaw)

range = ZonedDateTime(nonexistent - Day(1) - Hour(1), warsaw):Hour(1):ZonedDateTime(nonexistent - Day(1), warsaw)
@test range .+ Day(1) == ZonedDateTime(nonexistent - Hour(1), warsaw):Hour(1):ZonedDateTime(nonexistent - Hour(1), warsaw)
