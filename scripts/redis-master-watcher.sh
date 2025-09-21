#!/bin/sh

# Example redis-master-watcher.sh script
# This script monitors Redis masters and communicates with HAProxy through the admin socket

HAPROXY_SOCKET="/var/run/haproxy/admin.sock"
CHECK_INTERVAL=${CHECK_INTERVAL:-10}
REDIS_HOSTS=${REDIS_HOSTS:-"redis1:6379 redis2:6379 redis3:6379"}
SOCAT_TOOL="/usr/local/bin/simple-socat.sh"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] redis-master-watcher: $1"
}

check_redis_master() {
    local host=$1
    local port=$2
    
    # Check if Redis is a master (simplified check using nc if available)
    if command -v nc >/dev/null 2>&1; then
        if timeout 3 sh -c "echo 'INFO replication' | nc $host $port" 2>/dev/null | grep -q "role:master"; then
            return 0
        else
            return 1
        fi
    else
        log "nc not available, skipping Redis check for $host:$port"
        return 1
    fi
}

update_haproxy_backend() {
    local action=$1  # enable or disable
    local server=$2
    
    if [ -S "$HAPROXY_SOCKET" ]; then
        if [ -x "$SOCAT_TOOL" ]; then
            "$SOCAT_TOOL" "$action server redis-backend/$server" "$HAPROXY_SOCKET"
            log "$action server $server in HAProxy backend"
        else
            log "Socket communication tool not available"
        fi
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