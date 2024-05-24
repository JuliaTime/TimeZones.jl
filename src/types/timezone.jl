# Use a separate cache for FixedTimeZone (which is `isbits`) so the container is concretely
# typed and we avoid allocating a FixedTimeZone every time we get one from the cache.
struct TimeZoneCache
    ftz::Dict{String,Tuple{FixedTimeZone,Class}}
    vtz::Dict{String,Tuple{VariableTimeZone,Class}}
    lock::ReentrantLock
    initialized::Threads.Atomic{Bool}
end

TimeZoneCache() = TimeZoneCache(Dict(), Dict(), ReentrantLock(), Threads.Atomic{Bool}(false))

# Retains the compiled tzdata in memory. Read-only access to the cache is thread-safe and
# any changes to this structure can result in inconsistent behaviour. Do not access this
# object directly, instead use `get` to access the cache content.
const _TZ_CACHE = TimeZoneCache()

function Base.copy!(dst::TimeZoneCache, src::TimeZoneCache)
    copy!(dst.ftz, src.ftz)
    copy!(dst.vtz, src.vtz)
    dst.initialized[] = src.initialized[]
    return dst
end

function reload!(cache::TimeZoneCache, compiled_dir::AbstractString=_COMPILED_DIR[])
    empty!(cache.ftz)
    empty!(cache.vtz)

    walk_tz_dir(compiled_dir) do name, path
        tz, class = open(TZJFile.read, path, "r")(name)

        if tz isa FixedTimeZone
            cache.ftz[name] = (tz, class)
        elseif tz isa VariableTimeZone
            cache.vtz[name] = (tz, class)
        else
            error("Unhandled TimeZone class encountered: $(typeof(tz))")
        end
    end

    !isempty(cache.ftz) && !isempty(cache.vtz) || error("Cache remains empty after loading")

    return cache
end

function Base.get(body::Function, cache::TimeZoneCache, name::AbstractString)
    if !cache.initialized[]
        lock(cache.lock) do
            if !cache.initialized[]
                _initialize()
                reload!(cache)
                cache.initialized[] = true
            end
        end
    end

    return get(cache.ftz, name) do
        get(cache.vtz, name) do
            body()
        end
    end
end

function _initialize()
    # Write out our compiled tzdata representations into a scratchspace
    desired_version = TZData.tzdata_version()

    _COMPILED_DIR[] = if desired_version == TZJData.TZDATA_VERSION
        TZJData.ARTIFACT_DIR
    else
        TZData.build(desired_version, _scratch_dir())
    end

    return nothing
end

_reload_tz_cache(compiled_dir::AbstractString) = reload!(_TZ_CACHE, compiled_dir)

"""
    TimeZone(str::AbstractString) -> TimeZone

Constructs a `TimeZone` subtype based upon the string. If the string is a recognized
standard time zone name then data is loaded from the compiled IANA time zone database.
Otherwise the string is parsed as a fixed time zone.

A list of recognized standard and legacy time zones names can is available by running
`timezone_names()`. Supported fixed time zone string formats can be found in docstring for
[`FixedTimeZone(::AbstractString)`](@ref).

## Examples
```jldoctest
julia> TimeZone("Europe/Warsaw")
Europe/Warsaw (UTC+1/UTC+2)

julia> TimeZone("UTC")
UTC
```
"""
TimeZone(::AbstractString)

"""
    TimeZone(str::AbstractString, mask::Class) -> TimeZone

Similar to [`TimeZone(::AbstractString)`](@ref) but allows you to control what time zone
classes are allowed to be constructed with `mask`. Can be used to construct time zones
which are classified as "legacy".

## Examples
```jldoctest
julia> TimeZone("US/Pacific")
ERROR: ArgumentError: The time zone "US/Pacific" is of class `TimeZones.Class(:LEGACY)` which is currently not allowed by the mask: `TimeZones.Class(:FIXED) | TimeZones.Class(:STANDARD)`

julia> TimeZone("US/Pacific", TimeZones.Class(:LEGACY))
US/Pacific (UTC-8/UTC-7)
```
"""
TimeZone(::AbstractString, ::Class)

function TimeZone(str::AbstractString, mask::Class=Class(:DEFAULT))
    tz, class = get(_TZ_CACHE, str) do
        if occursin(FIXED_TIME_ZONE_REGEX, str)
            FixedTimeZone(str), Class(:FIXED)
        else
            throw(ArgumentError("Unknown time zone \"$str\""))
        end
    end

    if mask & class == Class(:NONE)
        throw(ArgumentError(
            "The time zone \"$str\" is of class `$(repr(class))` which is " *
            "currently not allowed by the mask: `$(repr(mask))`"
        ))
    end

    return tz
end

"""
    @tz_str -> TimeZone

Constructs a `TimeZone` subtype based upon the string at parse time. See docstring of
`TimeZone` for more details.

```julia
julia> tz"Africa/Nairobi"
Africa/Nairobi (UTC+3)
```
"""
macro tz_str(str)
    TimeZone(str)
end

"""
    istimezone(str::AbstractString, mask::Class=Class(:DEFAULT)) -> Bool

Check whether a string is a valid for constructing a `TimeZone` with the provided `mask`.
"""
function istimezone(str::AbstractString, mask::Class=Class(:DEFAULT))
    # Start by performing quick FIXED class test
    if mask & Class(:FIXED) != Class(:NONE) && occursin(FIXED_TIME_ZONE_REGEX, str)
        return true
    end

    # Checks against pre-compiled time zones
    class = get(() -> (UTC_ZERO, Class(:NONE)), _TZ_CACHE, str)[2]
    return mask & class != Class(:NONE)
end
