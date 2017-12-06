import Base: @deprecate_binding, @deprecate

# BEGIN TimeZones 0.4 deprecations

import TimeZones.TZData: REGIONS, LEGACY_REGIONS

# We forgot to remove these deprecates during the switch to 0.5
@deprecate_binding Olson TZData
@deprecate_binding TZDATA_DIR TZ_SOURCE_DIR

# END TimeZones 0.4 deprecations

# BEGIN TimeZones 0.5 deprecations
# END TimeZones 0.5 deprecations
