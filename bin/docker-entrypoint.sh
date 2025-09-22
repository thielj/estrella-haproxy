#!/bin/sh
set -e

# If first argument is haproxy, run our minimal supervisord
if [ "$1" = 'haproxy' ]; then
    shift
    exec /usr/local/bin/supervisord "$@"
fi

# Otherwise, exec the provided command
exec "$@"
