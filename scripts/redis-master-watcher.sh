#!/bin/bash

# Redis master watcher script
# Monitors Redis Sentinel for master changes and updates HAProxy backend

#REDIS_PASSWORD=
#REDIS_SENTINEL_GROUP=
#REDIS_MASTER_BACKEND_SET=
#REDIS_MASTER_BACKEND_SRV=

#SOCKET="${HAPROXY_SOCKET:-/var/lib/haproxy/haproxy.sock}"
SOCKET_HOST="127.0.0.1"
SOCKET_PORT="9999"

# HAProxy can provide a healthy sentinel
SENTINEL_HOST="127.0.0.1"
SENTINEL_PORT="26379"

# HAProxy provided replica
DEFAULT_ADDR="127.0.0.1:16379"

CURRENT_ADDR="$DEFAULT_ADDR"

# Function to get master address from sentinel
get_master_addr() {
    local output
    output=$(redis-cli -h "$SENTINEL_HOST" -p "$SENTINEL_PORT" \
        -a "$REDIS_PASSWORD" \
        --raw sentinel get-master-addr-by-name "$REDIS_SENTINEL_GROUP" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$output" ]; then
        echo "$output" | tr '\n' ':' | sed 's/:$//'
    else
        echo ""
    fi
}

# Function to update HAProxy server address
update_haproxy_server() {
    IFS=: read -r host port <<< "$1"
    #echo "set server $REDIS_MASTER_BACKEND_SET/$REDIS_MASTER_BACKEND_SRV addr $host port $port"
    echo "set server $REDIS_MASTER_BACKEND_SET/$REDIS_MASTER_BACKEND_SRV addr $host port $port" \
        | nc "$SOCKET_HOST" "$SOCKET_PORT" 2>/dev/null
    #    | socat unix-connect:"$SOCKET" stdio 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Updated $REDIS_MASTER_BACKEND_SET/$REDIS_MASTER_BACKEND_SRV to $host:$port"
    else
        echo "Failed to update $REDIS_MASTER_BACKEND_SET/$REDIS_MASTER_BACKEND_SRV"
    fi
}

# Main loop
while true; do

    sleep 10  # Check every 10 seconds

    master_addr=$(get_master_addr)
    if [ -n "$master_addr" ]; then
        if [ "$master_addr" != "$CURRENT_ADDR" ]; then
            update_haproxy_server "$master_addr"
            CURRENT_ADDR="$master_addr"
        fi
    else
        # No master found, set to default
        if [ "$DEFAULT_ADDR" != "$CURRENT_ADDR" ]; then
            update_haproxy_server "$DEFAULT_ADDR"
            CURRENT_ADDR="$DEFAULT_ADDR"
            echo "No master found, set to default $DEFAULT_ADDR"
        fi
    fi

done