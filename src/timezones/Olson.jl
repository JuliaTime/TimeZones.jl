module Olson

using Base.Dates

import ..TimeZones: TZDATA_DIR, COMPILED_DIR, ZERO, MIN_GMT_OFFSET, MAX_GMT_OFFSET,
    MIN_SAVE, MAX_SAVE, ABS_DIFF_OFFSET, Time, toseconds
import ..TimeZones: TimeZone, FixedTimeZone, VariableTimeZone, Transition, Time

const REGIONS = (
    "africa", "antarctica", "asia", "australasia",
    "europe", "northamerica", "southamerica",
)

# Zone type maps to an Olson Timezone database entity
type Zone
    gmtoffset::Time
    save::Time
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

# Rules govern how Daylight Savings transitions happen for a given timezone
type Rule
    from::Nullable{Int}  # First year rule applies
    to::Nullable{Int}    # Rule applies up until, but not including this year
    month::Int           # Month in which DST transition happens
    on::Function         # Anonymous boolean function to determine day
    at::Time             # Hour and minute at which the transition happens
    at_flag::Char        # Local wall time (w), UTC time (u), Local Standard time (s)
    save::Time           # How much time is "saved" in daylight savings transition
    letter::AbstractString  # Timezone abbr letter(s). ie. CKT ("") => CKHST ("HS")
end

typealias ZoneDict Dict{AbstractString,Array{Zone}}
typealias RuleDict Dict{AbstractString,Array{Rule}}
typealias OrderedRuleDict Dict{AbstractString,Array{Tuple{Date,Rule}}}

# Min and max years that we create DST transition instants for (inclusive)
const MINYEAR = 1800
const MAXYEAR = 2038

const MINDATETIME = DateTime(MINYEAR,1,1)
const MAXDATETIME = DateTime(MAXYEAR,12,31)

# Helper functions/data
const MONTHS = Dict("Jan"=>1,"Feb"=>2,"Mar"=>3,"Apr"=>4,"May"=>5,"Jun"=>6,
                "Jul"=>7,"Aug"=>8,"Sep"=>9,"Oct"=>10,"Nov"=>11,"Dec"=>12)

const DAYS = Dict("Mon"=>1,"Tue"=>2,"Wed"=>3,"Thu"=>4,"Fri"=>5,"Sat"=>6,"Sun"=>7)

# Create adjuster functions such as "lastSun".
for (abbr, dayofweek) in DAYS
    sym = symbol("last" * abbr)
    @eval (
        function $sym(dt)
            return dayofweek(dt) == $dayofweek &&
            dayofweekofmonth(dt) == daysofweekinmonth(dt)
        end
    )
end


function parseflag(s::AbstractString)
    if s == "" || s == "w"
        return 'w'
    elseif s == "u"
        return 'u'
    elseif s == "s"
        return 's'
    else
        error("Unhandled flag $s")
    end
end

# Olson timezone dates can be a single year (1900), yyyy-mm-dd (1900-Jan-01),
# or minute-precision (1900-Jan-01 2:00).
# They can also be given in Local Wall Time, UTC time (u), or Local Standard time (s)
function parsedate(s::AbstractString)
    s = replace(s, r"\s+", " ")
    num_periods = length(split(s, " "))
    s, flag = num_periods > 3 && isalpha(s[end]) ? (s[1:end-1], s[end:end]) : (s, "")
    if contains(s,"lastSun")
        dt = DateTime(replace(s, "lastSun", "1", 1), "yyyy uuu d H:MM:SS")
        dt = tonext(lastSun, dt; same=true)
    elseif contains(s,"lastSat")
        dt = DateTime(replace(s, "lastSat", "1", 1), "yyyy uuu d H:MM:SS")
        dt = tonext(lastSat, dt; same=true)
    elseif contains(s,"Sun>=1")
        dt = DateTime(replace(s,"Sun>=", "", 1),"yyyy uuu d H:MM:SS")
        dt = tonext(d -> dayofweek(d) == Sun, dt; same=true)
    else
        format = join(split("yyyy uuu dd HH:MM:SS", " ")[1:num_periods], ' ')
        periods = Dates.parse(s, DateFormat(format))

        # Deal with zone "Pacific/Apia" which has a 24:00 datetime.
        if length(periods) > 3 && periods[4] == Hour(24)
            periods[4] = Hour(0)
            periods[3] += Day(1)
        end
        dt = DateTime(periods...)
    end

    # TODO: I feel like there are issues here.
    # If the time is UTC, we add back the offset and any saved amount
    # If it's local standard time, we just need to add any saved amount
    # return letter == 's' ? (dt - save) : (dt - offset - save)

    return dt, parseflag(flag)
end

function asutc(dt::DateTime, flag::Char, offset::Time, save::Time)
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

