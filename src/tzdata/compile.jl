using Compat.Dates, Compat.Serialization
import Compat.Dates: parse_components

import ...TimeZones: TZ_SOURCE_DIR, COMPILED_DIR, TIME_ZONES
import ...TimeZones: TimeZone, FixedTimeZone, VariableTimeZone, Transition
import ..TZData: TimeOffset, ZERO, MIN_GMT_OFFSET, MAX_GMT_OFFSET,
    MIN_SAVE, MAX_SAVE, ABS_DIFF_OFFSET

# Zone type maps to an Olson Timezone database entity
struct Zone
    gmtoffset::TimeOffset
    save::TimeOffset
    rules::AbstractString
    format::AbstractString
    until::Nullable{DateTime}
    until_flag::Char
end

function Base.isless(x::Zone,y::Zone)
    x_dt = get(x.until, typemax(DateTime))
    y_dt = get(y.until, typemax(DateTime))

    # Easy to compare until's if they are using the same flag. Alternatively, it should
    # be safe to compare different until flags if the DateTimes are far enough apart.
    if x.until_flag == y.until_flag || abs(x_dt - y_dt) > ABS_DIFF_OFFSET
        return isless(x_dt, y_dt)
    else
        error("Unable to compare zones when until datetimes are too close and flags are mixed")
    end
end

# Rules govern how Daylight Savings transitions happen for a given time zone
struct Rule
    from::Nullable{Int}  # First year rule applies
    to::Nullable{Int}    # Rule applies up until, but not including this year
    month::Int           # Month in which DST transition happens
    on::Function         # Anonymous boolean function to determine day
    at::TimeOffset       # Hour and minute at which the transition happens
    at_flag::Char        # Local wall time (w), UTC time (u), Local Standard time (s)
    save::TimeOffset     # How much time is "saved" in daylight savings transition
    letter::AbstractString  # Timezone abbr letter(s). ie. CKT ("") => CKHST ("HS")

    function Rule(
        from::Nullable{Int}, to::Nullable{Int}, month::Int, on::Function, at::TimeOffset,
        at_flag::Char, save::TimeOffset, letter::AbstractString,
    )
        isflag(at_flag) || throw(ArgumentError("Unhandled flag '$at_flag'"))
        new(from, to, month, on, at, at_flag, save, letter)
    end
end

const ZoneDict = Dict{AbstractString, Vector{Zone}}
const RuleDict = Dict{AbstractString, Vector{Rule}}
const OrderedRuleDict = Dict{AbstractString, Tuple{Vector{Date}, Vector{Rule}}}

# Min and max years that we create DST transition DateTimes for (inclusive)
const MIN_YEAR = year(typemin(DateTime))  # Essentially the begining of time
const MAX_YEAR = 2037                     # year(unix2datetime(typemax(Int32))) - 1

const DEFAULT_FLAG = 'w'

# Helper functions/data
const MONTHS = Dict(
    "Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4, "May" => 5, "Jun" => 6,
    "Jul" => 7, "Aug" => 8, "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12,
)

const DAYS = Dict(
    "Mon" => 1, "Tue" => 2, "Wed" => 3, "Thu" => 4, "Fri" => 5, "Sat" => 6, "Sun" => 7,
)

const LAST_DAY_OF_WEEK = Dict{String, Function}()

# Create adjuster functions such as `last_sunday`.
for (abbr, dayofweek) in DAYS
    str = "last" * abbr
    f = Symbol("last_" * lowercase(dayname(dayofweek)))
    LAST_DAY_OF_WEEK[str] = @eval begin
        function $f(dt)
            return dayofweek(dt) == $dayofweek &&
            dayofweekofmonth(dt) == daysofweekinmonth(dt)
        end
    end
end

# Generate various DateFormats based the number of periods provided.
const UNTIL_FORMATS = let
    parts = split("yyyy uuu dd HH:MM:SS", ' ')
    map(i -> DateFormat(join(parts[1:i], ' ')), eachindex(parts))
end


isflag(flag::Char) = flag in ('w', 'u', 's')

