import TimeZones: timezone_names

names = timezone_names()

@test length(names) >= 429
@test isa(names, Array{AbstractString})
@test issorted(names)
