#!/bin/sh

# Simple socat replacement for HAProxy admin socket communication
# Usage: ./simple-socat.sh "command" /path/to/socket

if [ $# -ne 2 ]; then
    echo "Usage: $0 \"command\" /path/to/socket"
    exit 1
fi

COMMAND="$1"
SOCKET="$2"

if [ -S "$SOCKET" ]; then
    # Since BusyBox nc doesn't support Unix sockets, use exec to open the socket
    # This is a basic shell method to communicate with the socket
    exec 3<>"$SOCKET" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "$COMMAND" >&3
        cat <&3
        exec 3>&-
    else
        echo "Warning: Could not open socket $SOCKET"
        return 1
    fi
else
    echo "Socket $SOCKET not found"
    return 1
fi