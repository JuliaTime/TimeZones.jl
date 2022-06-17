module TZJFile

using Dates: Dates, DateTime, Second, datetime2unix, unix2datetime
using ...TimeZones: Class, FixedTimeZone, Transition, VariableTimeZone, iscomposite, isdst
using ...TimeZones.TZFile: transition_min, assemble_designations, DATETIME_EPOCH, abbreviation

const DEFAULT_VERSION = 1
const TIMESTAMP_MIN = transition_min(Int64)

include("utils.jl")
include("read.jl")
include("write.jl")

end
