module TZCompile

using Base.Dates

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
    length(s) == 1 && return HourMin(int(s),0)
    ss = split(s,':')
    return HourMin(int(ss[1]),int(ss[2]))
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
for d in collect(keys(DAYS))
    sym = symbol("last" * d)
    dayofweek = get(DAYS,d,1)
    @eval (function $sym(dt)
            return dayofweek(dt) == $dayofweek &&
            dayofweekofmonth(dt) == daysofweekinmonth(dt)
        end)
end

# Olsen timezone dates can be a single year (1900), yyyy-mm-dd (1900-Jan-01),
# or minute-precision (1900-Jan-01 2:00).
# They can also be given in Local Wall Time, UTC time (u), or Local Standard time (s)
function parsedate(periods,offset,save)
    s = join(periods,' ')
    s,letter = length(periods) > 3 ? isalpha(s[end]) ? (s[1:end-1],s[end]) : (s,' ') : (s,' ')
    if contains(s,"lastSun")
        dt = DateTime(replace(s,"lastSun","1",1),"yyyy uuu d H:MM")
        while !lastSun(dt)
            dt += Day(1)
        end
    elseif contains(s,"lastSat")
        dt = DateTime(replace(s,"lastSat","1",1),"yyyy uuu d H:MM")
        while !lastSat(dt)
            dt += Day(1)
        end
    elseif contains(s,"Sun>=1")
        dt = DateTime(replace(s,"Sun>=","",1),"yyyy uuu d H:MM")
        while dayofweek(dt) != 7
            dt += Day(1)
        end
    else
        l = length(periods)
        f = l == 1 ? "yyyy" : l == 2 ? "yyyy uuu" : 
            l == 3 ? "yyyy uuu dd" : l == 4 ? "yyyy uuu dd HH:MM" : error("couldn't parse date")
        periods = Dates.parse(s,Dates.DateFormat(f))
        if length(periods) > 3
            if periods[4] == Hour(24)
                periods[4] = Hour(0)
                periods[3] += Day(1)
            end
        end
        dt = DateTime(periods...)
    end
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
        month = MONTHS[spl[6]]
        # Now we need to get the right anonymous function
        # for determining the right day for transitioning
        if ismatch(r"last\w\w\w",spl[7])
            # We pre-built these functions above
            # They follow the format "lastSun","lastMon"
            on = eval(symbol(spl[7]))
        elseif ismatch(r"\w\w\w[<>]=\d\d?",spl[7])
            # For the first day of the week after or before a given day
            # i.e. Sun>=8 refers to the 1st Sunday after the 8th of the month
            # or in other words, the 2nd Sunday
            zday = int(match(r"\d\d?",spl[7]).match)
            dow = DAYS[match(r"\w\w\w",spl[7]).match]
            if ismatch(r"<=",spl[7])
                on = @eval (x->day(x) <= $zday && dayofweek(x) == $dow)
            else
                on = @eval (x->day(x) >= $zday && dayofweek(x) == $dow)
            end
        elseif ismatch(r"\d\d?",spl[7])
            # Matches just a plain old day of the month
            zday = int(spl[7])
            on = @eval (x->day(x) == $zday)
        else
            error("Can't parse day of month for DST change")
        end
        # Now we get the time of the transition
        c = spl[8][end]
        at = isalpha(c) ? HourMin(spl[8][1:end-1]) : HourMin(spl[8])
        # 0 for Local Wall time, 1 for UTC, 2 for Local Standard time
        at_flag = c == 'u' ? 1 : c == 's' ? 2 : 0
        save = HourMin(spl[9])
        letter = spl[10]
        from = spl[3] == "min" ? year(MINDATE) : int(spl[3])
        to = spl[4] == "only" ? from : spl[4] == "max" ? year(MAXDATE) : int(spl[4])
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
        spl = split(line,' ')
        # Sometimes there are "LMT" lines which we don't care about
        length(split(spl[1],':')) > 2 && continue #TODO: this may be too aggressive
        # Get our offset and abbreviation string for this period
        offset = HourMin(spl[1])
        abbr = spl[3] == "zzz" ? "" : spl[3]
        # Parse the date the line rule applies up to
        # If it's blank, then we're at the last line, so go to MAXDATE
        until = (length(spl) < 4 || spl[4] == "") ? MAXDATE : parsedate(spl[4:end],offset,save)

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
                for n = 1:length(ruleset.rules)
                    r = ruleset.rules[n]
                    # If the Rule is out of range, skip it
                    r.from > year(y) && continue
                    r.to   < year(y) && continue
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
                    push!(offs,millis(HourMin(spl[1])+r.save))
                    push!(abbrs,replace(abbr,"%s",r.letter == "-" ? "" : r.letter,1))
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
    rulelines = Dict{String,Array{String,1}}()
    zonelines = Dict{String,Array{String,1}}()
    open(tzfile) do x
        z = ""
        for line in eachline(x)
            line = replace(strip(replace(chomp(line),r"#.*$","")),r"\s+"," ")
            (line == "" || line[1] == '#' || 
             ismatch(r"^Zone\s(EST|MST|HST|EST5EDT|CST6CDT|MST7MDT|PST8PDT|WET|CET|MET|EET)",line) || 
             ismatch(r"^Link",line)) && continue
            if ismatch(r"^Rule",line)
                m = match(r"(?<=^Rule\s)\b.+?(?=\s)",line).match
                rulelines[m] = push!(get(rulelines,m,String[]),line)
            else
                z = !ismatch(r"^Zone",line) ? z : match(r"(?<=^Zone\s)\b.+?(?=\s)",line).match
                ismatch(r"^Zone",line) && continue
                zonelines[z] = push!(get(zonelines,z,String[]),line)
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
        append!(zones,tzparse(olsen_path*string(f))[1])
    end
    z_syms = [symbol(zone_symbol(x)) for x in zones]
    z_s = [a.name=>b for (a,b) in zip(zones,z_syms)]
    s_z = [a=>b.name for (a,b) in zip(z_syms,zones)]
    open(dest_path * "tzinfo.jl","w") do f
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