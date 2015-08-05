
dir = dirname(@__FILE__)
tz = joinpath(dir, "tzdata")
com = joinpath(dir, "compiled")

isdir(tz)  || mkdir(tz)
isdir(com) || mkdir(com)

# Remove all contents in tz and com directories.
for d in (tz, com)
    for file in readdir(d)
        rm(joinpath(d, file), recursive=true)
    end
end

regions = ["africa","antarctica","asia","australasia",
           "europe","northamerica","southamerica"]

#=
Need to make this code more reliable

LoadError: failed process: Process(`curl -o /Users/omus/.julia/v0.4/Timezones/deps/tzdata/asia -L ftp://ftp.iana.org/tz/data/asia`, ProcessExited(56)) [56]
while loading /Users/omus/.julia/v0.4/Timezones/deps/build.jl, in expression starting on line 18
=#
@sync for reg in regions
    @async download("ftp://ftp.iana.org/tz/data/"*reg,joinpath(tz,reg))
end

include("../src/TimeZones.jl")
TimeZones.Olsen.generate_tzdata(tz,com)
println("=========Timezone Database Successfully Compiled=========")
