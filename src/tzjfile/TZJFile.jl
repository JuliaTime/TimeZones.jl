module TZJFile

using Dates: Dates, DateTime, Second, datetime2unix, unix2datetime
using ...TimeZones: FixedTimeZone, VariableTimeZone, Class, Transition
using ...TimeZones.TZFile: abbreviation, combine_designations, timestamp_min

const DEFAULT_VERSION = 1

include("utils.jl")
include("read.jl")
include("write.jl")

end
