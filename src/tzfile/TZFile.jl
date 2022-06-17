module TZFile

# The tzfile format specification can be found at:
# https://data.iana.org/time-zones/data/tzfile.5.txt

using Dates: Dates, DateTime, Second, datetime2unix, unix2datetime
using ...TimeZones: FixedTimeZone, VariableTimeZone, Transition, isdst

const SUPPORTED_VERSIONS = ('\0', '1', '2', '3', '4')
const LATEST_VERSION = last(SUPPORTED_VERSIONS)

include("utils.jl")
include("read.jl")
include("write.jl")

end
