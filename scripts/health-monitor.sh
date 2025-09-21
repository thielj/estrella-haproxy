#!/bin/bash

# Health monitor script for HAProxy latency-based weight adjustment
# Adjusts weights for servers in specified backends based on response time (rtime)
# Favors servers with lower latency

#SOCKET="${HAPROXY_SOCKET:-/var/lib/haproxy/haproxy.sock}"
SOCKET_HOST="127.0.0.1"
SOCKET_PORT="9999"

# Function to get HAProxy stats
get_stats() {
    #echo "show stat" | socat unix-connect:"$SOCKET" stdio 2>/dev/null
    echo "show stat" | nc -q1 "$SOCKET_HOST" "$SOCKET_PORT" 2>/dev/null
}

# Function to set server weight
set_weight() {
    local backend="$1"
    local server="$2"
    local weight="$3"
    #echo "set weight $backend/$server $weight" | socat unix-connect:"$SOCKET" stdio 2>/dev/null
    echo "set weight $backend/$server $weight" | nc -q1 "$SOCKET_HOST" "$SOCKET_PORT" 2>/dev/null
}

# Function to adjust weights for a backend
adjust_weights() {
    local backend="$1"
    local srv_pattern="$2"

    # Get stats and filter for the backend and servers matching pattern, status UP
    local stats
    stats=$(get_stats | awk -F',' '$1 == "'$backend'" && $2 ~ /^'$srv_pattern'[0-9]+$/ && $18 == "UP" {print $2","$60}')

    # Parse servers
    local servers=()
    while IFS=',' read -r svname rtime; do
        servers+=("$svname:$rtime")
    done <<< "$stats"

    # Sort by rtime (latency), ascending
    mapfile -t sorted < <(printf '%s\n' "${servers[@]}" | sort -t: -k2 -n)

    local num_servers=${#sorted[@]}
    if [ "$num_servers" -eq 0 ]; then
        echo "No UP servers for $backend matching $srv_pattern"
        return
    fi

    # Assign weights: strongly favor lower latency
    local base_weight=256
    local div=16 # 256, 16, 1, 0, 0, ...
    for i in "${!sorted[@]}"; do
        local server="${sorted[$i]%%:*}"
        local weight=$base_weight
        base_weight=$(( (base_weight + div / 2) / div )) # half-up rounding
        set_weight "$backend" "$server" "$weight"
        echo "Set $backend/$server weight to $weight"
    done
}

# Main loop
while true; do
    # Process each LATENCY_PROXY_SET
    i=0
    while true; do
        backend_var="LATENCY_PROXY_SET$i"
        srv_var="LATENCY_PROXY_SRV$i"
        backend="${!backend_var}"
        srv_pattern="${!srv_var}"
        if [ -z "$backend" ] || [ -z "$srv_pattern" ]; then
            break
        fi
        adjust_weights "$backend" "$srv_pattern"
        i=$((i + 1))
    done

    sleep 60  # Adjust every minute
done