
dir = dirname(@__FILE__)
tz = joinpath(dir,"tzdata")
com = joinpath(dir,"compiled")

isdir(tz)  || mkdir(tz)
isdir(com) || mkdir(com)


for f in (tz,com)
    for file in readdir(f)
        rm(joinpath(f,file))
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

# include("../src/TimeZones.jl")
# TimeZones.Olsen.generate_tzdata(tz,com)
println("=========Timezone Database Successfully Compiled=========")
