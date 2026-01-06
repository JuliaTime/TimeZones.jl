# Use a separate cache for FixedTimeZone (which is `isbits`) so the container is concretely
# typed and we avoid allocating a FixedTimeZone every time we get one from the cache.
# Note: link uses InlineString31 (not Union{InlineString31,Nothing}) to keep tuples isbits.
# An empty string "" is used as a sentinel value for "no link target".
struct TimeZoneCache
    ftz::Dict{String,Tuple{FixedTimeZone,Class,InlineString31}}
    vtz::Dict{String,Tuple{VariableTimeZone,Class,InlineString31}}
    lock::ReentrantLock
    initialized::Threads.Atomic{Bool}
end

TimeZoneCache() = TimeZoneCache(Dict(), Dict(), ReentrantLock(), Threads.Atomic{Bool}(false))

# Retains the compiled tzdata in memory. Read-only access to the cache is thread-safe and
# any changes to this structure can result in inconsistent behaviour. Do not access this
# object directly, instead use `get` to access the cache content.
const _TZ_CACHE = TimeZoneCache()

function Base.copy!(dst::TimeZoneCache, src::TimeZoneCache)
    lock(dst.lock) do
        copy!(dst.ftz, src.ftz)
        copy!(dst.vtz, src.vtz)
        dst.initialized[] = src.initialized[]
    end
    return dst
end

function reload!(cache::TimeZoneCache, compiled_dir::AbstractString=_COMPILED_DIR[])
    empty!(cache.ftz)
    empty!(cache.vtz)

    walk_tz_dir(compiled_dir) do name, path
        tz, class, link = open(TZJFile.read, path, "r")(name)

        # Convert link to InlineString31 to keep tuples isbits
        # Use empty string as sentinel for "no link target"
        entry = (tz, class, link === nothing ? InlineString31("") : InlineString31(link))

        if tz isa FixedTimeZone
            cache.ftz[name] = entry
        elseif tz isa VariableTimeZone
            cache.vtz[name] = entry
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
                _build()
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

# Build specific tzdata version if specified by `JULIA_TZ_VERSION`
function _build()
    desired_version = TZData.tzdata_version()
    if desired_version != TZJData.TZDATA_VERSION
        _COMPILED_DIR[] = TZData.build(desired_version, _scratch_dir())
    end

    return nothing
end

_reload_tz_cache(compiled_dir::AbstractString) = reload!(_TZ_CACHE, compiled_dir)