"""
    tryparse_dayofmonth(str::AbstractString) -> Union{Function,Nothing}

Parse the various day-of-month formats used within tzdata source files.

```julia
julia> tryparse_dayofmonth("lastSun")
last_sunday (generic function with 1 method)

julia> tryparse_dayofmonth("Sun>=8")
#15 (generic function with 1 method)

julia> TimeZones.TZData.tryparse_dayofmonth("15")
#16 (generic function with 1 method)
```
"""
function tryparse_dayofmonth(str::AbstractString)
    if occursin(r"^last\w{3}$", str)
        # We pre-built these functions above
        # They follow the format: "lastSun", "lastMon", etc.
        LAST_DAY_OF_WEEK[str]
    elseif (m = match(r"^(?<dow>\w{3})(?<op>[<>]=)(?<dom>\d{1,2})$", str)) !== nothing
        # The first day of the week that occurs before or after a given day of month.
        # i.e. Sun>=8 refers to the Sunday after the 8th of the month
        # or in other words, the 2nd Sunday.
        dow = DAYS[m[:dow]]
        dom = parse(Int, m[:dom])
        if m[:op] == "<="
            dt -> day(dt) <= dom && dayofweek(dt) == dow
        else
            dt -> day(dt) >= dom && dayofweek(dt) == dow
        end
    elseif occursin(r"^\d{1,2}$", str)
        # Matches just a plain old day of the month
        dom = parse(Int, str)
        dt -> day(dt) == dom
    else
        nothing
    end
end

# Olson time zone dates can be a single year (1900), yyyy-mm-dd (1900-Jan-01),
# or minute-precision (1900-Jan-01 2:00).
# They can also be given in Local Wall Time, UTC time (u), or Local Standard time (s)
function parse_date(s::AbstractString)
    period_strs = split(s, r"\s+")
    num_periods = length(period_strs)

    # Extract the flag when time is included
    if num_periods > 3 && isflag(s[end])
        flag = s[end]
        period_strs[end] = period_strs[end][1:end - 1]
    else
        flag = DEFAULT_FLAG
    end

    # Save the day of month string and substitute a non-numeric string for parsing.
    dom_str = num_periods >= 3 ? period_strs[3] : ""
    numeric_dom = all(isnumeric, dom_str)
    !numeric_dom && splice!(period_strs, 3, ["1"])

    periods = parse_components(join(period_strs, ' '), UNTIL_FORMATS[num_periods])

    # Roll over 24:00 to the next day which occurs in "Pacific/Apia" and "Asia/Macau".
    # Note: Apply the `shift` after we create the DateTime to ensure that roll over works
    # correctly at the end of the month or year.
    shift = Day(0)
    if num_periods > 3 && periods[4] == Hour(24)
        periods[4] = Hour(0)
        shift += Day(1)
    end
    dt = DateTime(periods...)

    # Adjust the DateTime to reflect the requirements of the day-of-month function.
    if !numeric_dom
        dom = tryparse_dayofmonth(dom_str)
        dom !== nothing || throw(ArgumentError("Unable to parse day-of-month: \"$dom_str\""))
        dt = tonext(dom, dt; step=Day(1), same=true)
    end

    dt += shift

    # Note: If the time is UTC, we add back the offset and any saved amount
    # If it's local standard time, we just need to add any saved amount
    # return letter == 's' ? (dt - save) : (dt - offset - save)
    return dt, flag
end

function asutc(dt::DateTime, flag::Char, offset::TimeOffset, save::TimeOffset)
    if flag == 'u'
        # In UTC
        return dt
    elseif flag == 'w'
        # In local wall time, add back offset and saved amount
        return dt - offset - save
    elseif flag == 's'
        # In local standard time, add back any saved amount
        return dt - offset
    else
        error("Unknown flag: $flag")
    end
end

function abbr_string(format::AbstractString, save::TimeOffset, letter::AbstractString="")
    # Note: using @sprintf would make sense but unfortunately it doesn't accept a
    # format as a variable.
    abbr = replace(format, "%s" => letter, count=1)

    # If the abbreviation contains a slash then the first string is the abbreviation
    # for standard time and the second is the abbreviation for daylight saving time.
    abbrs = split(abbr, '/')
    if length(abbrs) > 1
        abbr = save == ZERO ? first(abbrs) : last(abbrs)
    end

    # Some time zones (e.g. "Europe/Ulyanovsk") do not have abbreviations for the various
    # rules and instead hardcode the offset as the name.
    if occursin(r"[+-]\d{2}", abbr)
        abbr = ""
    end

    return abbr
end

