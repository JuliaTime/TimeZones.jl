module TZCompile

using Base.Dates
import Compat: parse

# Convenience type for working with HH:MM
immutable HourMin
    hour::Int
    min::Int
end

const ZERO = HourMin(0,0)

function HourMin(s::String)
    # "-" represents 0:00 for some DST rules
    ismatch(r"\d",s) || return ZERO
    # handle single number as # of hours
    length(s) == 1 && return HourMin(parse(Int, s), 0)
    ss = split(s, ':')
    return HourMin(parse(Int, ss[1]), parse(Int, ss[2]))
end

millis(hm::HourMin) = hm.min*60000 + 3600000*hm.hour
(+)(x::HourMin,y::HourMin) = HourMin(x.hour+y.hour,x.min+y.min)
(-)(x::HourMin,y::HourMin) = HourMin(x.hour-y.hour,x.min-y.min)
(+)(x::DateTime,y::HourMin) = x + Hour(y.hour) + Minute(y.min)
(-)(x::DateTime,y::HourMin) = x - Hour(y.hour) - Minute(y.min)

# Zone type maps to an Olsen Timezone database entity
type Zone
    name::String        # of the form "America/Chicago", etc.
    gmtoffset::HourMin  # Default offset: most recent is used as default
    abbr::String        # Default abbreviation: Most recent "Standard" abbr is used
    dst::Array{Any,2}   # nx3 matrix [DST_Millisecond_Instant offset abbr]
end
# Rules govern how Daylight Savings transitions happen for a given timezone
type Rule
    from::Int       # First year rule applies
    to::Int         # Rule applies up until, but not including this year
    month::Int      # Month in which DST transition happens
    on::Function    # Anonymous boolean function to determine day
    at::HourMin     # Hour and minute at which the transition happens
    at_flag::Int    # 0, 1, 2 = Local wall time, UTC time, Local Standard time
    save::HourMin   # How much time is "saved" in daylight savings transition
    letter::String  # Timezone abbreviation letter change; i.e CST => CDT
end
# Rules are collected in RuleSets
type RuleSet
    name::String
    rules::Vector{Rule}
end
RuleSet(n::String) = RuleSet(n,Rule[])

# Max date that we create DST transition instants for
const MINDATE = DateTime(1917,1,1)
const MAXDATE = DateTime(2038,12,31)

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

# Olsen timezone dates can be a single year (1900), yyyy-mm-dd (1900-Jan-01),
# or minute-precision (1900-Jan-01 2:00).
# They can also be given in Local Wall Time, UTC time (u), or Local Standard time (s)
function parsedate(s,offset,save)
    periods = split(s, ' ')
    s,letter = length(periods) > 3 ? isalpha(s[end]) ? (s[1:end-1],s[end]) : (s,' ') : (s,' ')
    if contains(s,"lastSun")
        dt = DateTime(replace(s, "lastSun", "1", 1), "yyyy uuu d H:MM")
        dt = tonext(lastSun, dt; same=true)
    elseif contains(s,"lastSat")
        dt = DateTime(replace(s, "lastSat", "1", 1), "yyyy uuu d H:MM")
        dt = tonext(lastSat, dt; same=true)
    elseif contains(s,"Sun>=1")
        dt = DateTime(replace(s,"Sun>=", "", 1),"yyyy uuu d H:MM")
        dt = tonext(d -> dayofweek(d) == Sun, dt; same=true)
    else
        f = join(split("yyyy uuu dd HH:MM", ' ')[1:length(periods)], ' ')
        periods = Dates.parse(s, Dates.DateFormat(f))

        # Deal with zone "Pacific/Apia" which has a 24:00 datetime.
        if length(periods) > 3
            if periods[4] == Hour(24)
                periods[4] = Hour(0)
                periods[3] += Day(1)
            end
        end
        dt = DateTime(periods...)
    end

    # TODO: I feel like there are issues here.
    # If the time is UTC, we add back the offset and any saved amount
    # If it's local standard time, we just need to add any saved amount
    return letter == 's' ? (dt - save) : (dt - offset - save)
end

