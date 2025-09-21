#!/bin/bash

# Example redis-master-watcher.sh script
# This script monitors Redis masters and communicates with HAProxy through the admin socket

HAPROXY_SOCKET="/var/run/haproxy/admin.sock"
CHECK_INTERVAL=${CHECK_INTERVAL:-10}
REDIS_HOSTS=${REDIS_HOSTS:-"redis1:6379 redis2:6379 redis3:6379"}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] redis-master-watcher: $1"
}

check_redis_master() {
    local host=$1
    local port=$2
    
    # Check if Redis is a master (simplified check)
    if timeout 3 bash -c "echo 'INFO replication' | nc $host $port" 2>/dev/null | grep -q "role:master"; then
        return 0
    else
        return 1
    fi
}

update_haproxy_backend() {
    local action=$1  # enable or disable
    local server=$2
    
    if [ -S "$HAPROXY_SOCKET" ]; then
        echo "$action server redis-backend/$server" | socat - "UNIX-CONNECT:$HAPROXY_SOCKET"
        log "$action server $server in HAProxy backend"
    else
        log "HAProxy admin socket not available at $HAPROXY_SOCKET"
    fi
}

log "Starting Redis master watcher..."
log "Monitoring Redis hosts: $REDIS_HOSTS"
log "Check interval: ${CHECK_INTERVAL}s"

while true; do
    for host_port in $REDIS_HOSTS; do
        host=$(echo $host_port | cut -d: -f1)
        port=$(echo $host_port | cut -d: -f2)
        server_name="$host"
        
        if check_redis_master "$host" "$port"; then
            log "Redis $host:$port is master - enabling in HAProxy"
            update_haproxy_backend "enable" "$server_name"
        else
            log "Redis $host:$port is not master - disabling in HAProxy"
            update_haproxy_backend "disable" "$server_name"
        fi
    done
    
    sleep $CHECK_INTERVAL
done