module TZFile

# The tzfile format specification can be found at:
# https://data.iana.org/time-zones/data/tzfile.5.txt

using Dates: Dates, DateTime, Second, datetime2unix, unix2datetime
using ...TimeZones: FixedTimeZone, VariableTimeZone, Transition, isdst

include("utils.jl")
include("read.jl")
include("write.jl")

end
