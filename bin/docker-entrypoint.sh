#!/bin/sh
set -e

PID_FILE="${_VAR_DIR}/supervisord.pid"

# Function to handle shutdown signals
shutdown() {
    echo "Received shutdown signal, stopping all processes gracefully..."
    if [ -f PID_FILE ]; then
        kill -TERM "$(cat "${PID_FILE}")" 2>/dev/null || true
    fi
    exit 0
}

# Trap signals for clean shutdown
trap 'shutdown' TERM INT USR1

# If first argument is supervisord, run our minimal supervisord
if [ "$1" = 'supervisord' ]; then
    echo "Starting minimal supervisord with HAProxy and additional scripts..."
    shift
    exec /usr/local/bin/supervisord "$@"
fi

# Otherwise, exec the provided command
exec "$@"