# Takes a string array of Rule lines and parses a RuleSet
function rulesetparse(rule,lines)
    ruleset = RuleSet(rule)
    # And away we go...
    for line in lines
        spl = split(line,' ')
        # Get the month. Easy.
        month = MONTHS[spl[4]]
        # Now we need to get the right anonymous function
        # for determining the right day for transitioning
        if ismatch(r"last\w\w\w",spl[5])
            # We pre-built these functions above
            # They follow the format: "lastSun", "lastMon".
            on = eval(symbol(spl[5]))
        elseif ismatch(r"\w\w\w[<>]=\d\d?",spl[5])
            # The first day of the week that occurs before or after a given day of month.
            # i.e. Sun>=8 refers to the Sunday after the 8th of the month
            # or in other words, the 2nd Sunday.
            dow = DAYS[match(r"\w\w\w",spl[5]).match]
            dom = parse(Int, match(r"\d\d?",spl[5]).match)
            if ismatch(r"<=",spl[5])
                on = @eval (dt -> day(dt) <= $dom && dayofweek(dt) == $dow)
            else
                on = @eval (dt -> day(dt) >= $dom && dayofweek(dt) == $dow)
            end
        elseif ismatch(r"\d\d?",spl[5])
            # Matches just a plain old day of the month
            zday = parse(Int, spl[5])
            on = @eval (x->day(x) == $zday)
        else
            error("Can't parse day of month for DST change")
        end
        # Now we get the time of the transition
        c = spl[6][end]
        at = isalpha(c) ? HourMin(spl[6][1:end-1]) : HourMin(spl[6])
        # 0 for Local Wall time, 1 for UTC, 2 for Local Standard time
        at_flag = c == 'u' ? 1 : c == 's' ? 2 : 0
        save = HourMin(spl[7])
        letter = spl[8] == "-" ? "" : spl[8]
        from = spl[1] == "min" ? year(MINDATE) : parse(Int, spl[1])
        to = spl[2] == "only" ? from : spl[2] == "max" ? year(MAXDATE) : parse(Int, spl[2])
        # Now we've finally parsed everything we need
        push!(ruleset.rules,Rule(from,to,month,on,at,at_flag,save,letter))
    end
    return ruleset
end

# Takes string array, and Dict{RuleSet.name=>RuleSet} for Zone parsing
function zoneparse(zone,lines,rulesets)
    # These 3 arrays will hold our DST_matrices
    dst = Int64[]    # DST transition instants in milliseconds
    offs = Int64[]   # Offset from UTC for the time leading up to dst_instant
    abbrs = String[] # Abbreviation for period up to dst_instant
    # Set some default values and starting DateTime increment and away we go...
    y = MINDATE
    default_letter = "S"
    save = ZERO
    offset = ZERO
    abbr = ""
    for line in lines
        spl = split(line, ' '; limit=4)

        # Sometimes there are "LMT" lines which we don't care about
        length(split(spl[1],':')) > 2 && continue #TODO: this may be too aggressive

        # Get our offset and abbreviation string for this period
        offset = HourMin(spl[1])
        abbr = spl[3] == "zzz" ? "" : spl[3]
        # Parse the date the line rule applies up to
        # If it's blank, then we're at the last line, so go to MAXDATE
        until = (length(spl) < 4 || spl[4] == "") ? MAXDATE : parsedate(spl[4],offset,save)

        if spl[2] == "-" || ismatch(r"\d",spl[2])
            save = HourMin(spl[2])
            y = y - offset - save
            push!(dst,y.instant.periods.value)
            push!(offs,millis(offset+save))
            push!(abbrs,abbr)
            y = until
        else
            # Get the Rule that applies for this period
            ruleset = rulesets[spl[2]]
            # Now we iterate thru the years until we reach UNTIL
            while y < until
                # We need to check all Rules to see if they apply
                # for the given year
                for r in ruleset.rules
                    # If the Rule is out of range, skip it
                    r.from <= year(y) <= r.to || continue

                    # Now we need to deterimine the transition day
                    # We start at the Rule month, hour, minute
                    # And apply our boolean "on" function until we
                    # arrive at the right transition instant
                    h = r.at.hour
                    d = 1
                    if h == 24
                        h = 0
                        d += 1
                    end
                    dt = DateTime(year(y),r.month,d,h,r.at.min)
                    # TODO: Alternatively this code could be rewritten as:
                    # try
                    #     dt = tonext(r.on, dt; limit=1000)
                    # catch e
                    #     if isa(e, ArgumentError)
                    #         @show zone, DateTime(year(y),r.month,1,r.at.hour,r.at.min)
                    #         error("throwy")
                    #     end
                    # end
                    ff = 1
                    while true
                        (r.on(dt) || ff == 1000) && break
                        ff += 1; dt += Day(1)
                    end
                    if ff == 1000
                        @show zone, DateTime(year(y),r.month,1,r.at.hour,r.at.min)
                        error("throwy")
                    end
                    # If our time was given in UTC, add back offset and save
                    # if local standard time, add back any saved amount
                    dt = r.at_flag == 1 ? dt :
                         r.at_flag == 0 ? dt - offset - save : dt - r.save

                    push!(dst,dt.instant.periods.value)
                    push!(offs,millis(offset + r.save))

                    # Using @sprintf would be best but it doesn't accept a format as a
                    # variable.
                    push!(abbrs,replace(abbr,"%s",r.letter,1))

                    save = r.save != ZERO ? r.save : ZERO
                    r.save == ZERO && (default_letter = r.letter)
                end
                y += Year(1)
            end
        end
        until == MAXDATE && break
    end
    abbr = replace(abbr,r"%\w",default_letter,1)
    dst_matrix = [dst offs abbrs]
    sortinds = sortperm(dst_matrix[:,1])
    return Zone(zone,offset,abbr,dst_matrix[sortinds,:])