function ruleparse(from, to, rule_type, month, on, at, save, letter)
    from_int = convert(Nullable{Int}, from == "min" ? nothing : parse(Int, from))
    to_int = convert(Nullable{Int}, to == "only" ? from_int : to == "max" ? nothing : parse(Int, to))
    month_int = MONTHS[month]

    # Now we need to get the right anonymous function
    # for determining the right day for transitioning
    on_func = tryparse_dayofmonth(on)
    on_func === nothing && error("Can't parse day of month for DST change: \"$on\"")

    # Now we get the time of the transition
    c = at[end]
    at_hm = TimeOffset(isflag(c) ? at[1:end-1] : at)
    at_flag = isflag(c) ? c : DEFAULT_FLAG
    save_hm = TimeOffset(save)
    letter = letter == "-" ? "" : letter

    # Report unexpected save values that could cause issues during resolve.
    save_hm < MIN_SAVE && @warn "Discovered save \"$save\" less than the expected min $MIN_SAVE"
    save_hm > MAX_SAVE && @warn "Discovered save \"$save\" larger than the expected max $MAX_SAVE"

    # Now we've finally parsed everything we need
    return Rule(
        from_int,
        to_int,
        month_int,
        on_func,
        at_hm,
        at_flag,
        save_hm,
        letter,
    )
end

function zoneparse(gmtoff, rules, format, until="")
    # Get our offset and abbreviation string for this period
    offset = TimeOffset(gmtoff)

    # Report unexpected offsets that could cause issues during resolve.
    offset < MIN_GMT_OFFSET && @warn "Discovered offset $offset less than the expected min $MIN_GMT_OFFSET"
    offset > MAX_GMT_OFFSET && @warn "Discovered offset $offset larger than the expected max $MAX_GMT_OFFSET"

    # "zzz" represents a NULL entry
    format = format == "zzz" ? "" : format

    # Parse the date the line rule applies up to
    until_tuple = until == "" ? (nothing, 'w') : parse_date(until)
    until_dt, until_flag = convert(Nullable{DateTime}, until_tuple[1]), until_tuple[2]

    if rules == "-" || occursin(r"\d", rules)
        save = TimeOffset(rules)
        rules = ""
    else
        save = ZERO
    end

    return Zone(
        offset,
        save,
        rules,
        format,
        until_dt,
        until_flag,
    )
end

"""
Rules are typically ordered by the "from" than "in" fields. Since rules also
contain a "to" field the written ordering can be problematic for resolving
time zone transitions.

Example:

    # Rule  NAME    FROM    TO  TYPE    IN  ON  AT      SAVE    LETTER/S
    Rule    Poland  1918    1919    -   Sep 16  2:00s   0       -
    Rule    Poland  1919    only    -   Apr 15  2:00s   1:00    S
    Rule    Poland  1944    only    -   Apr  3  2:00s   1:00    S

    A simplistic way of iterating through the rules by years could yield the rules
    in the wrong order:

    # ON         AT      SAVE    LETTER/S
    1918-09-16   2:00s   0       -
    1919-09-16   2:00s   0       -
    1919-04-15   2:00s   1:00    S
    1944-04-03   2:00s   1:00    S

    The order_rules function will expand the rules such that they can be ordered by the
    "on" date which ensures we process the rules in the correct order:

    1918-09-16   2:00s   0       -
    1919-04-15   2:00s   1:00    S
    1919-09-16   2:00s   0       -
    1944-04-03   2:00s   1:00    S
"""
function order_rules(rules::Vector{Rule}; max_year::Integer=MAX_YEAR)
    dates = Date[]
    ordered = Rule[]

    # Note: Typically rules are orderd by "from" and "in". Unfortunately
    for rule in rules
        start_year = max(get(rule.from, MIN_YEAR), MIN_YEAR)
        end_year = min(get(rule.to, max_year), max_year)

        # For each year the rule applies compute the transition date
        for rule_year in start_year:end_year
            # Determine the rule transition day by starting at the
            # beginning of the month and applying our "on" function
            # until we reach the correct day.
            date = Date(rule_year, rule.month)
            try
                # The "on" function should evaluate to a day within the current month.
                date = tonext(rule.on, date; same=true, limit=daysinmonth(date))
            catch e
                if isa(e, ArgumentError)
                    error("Unable to find matching day in month $(year(date))/$(month(date))")
                else
                    rethrow(e)
                end
            end
            push!(dates, date)
            push!(ordered, rule)
        end
    end

    perm = sortperm(dates)
    dates = dates[perm]
    ordered = ordered[perm]

    # Since we are not yet taking offsets or flags into account yet
    # there is a small chance that the results are not ordered correctly.
    last_date = typemin(Date)
    for (i, date) in enumerate(dates)
        if i > 1 && date - last_date <= ABS_DIFF_OFFSET
            error("Dates are probably not in order")
        end
        last_date = date
    end

    return dates, ordered
