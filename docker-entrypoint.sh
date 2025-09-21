#!/bin/bash
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

# Function to generate supervisord config for scripts in /usr/local/bin/scripts/
generate_script_configs() {
    local script_dir="/usr/local/bin/scripts"
    local config_dir="/etc/supervisor/conf.d"
    
    if [ -d "$script_dir" ]; then
        for script in "$script_dir"/*.sh; do
            if [ -f "$script" ] && [ -x "$script" ]; then
                local script_name=$(basename "$script" .sh)
                local config_file="$config_dir/${script_name}-script.conf"
                
                echo "Generating supervisord config for script: $script_name"
                cat > "$config_file" << EOF
[program:${script_name}]
command=${script}
directory=/
autostart=true
autorestart=true
startretries=3
user=root
stdout_logfile=/var/log/supervisor/${script_name}.log
stderr_logfile=/var/log/supervisor/${script_name}_error.log
stdout_logfile_maxbytes=50MB
stderr_logfile_maxbytes=50MB
stdout_logfile_backups=10
stderr_logfile_backups=10
stopsignal=TERM
stopwaitsecs=10
killasgroup=true
stopasgroup=true
EOF
            fi
        done
    fi
}

# Function to handle shutdown signals
shutdown() {
    echo "Received shutdown signal, stopping supervisord gracefully..."
    if [ -f /var/run/supervisord.pid ]; then
        supervisorctl stop all
        kill -TERM $(cat /var/run/supervisord.pid)
    fi
    exit 0
}

# Trap signals for clean shutdown
trap shutdown SIGTERM SIGINT SIGUSR1

# Generate configurations for scripts
generate_script_configs

# If first argument is supervisord, run supervisord
if [ "$1" = 'supervisord' ]; then
    echo "Starting supervisord with HAProxy and additional scripts..."
    exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
fi

# Otherwise, exec the provided command
exec "$@"