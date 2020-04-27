# Utilities for examining the behaviour of `TZ` with the `date` command. Was useful in
# validating the behaviour of the direct time zone representation support in TimeZones.jl

function epoch {
    date --date="${1:?}" +%s
}

function view_dates {
    xargs -I{} bash -c 'echo $(date -u --date @{} +%FT%X%z) $(date --date @{} +"-> %FT%X%z (%Z)")'
}

function transitions {
    local year=${1:?}
    local start=$(date -u --date="$year/1/1 00:00:00" +%s)
    local end=$(date -u --date="$(($year + 2))/1/1 00:00:00" +%s)

    find_transitions $start 2628000 $end
}

function find_transitions {
    local start=$1
    local step=$2
    local end=$3

    # Make seq always include end
    end=$(($end + ($start % $step)))

    function hash_tz {
        date --date @$1 +"%z%Z"
    }

    local prev_timestamp=0
    local prev_tz=""

    # Note: If transitions occurs very close together we may miss it
    for timestamp in $(seq $start $step $end); do
        local tz=$(hash_tz $timestamp)

        if [[ -n $prev_tz && $prev_tz != $tz ]]; then
            if [[ $step -eq 1 ]]; then
                echo -e "$prev_timestamp\n$timestamp" | view_dates
                echo
            else
                find_transitions $prev_timestamp $(($step/2)) $timestamp
            fi
        fi

        prev_timestamp=$timestamp
        prev_tz=$tz
    done
}

# Compare "America/Winnipeg" to direct specification equivalent
TZ="America/Winnipeg" transitions 2020
TZ="CST+6CDT+5,M3.2.0,M11.1.0" transitions 2020

# Low-level tooling
seq $(epoch "2019/12/30 UTC") 3600 $(epoch "2020/01/03 UTC") | TZ="FOO-0BAR-0,1,364" view_dates
