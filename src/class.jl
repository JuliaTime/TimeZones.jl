const NONE     = 0x00
const FIXED    = 0x01
const STANDARD = 0x02
const LEGACY   = 0x04

const DEFAULT_MASK = STANDARD | FIXED

"""
    _timezone_class(str::AbstractString) -> UInt8

Classifies the provided time zone string.
"""
function _timezone_class(str::AbstractString)
    if occursin(FIXED_TIME_ZONE_REGEX, str)
        FIXED
    elseif str in TIME_ZONE_NAMES[STANDARD]
        STANDARD
    elseif str in TIME_ZONE_NAMES[LEGACY]
        LEGACY
    else
        NONE
    end
end

function _class_name(class::UInt8)
    if class == NONE
        "NONE"
    elseif class == FIXED
        "FIXED"
    elseif class == STANDARD
        "STANDARD"
    elseif class == LEGACY
        "LEGACY"
    else
        "UNKNOWN"
    end
end
