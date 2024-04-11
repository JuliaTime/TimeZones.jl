# Retains the compiled tzdata in memory. Read-only access is thread-safe and any changes
# to this structure can result in inconsistent behaviour.
# Do not access this object directly, instead use `get_tz_cache()` to access the cache.
const _TZ_CACHE = Dict{String,Tuple{TimeZone,Class}}()

function _reload_cache(compiled_dir::AbstractString)
    _reload_cache!(_TZ_CACHE, compiled_dir)
    !isempty(_TZ_CACHE) || error("Cache remains empty after loading")
    return nothing
end

function _reload_cache!(cache::AbstractDict, compiled_dir::AbstractString)
    empty!(cache)
    check = Tuple{String,String}[(compiled_dir, "")]

    for (dir, partial) in check
        for filename in readdir(dir)
            startswith(filename, ".") && continue

            path = joinpath(dir, filename)
            name = isempty(partial) ? filename : join([partial, filename], "/")

            if isdir(path)
                push!(check, (path, name))
            else
                cache[name] = open(TZJFile.read, path, "r")(name)
            end
        end
    end

    return cache
end

const _TZ_CACHE_INITIALIZED = Threads.Atomic{Bool}(false)
function initialize_tz_cache()
    # Write out our compiled tzdata representations into a scratchspace
    desired_version = TZData.tzdata_version()

    _COMPILED_DIR[] = if desired_version == TZJData.TZDATA_VERSION
        TZJData.ARTIFACT_DIR
    else
        @info "Loading tzdata $desired_version"
        TZData.build(desired_version, _scratch_dir())
    end

    # Load the pre-computed TZData into memory.
    _reload_cache(_COMPILED_DIR[])
    _TZ_CACHE_INITIALIZED[] = true

    return nothing
end

const _TZ_CACHE_LOCK = ReentrantLock()
function get_tz_cache()
    if  !_TZ_CACHE_INITIALIZED[]
        lock(_TZ_CACHE_LOCK) do
            if !_TZ_CACHE_INITIALIZED[]
                initialize_tz_cache()
            end
        end
    end
    return _TZ_CACHE
end


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
    tz, class = get(get_tz_cache(), str) do
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
    tz_class = get(get_tz_cache(), str, nothing)
    tz_class === nothing && return false
    if tz_class === nothing
        return false
    else
        _, class = tz_class
        return mask & class != Class(:NONE)
    end
end
