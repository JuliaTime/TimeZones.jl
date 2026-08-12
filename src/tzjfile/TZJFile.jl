module TZJFile

using Dates: Dates, DateTime, Second, datetime2unix, unix2datetime
using ...TimeZones: FixedTimeZone, VariableTimeZone, Class, Transition
using ...TimeZones.TZFile: combine_designations, get_designation, timestamp_min

const DEFAULT_VERSION = 2

"""
    tzjfile_version() -> Int

Returns the TZJFile format version to use, controlled by the `JULIA_TZJ_VERSION` environment
variable. If not set, defaults to `DEFAULT_VERSION` (currently $DEFAULT_VERSION).

This allows users to opt-in or opt-out of new file format versions for testing or
compatibility purposes.

# Examples
```julia
# Use default version (currently 2)
julia> TZJFile.tzjfile_version()
2

# Use version 1 via environment variable
julia> ENV["JULIA_TZJ_VERSION"] = "1"
julia> TZJFile.tzjfile_version()
1
```
"""
function tzjfile_version()
    version_str = get(ENV, "JULIA_TZJ_VERSION", string(DEFAULT_VERSION))
    version = tryparse(Int, version_str)
    version === nothing && error("Invalid JULIA_TZJ_VERSION: \"$version_str\". Must be an integer (1 or 2).")
    version ∉ (1, 2) && error("Unsupported JULIA_TZJ_VERSION: $version. Must be 1 or 2.")
    return version
end

include("utils.jl")
include("read.jl")
include("write.jl")

end
