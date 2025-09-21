#!/bin/sh

# Example health-monitor.sh script
# This script monitors backend health and logs status through HAProxy admin socket

HAPROXY_SOCKET="/var/run/haproxy/admin.sock"
CHECK_INTERVAL=${HEALTH_CHECK_INTERVAL:-30}
SOCAT_TOOL="/usr/local/bin/simple-socat.sh"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] health-monitor: $1"
}

get_haproxy_stats() {
    if [ -S "$HAPROXY_SOCKET" ] && [ -x "$SOCAT_TOOL" ]; then
        "$SOCAT_TOOL" "show stat" "$HAPROXY_SOCKET" 2>/dev/null
    fi
}

monitor_backends() {
    local stats=$(get_haproxy_stats)
    
    if [ -n "$stats" ]; then
        # Parse backend status (simplified)
        echo "$stats" | grep -v "^#" | while IFS=',' read -r pxname svname qcur qmax scur smax slim stot bin bout dreq dresp ereq econ eresp wretr wredis status weight act bck chkfail chkdown lastchg downtime qlimit pid iid sid throttle lbtot tracked type rate rate_lim rate_max check_status check_code check_duration hrsp_1xx hrsp_2xx hrsp_3xx hrsp_4xx hrsp_5xx hrsp_other hanafail req_rate req_rate_max req_tot cli_abrt srv_abrt comp_in comp_out comp_byp comp_rsp lastsess last_chk last_agt qtime ctime rtime ttime agent_status agent_code agent_duration check_desc agent_desc check_rise check_fall check_health agent_rise agent_fall agent_health addr cookie mode algo conn_rate conn_rate_max conn_tot intercepted dcon dses wrew connect reuse cache_lookups cache_hits srv_icur src_ilim; do
            if [ "$svname" != "BACKEND" ] && [ "$svname" != "FRONTEND" ] && [ -n "$status" ]; then
                case "$status" in
                    "UP"|"OPEN")
                        ;;
                    "DOWN"|"MAINT")
                        log "Backend $pxname/$svname is $status"
                        ;;
                    *)
                        log "Backend $pxname/$svname status: $status"
                        ;;
                esac
            fi
        done
    else
        log "Could not retrieve HAProxy stats"
    fi
}

log "Starting health monitor..."
log "Check interval: ${CHECK_INTERVAL}s"

while true; do
    monitor_backends
    sleep $CHECK_INTERVAL
done