end

function tzparse(tzfile::String)
    rulelines = Dict{String,Array{String}}()
    zonelines = Dict{String,Array{String}}()

    # For the intial pass we'll collect the zone and rule lines.
    open(tzfile) do fp
        kind, name = nothing, nothing
        for line in eachline(fp)
            line = strip(replace(chomp(line), r"#.*$", ""))
            length(line) > 0 || continue
            line = replace(line, r"\s+", " ")

            # Remove type and name from the line if they exist otherwise persist
            # the last occurence.
            parts = split(line, ' '; limit=3)
            if parts[1] in ("Rule", "Zone")
                kind, name, line = parts
            end

            if kind == "Rule"
                rulelines[name] = push!(get(rulelines, name, String[]), line)
            elseif kind == "Zone"
                zonelines[name] = push!(get(zonelines, name, String[]), line)
            end
        end
    end

    # Rule pass
    rulesets = Dict{String,RuleSet}() # RuleSet.name=>RuleSet for easy lookup
    for (rule,lines) in rulelines
        rulesets[rule] = rulesetparse(rule,lines)
    end

    # Zone pass
    zones = Dict{String,Zone}()
    for (zone,lines) in zonelines
        zones[zone] = zoneparse(zone,lines,rulesets)
    end
    return zones, rulesets
end

function zone_symbol(z::Zone)
    n = z.name
    n = ismatch(r"(?<=/).+?$",n) ? match(r"(?<=/).+?$",n).match : n
    n = ismatch(r"(?<=/).+?$",n) ? match(r"(?<=/).+?$",n).match : n
    return replace(n,"-","_")
end

function generate_tzinfo(olsen_path::String,dest_path::String)
    files = [:africa,:antarctica,:asia,:australasia,
             :europe,:northamerica,:southamerica]
    zones = Zone[]
    for f in files
        append!(zones,tzparse(joinpath(olsen_path,string(f)))[1])
    end
    z_syms = [symbol(zone_symbol(x)) for x in zones]
    z_s = [a.name=>b for (a,b) in zip(zones,z_syms)]
    s_z = [a=>b.name for (a,b) in zip(z_syms,zones)]
    open(joinpath(dest_path, "tzinfo.jl"), "w") do f
        write(f,"### AUTO-GENERATED FILE ###\n\n")
        # Zone Definitions
        write(f,"#Define zone immutable for each timezone in Olson tz database\n")
        write(f,"for tz in $(repr(tuple(z_syms...)))\n")
        write(f,"\t@eval immutable \$tz <: PoliticalTimezone end\n")
        write(f,"end\n\n")
        # String=>Zone, Zone=>String mapping
        write(f,"const TIMEZONES = $(repr(s_z))\n")
        write(f,"const TIMEZONES1 = $(repr(z_s))\n")
        # Abbreviations

    end
end

function generate_tzdata(olsen_path::String,dest_path::String)
    files = [:africa,:antarctica,:asia,:australasia,
             :europe,:northamerica,:southamerica]
    for f in files
        for (name,zone) in tzparse(joinpath(olsen_path,string(f)))[1]
            open(joinpath(dest_path,zone_symbol(zone)),"w") do x
                serialize(x,zone.dst)
            end
        end
    end
end

#TODO
 #spot check times/offsets/abbrs
 #handle timezone link names
 #generate common abbreviation typealiases
 #fix abbreviation for kiev? antarctica
 #use etcetera file for generic offsets?
end # module