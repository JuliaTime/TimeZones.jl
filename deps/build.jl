import TimeZones.Olsen: REGIONS, generate_tzdata

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

#=
Need to make this code more reliable

LoadError: failed process: Process(`curl -o ~/.julia/v0.4/Timezones/deps/tzdata/asia -L ftp://ftp.iana.org/tz/data/asia`, ProcessExited(56)) [56]
while loading ~/.julia/v0.4/Timezones/deps/build.jl, in expression starting on line 18
=#
info("Downloading TZ data")
@sync for region in REGIONS
    @async download("ftp://ftp.iana.org/tz/data/"*region, joinpath(tz,region))
end

info("Pre-processing TimeZone data")
generate_tzdata(tz,com)

info("Successfully processed TimeZone data")