end

"""
Resolves a named zone into TimeZone. Updates ordered with any new rules that
were required to be ordered.
"""
function resolve!(zone_name::AbstractString, zoneset::ZoneDict, ruleset::RuleDict,
    ordered::OrderedRuleDict; max_year::Integer=MAX_YEAR, debug=false)

    transitions = Transition[]
    cutoff = Nullable{DateTime}()

    # Set some default values and starting DateTime increment and away we go...
    start_utc = DateTime(MIN_YEAR)
    max_until = DateTime(max_year, 12, 31, 23, 59, 59)
    save = ZERO
    letter = ""
    start_rule = Nullable{Rule}()

    # zones = Set{FixedTimeZone}()

    # Zone needs to be in ascending order to ensure that start_utc is being applied
    # to the correct transition.
    for zone in sort(zoneset[zone_name])

        # Break at the beginning of the loop instead of the end so that we know an
        # future zone exists beyond max_year and we can set cutoff.
        if year(start_utc) > max_year
            cutoff = Nullable(start_utc)
            break
        end

        offset = zone.gmtoffset
        format = zone.format
        # save = zone.save
        rule_name = zone.rules
        until = get(zone.until, max_until)
        cutoff = Nullable{DateTime}()  # Reset cutoff

        if rule_name == ""
            save = zone.save
            abbr = abbr_string(format, save)

            if debug
                rule_name = "\"\""  # Just for display purposes
                println("Zone Start $rule_name, $(zone.gmtoffset), $save, $(start_utc)u, $(until)$(zone.until_flag), $abbr")
            end

            tz = FixedTimeZone(abbr, Second(offset), Second(save))
            if isempty(transitions) || last(transitions).zone != tz
                push!(transitions, Transition(start_utc, tz))
            end
        else
            # Only order the rule if it hasn't already been processed. We'll go one year
            # further than the max_year to ensure we get an accurate cutoff DateTime.
            if !haskey(ordered, rule_name)
                ordered[rule_name] = order_rules(ruleset[rule_name]; max_year=max_year + 1)
            end

            dates, rules = ordered[rule_name]

            # TODO: We could avoid this search if the rule_name haven't changed since the
            # last iteration.
            index = searchsortedlast(dates, start_utc)

            if !isnull(start_rule)
                rule = get(start_rule)
                save = rule.save
                letter = rule.letter

                start_rule = Nullable{Rule}()
            elseif index == 0
                save = ZERO

                # Find the first occurrence of of standard-time
                for rule in rules
                    if rule.save == save
                        letter = rule.letter
                        break
                    end
                end
            else
                rule = rules[index]
                save = rule.save
                letter = rule.letter
            end
            abbr = abbr_string(format, save, letter)

            debug && println("Zone Start $rule_name, $(zone.gmtoffset), $save, $(start_utc)u, $(until)$(zone.until_flag), $abbr")

            tz = FixedTimeZone(abbr, Second(offset), Second(save))
            if isempty(transitions) || last(transitions).zone != tz
                push!(transitions, Transition(start_utc, tz))
            end

            index = max(index, 1)
            for (date, rule) in zip(dates[index:end], rules[index:end])
                # Add "at" since it could be larger than 23:59:59.
                dt = DateTime(date) + rule.at

                # Convert rule and until datetimes into UTC using the latest
                # offset and save values that occurred prior to this rule.
                dt_utc = asutc(dt, rule.at_flag, offset, save)
                until_utc = asutc(until, zone.until_flag, offset, save)

                if dt_utc == until_utc
                    start_rule = Nullable{Rule}(rule)
                elseif dt_utc > until_utc
                    cutoff = Nullable{DateTime}(dt_utc)
                end

                dt_utc >= until_utc && break

                # Need to be careful when we update save/letter.
                save = rule.save
                letter = rule.letter
                abbr = abbr_string(format, save, letter)

                if debug
                    status = dt_utc >= start_utc ? "Rule" : "Skip"
                    println("$status $(year(date)), $(dt)$(rule.at_flag), $(dt_utc)u, $save, $abbr")
                end

                # TODO: Is start_utc inclusive or exclusive?
                dt_utc >= start_utc || continue

                tz = FixedTimeZone(abbr, Second(offset), Second(save))

                # TODO: We can maybe reduce memory usage by reusing the same
                # FixedTimeZone object.
                # Note: By default pushing onto a set will replace objects.
                # if !(tz in zones)
                #     push!(zones, tz)
                # else
                #     tz = first(intersect(zones, Set([tz])))
                # end

                if isempty(transitions) || last(transitions).zone != tz
                    push!(transitions, Transition(dt_utc, tz))
                end
            end
        end

        start_utc = asutc(until, zone.until_flag, offset, save)
        debug && println("Zone End   $rule_name, $offset, $save, $(start_utc)u")
    end

    debug && println("Cutoff     $(isnull(cutoff) ? "nothing" : get(cutoff))")

    # Note: Transitions array is expected to be ordered and should be if both
    # zones and rules were ordered.
    if length(transitions) > 1 || !isnull(cutoff)
        return VariableTimeZone(zone_name, transitions, cutoff)
    else
        # Although unlikely the time zone name in the transition and the zone_name
        # could be different.
        offset = first(transitions).zone.offset
        return FixedTimeZone(zone_name, offset)
    end
