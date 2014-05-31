using Dates
include("../src/tzcompile.jl")
mkdir(dirname(@__FILE__)*"/compiled/")
generate_tzdata(dirname(@__FILE__)*"/tzdata/",
                dirname(@__FILE__)*"/compiled/")
println("=========Timezone Database Successfully Compiled=========")