function ruleparse(from, to, rule_type, month, on, at, save, letter)
    from_int = Nullable{Int}(from == "min" ? nothing : parse(Int, from))
    to_int = Nullable{Int}(to == "only" ? from_int : to == "max" ? nothing : parse(Int, to))
    month_int = MONTHS[month]

    # Now we need to get the right anonymous function
    # for determining the right day for transitioning
    if ismatch(r"last\w\w\w", on)
        # We pre-built these functions above
        # They follow the format: "lastSun", "lastMon".
        on_func = eval(symbol(on))
    elseif ismatch(r"\w\w\w[<>]=\d\d?", on)
        # The first day of the week that occurs before or after a given day of month.
        # i.e. Sun>=8 refers to the Sunday after the 8th of the month
        # or in other words, the 2nd Sunday.
        dow = DAYS[match(r"\w\w\w", on).match]
        dom = parse(Int, match(r"\d\d?", on).match)
        if ismatch(r"<=", on)
            on_func = @eval (dt -> day(dt) <= $dom && dayofweek(dt) == $dow)
        else
            on_func = @eval (dt -> day(dt) >= $dom && dayofweek(dt) == $dow)
        end
    elseif ismatch(r"\d\d?", on)
        # Matches just a plain old day of the month
        dom = parse(Int, on)
        on_func = @eval (dt -> day(dt) == $dom)
    else
        error("Can't parse day of month for DST change")
    end
    # Now we get the time of the transition
    c = at[end:end]
    at_hm = Time(isalpha(c) ? at[1:end-1] : at)
    at_flag = parseflag(isalpha(c) ? c : "")
    save_hm = Time(save)
    letter = letter == "-" ? "" : letter

    # Report unexpected save values that could cause issues during resolve.
    save_hm < MIN_SAVE && warn("Discovered save $save_hm less than the expected min $MIN_SAVE")
    save_hm > MAX_SAVE && warn("Discovered save $save_hm larger than the expected max $MAX_SAVE")

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
    offset = Time(gmtoff)

    # Report unexpected offsets that could cause issues during resolve.
    offset < MIN_GMT_OFFSET && warn("Discovered offset $offset less than the expected min $MIN_GMT_OFFSET")
    offset > MAX_GMT_OFFSET && warn("Discovered offset $offset larger than the expected max $MAX_GMT_OFFSET")

    format = format == "zzz" ? "" : format

    # Parse the date the line rule applies up to
    until_tuple = until == "" ? (nothing, 'w') : parsedate(until)
    until_dt, until_flag = Nullable{DateTime}(until_tuple[1]), until_tuple[2]

    if rules == "-" || ismatch(r"\d",rules)
        save = Time(rules)
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
timezone transitions.

Example:

    # Rule  NAME    FROM    TO  TYPE    IN  ON  AT      SAVE    LETTER/S
    Rule    Poland  1918    1919    -   Sep 16  2:00s   0       -
    Rule    Poland  1919    only    -   Apr 15  2:00s   1:00    S
    Rule    Poland  1944    only    -   Apr  3  2:00s   1:00    S

    Processing rules by iterating through years would generate:

    # ON         AT      SAVE    LETTER/S
    1918-09-16   2:00s   0       -
    1919-09-16   2:00s   0       -
    1919-04-15   2:00s   1:00    S
    1944-04-03   2:00s   1:00    S