end

function resolve(zoneset::ZoneDict, ruleset::RuleDict; max_year::Integer=MAX_YEAR, debug=false)
    ordered = OrderedRuleDict()
    timezones = Dict{AbstractString,TimeZone}()

    for zone_name in keys(zoneset)
        tz = resolve!(zone_name, zoneset, ruleset, ordered; max_year=max_year, debug=debug)
        timezones[zone_name] = tz
    end

    return timezones
end

function resolve(zone_name::AbstractString, zoneset::ZoneDict, ruleset::RuleDict; max_year::Integer=MAX_YEAR, debug=false)
    ordered = OrderedRuleDict()
    return resolve!(zone_name, zoneset, ruleset, ordered; max_year=max_year, debug=debug)
end

function tzparse(tz_source_file::AbstractString)
    zones = ZoneDict()
    rules = RuleDict()
    links = Dict{AbstractString,AbstractString}()

    # For the intial pass we'll collect the zone and rule lines.
    open(tz_source_file) do fp
        kind = name = ""
        for line in eachline(fp)
            # Lines that start with whitespace can be considered a "continuation line"
            # which means the last found kind/name should persist.
            persist = occursin(r"^\s", line)

            line = strip(replace(chomp(line), r"#.*$" => ""))
            length(line) > 0 || continue
            line = replace(line, r"\s+" => " ")

            if !persist
                kind, name, line = split(line, ' '; limit=3)
            end

            if kind == "Rule"
                rule = ruleparse(split(line, ' ')...)
                rules[name] = push!(get(rules, name, Rule[]), rule)
            elseif kind == "Zone"
                zone = zoneparse(split(line, ' '; limit=4)...)
                zones[name] = push!(get(zones, name, Zone[]), zone)
            elseif kind == "Link"
                dest = line
                links[dest] = name
            else
                @warn "Unhandled line found with type: $kind"
            end
        end
    end

    # Turn links into zones.
    # Note: it would be more computationally efficient to pass the links around
    # and only resolve a zone once.
    for (dest, source) in links
        zones[dest] = zones[source]
    end

    return zones, rules
end

function load(tz_source_dir::AbstractString=TZ_SOURCE_DIR; max_year::Integer=MAX_YEAR)
    timezones = Dict{AbstractString,TimeZone}()
    for filename in readdir(tz_source_dir)
        zones, rules = tzparse(joinpath(tz_source_dir, filename))
        merge!(timezones, resolve(zones, rules; max_year=max_year))
    end
    return timezones
end

function compile(tz_source_dir::AbstractString=TZ_SOURCE_DIR, dest_dir::AbstractString=COMPILED_DIR; max_year::Integer=MAX_YEAR)
    timezones = load(tz_source_dir; max_year=max_year)

    isdir(dest_dir) || error("Destination directory doesn't exist")
    empty!(TIME_ZONES)

    for (name, timezone) in timezones
        parts = split(name, "/")
        tz_dir, tz_file = joinpath(dest_dir, parts[1:end-1]...), parts[end]

        isdir(tz_dir) || mkpath(tz_dir)

        open(joinpath(tz_dir, tz_file), "w") do fp
            serialize(fp, timezone)
        end
    end
end
