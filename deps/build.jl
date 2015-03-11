
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
for reg in regions
    download("ftp://ftp.iana.org/tz/data/"*reg,joinpath(tz,reg))
end

include("../src/TZCompile.jl")
TZCompile.generate_tzdata(tz,com)
println("=========Timezone Database Successfully Compiled=========")