"""
function order_rules(rules::Array{Rule})
    date_rules = Tuple{Date,Rule}[]

    # Note: Typically rules are orderd by "from" and "in". Unfortunately
    for rule in rules
        # Replicate the rule for each year that it is effective.
        for rule_year in get(rule.from, MINYEAR):get(rule.to, MAXYEAR)
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
            push!(date_rules, (date, rule))
        end
    end

    sort!(date_rules, by=el -> el[1])

    # Since we are not yet taking offsets or flags into account yet
    # there is a small chance that the results are not ordered correctly.
    last_date = typemin(Date)
    for (i, (date, rule)) in enumerate(date_rules)
        if i > 1 && date - last_date <= ABS_DIFF_OFFSET
            error("Dates are probably not in order")
        end
        last_date = date
    end

    return date_rules
end

"""
Resolves a named zone into TimeZone. Updates ordered with any new rules that
were required to be ordered.
"""
function resolve!(zone_name::AbstractString, zoneset::ZoneDict, ruleset::RuleDict,
    ordered::OrderedRuleDict; debug=false)

    transitions = Transition[]

    # Set some default values and starting DateTime increment and away we go...
    start_utc = MINDATETIME
    save = ZERO
    letter = ""

    ordered_rules = Dict{AbstractString,Array{Tuple{Date,Rule}}}()
    # zones = Set{FixedTimeZone}()

    # Zone needs to be in ascending order to ensure that start_utc is being applied
    # to the correct transition.
    for zone in sort(zoneset[zone_name])
        offset = zone.gmtoffset
        format = zone.format
        # save = zone.save
        rule_name = zone.rules
        until = get(zone.until, MAXDATETIME)

        if rule_name == ""
            save = zone.save
            abbr = format

            if debug
                rule_name = "\"\""  # Just for display purposes
                println("Zone Start $rule_name, $(zone.gmtoffset), $save, $(start_utc)u, $(until)$(zone.until_flag), $abbr")
            end

            tz = FixedTimeZone(abbr, toseconds(offset), toseconds(save))
            push!(transitions, Transition(start_utc, tz))
        else
            if !haskey(ordered, rule_name)
                ordered[rule_name] = order_rules(ruleset[rule_name])
            end

            # TODO: We could avoid this search if the rule_name haven't changed since the
            # last iteration.
            rules = ordered[rule_name]
            index = searchsortedlast(rules, start_utc, by=el -> isa(el, Tuple) ? el[1] : el)

            # If start occurs prior to the first rule it can be expected in standard-time.
            if index == 0
                save = ZERO

                # Find the first occurrence of of standard-time
                for (date, rule) in rules
                    if rule.save == save
                        letter = rule.letter
                        break
                    end
                end
            else
                date, rule = rules[index]
                save = rule.save
                letter = rule.letter
            end

            # Note: using @sprintf would make sense but unfortunately it doesn't accept a
            # format as a variable.
            abbr = replace(format,"%s",letter,1)

            debug && println("Zone Start $rule_name, $(zone.gmtoffset), $save, $(start_utc)u, $(until)$(zone.until_flag), $abbr")

            tz = FixedTimeZone(abbr, toseconds(offset), toseconds(save))
            push!(transitions, Transition(start_utc, tz))

            for (date, rule) in rules[max(index,1):end]
                # TODO: Problematic if rule date close to until and offset is a large positive.
                date > until && break

                # Add "at" since it could be larger than 23:59:59.
                dt = DateTime(date) + rule.at

                # Convert rule and until datetimes into UTC using the latest
                # offset and save values that occurred prior to this rule.
                dt_utc = asutc(dt, rule.at_flag, offset, save)
                until_utc = asutc(until, zone.until_flag, offset, save)

                dt_utc < until_utc || break

                # Need to be careful when we update save/letter.
                save = rule.save
                letter = rule.letter
                abbr = replace(format,"%s",letter,1)

                if debug
                    status = start_utc <= dt_utc ? "Rule" : "Skip"
                    println("$status $(year(date)), $(dt)$(rule.at_flag), $(dt_utc)u, $save, $abbr")
                end

                # TODO: Is start_utc inclusive or exclusive?
                start_utc <= dt_utc || continue

                tz = FixedTimeZone(abbr, toseconds(offset), toseconds(save))

                # TODO: We can maybe reduce memory usage by reusing the same
                # FixedTimeZone object.
                # Note: By default pushing onto a set will replace objects.
                # if !(tz in zones)
                #     push!(zones, tz)
                # else
                #     tz = first(intersect(zones, Set([tz])))
                # end

                push!(transitions, Transition(dt_utc, tz))
            end
        end

        start_utc = asutc(until, zone.until_flag, offset, save)

        debug && println("Zone End   $rule_name, $offset, $save, $(start_utc)u")
        start_utc >= MAXDATETIME && break
    end

    # Note: Transitions array is expected to be ordered and should be if both
    # zones and rules were ordered.
    if length(transitions) > 1
        return VariableTimeZone(zone_name, transitions)
    else
        # Although unlikely the timezone name in the transition and the zone_name
        # could be different. We'll ignore this issue at the moment.
        return transitions[1].zone
    end
end

function resolve(zoneset::ZoneDict, ruleset::RuleDict; debug=false)
    ordered = OrderedRuleDict()
    timezones = Dict{AbstractString,TimeZone}()

    for zone_name in keys(zoneset)
        tz = resolve!(zone_name, zoneset, ruleset, ordered, debug=debug)
        timezones[zone_name] = tz
    end

    return timezones
end

function resolve(zone_name::AbstractString, zoneset::ZoneDict, ruleset::RuleDict; debug=false)
    ordered = OrderedRuleDict()
    return resolve!(zone_name, zoneset, ruleset, ordered, debug=debug)
end

function tzparse(tzfile::AbstractString)
    zones = ZoneDict()
    rules = RuleDict()
    links = Dict{AbstractString,AbstractString}()

    # For the intial pass we'll collect the zone and rule lines.
    open(tzfile) do fp
        kind = name = ""
        for line in eachline(fp)
            # Lines that start with whitespace can be considered a "continuation line"
            # which means the last found kind/name should persist.
            persist = ismatch(r"^\s", line)

            line = strip(replace(chomp(line), r"#.*$", ""))
            length(line) > 0 || continue
            line = replace(line, r"\s+", " ")

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
                warn("Unhandled line found with type: $kind")
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

function load(tzdata_dir::AbstractString=TZDATA_DIR)
    timezones = Dict{AbstractString,TimeZone}()
    for region in REGIONS
        zones, rules = tzparse(joinpath(tzdata_dir, region))
        merge!(timezones, resolve(zones, rules))
    end
    return timezones
end

function compile(tzdata_dir::AbstractString=TZDATA_DIR, dest_dir::AbstractString=COMPILED_DIR)
    timezones = load(tzdata_dir)

    isdir(dest_dir) || error("Destination directory doesn't exist")

    for (name, timezone) in timezones
        parts = split(name, "/")
        tz_dir, tz_file = joinpath(dest_dir, parts[1:end-1]...), parts[end]

        isdir(tz_dir) || mkpath(tz_dir)

        open(joinpath(tz_dir, tz_file), "w") do fp
            serialize(fp, timezone)
        end
    end
end

end # module