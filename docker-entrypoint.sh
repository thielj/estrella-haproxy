#!/bin/sh
set -e

# Default HAProxy config if none provided
if [ ! -f /usr/local/etc/haproxy/haproxy.cfg ]; then
    echo "No HAProxy config found, creating default minimal config..."
    mkdir -p /usr/local/etc/haproxy
    cat > /usr/local/etc/haproxy/haproxy.cfg << 'EOF'
global
    log stdout local0
    stats socket /var/run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend stats
    bind *:8404
    stats enable
    stats uri /
EOF
fi

# Function to handle shutdown signals
shutdown() {
    echo "Received shutdown signal, stopping all processes gracefully..."
    if [ -f /var/run/supervisord.pid ]; then
        kill -TERM $(cat /var/run/supervisord.pid) 2>/dev/null || true
    fi
    exit 0
}

# Trap signals for clean shutdown
trap shutdown SIGTERM SIGINT SIGUSR1

# If first argument is supervisord, run our minimal supervisord
if [ "$1" = 'supervisord' ]; then
    echo "Starting minimal supervisord with HAProxy and additional scripts..."
    exec /usr/local/bin/supervisord
fi

# Otherwise, exec the provided command
exec "$@"