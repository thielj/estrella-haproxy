# estrella-haproxy

Extensions to HAProxy with supervisord for running additional processes

## Overview

This project extends the official `haproxy:2.8-alpine` Docker image with supervisord to enable running additional processes alongside HAProxy. These processes can communicate with HAProxy through its admin socket for dynamic configuration and monitoring.

## Features

- **Multi-process Support**: Run additional scripts/processes alongside HAProxy using supervisord
- **HAProxy Admin Socket Integration**: Scripts can communicate with HAProxy through the admin socket (`/var/run/haproxy/admin.sock`)
- **Automatic Script Discovery**: All executable scripts in `/usr/local/bin/scripts/` are automatically started and managed
- **Clean Shutdown Handling**: Properly handles HAProxy's preferred `SIGUSR1` signal for graceful shutdown
- **Auto-restart**: Failed processes are automatically restarted by supervisord
- **Multi-arch Support**: Available for `linux/amd64` and `linux/arm64` architectures
- **Container Registry**: Images published to GitHub Container Registry (GHCR)

## Quick Start

### Using the Pre-built Image

```bash
# Pull from GitHub Container Registry
docker pull ghcr.io/thielj/estrella-haproxy:latest

# Run with default configuration
docker run -d -p 80:80 -p 8404:8404 ghcr.io/thielj/estrella-haproxy:latest
```

### Custom HAProxy Configuration

```bash
# Mount your HAProxy configuration
docker run -d \
  -p 80:80 -p 443:443 -p 8404:8404 \
  -v /path/to/your/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  ghcr.io/thielj/estrella-haproxy:latest
```

### Adding Custom Scripts

```bash
# Mount a directory with your scripts
docker run -d \
  -p 80:80 -p 8404:8404 \
  -v /path/to/your/scripts:/usr/local/bin/scripts:ro \
  -v /path/to/your/haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro \
  ghcr.io/thielj/estrella-haproxy:latest
```

## Included Example Scripts

### redis-master-watcher.sh

Monitors Redis instances and dynamically enables/disables them in HAProxy based on their master/slave status.

**Environment Variables:**
- `REDIS_HOSTS`: Space-separated list of Redis hosts (format: `host:port`)
- `CHECK_INTERVAL`: Check interval in seconds (default: 10)

**Example:**
```bash
docker run -d \
  -e REDIS_HOSTS="redis1:6379 redis2:6379 redis3:6379" \
  -e CHECK_INTERVAL=5 \
  ghcr.io/thielj/estrella-haproxy:latest
```

### health-monitor.sh

Monitors backend health status and logs any status changes.

**Environment Variables:**
- `HEALTH_CHECK_INTERVAL`: Check interval in seconds (default: 30)

## HAProxy Admin Socket

The admin socket is available at `/var/run/haproxy/admin.sock` and can be used by scripts to:

- Enable/disable servers: `echo "disable server backend/server1" | socat - UNIX-CONNECT:/var/run/haproxy/admin.sock`
- Get statistics: `echo "show stat" | socat - UNIX-CONNECT:/var/run/haproxy/admin.sock`
- Get info: `echo "show info" | socat - UNIX-CONNECT:/var/run/haproxy/admin.sock`

## Creating Custom Scripts

1. Create executable shell scripts in the `/usr/local/bin/scripts/` directory
2. Scripts will be automatically discovered and managed by supervisord
3. Use the HAProxy admin socket for dynamic configuration

**Example script structure:**
```bash
#!/bin/bash

HAPROXY_SOCKET="/var/run/haproxy/admin.sock"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] my-script: $1"
}

# Your script logic here
while true; do
    # Do something
    echo "show info" | socat - "UNIX-CONNECT:$HAPROXY_SOCKET"
    sleep 30
done
```

## Docker Compose Example

```yaml
version: '3.8'

services:
  haproxy:
    image: ghcr.io/thielj/estrella-haproxy:latest
    ports:
      - "80:80"
      - "443:443"
      - "8404:8404"
    volumes:
      - ./haproxy.cfg:/usr/local/etc/haproxy/haproxy.cfg:ro
      - ./scripts:/usr/local/bin/scripts:ro
    environment:
      - REDIS_HOSTS=redis1:6379 redis2:6379
      - CHECK_INTERVAL=10
      - HEALTH_CHECK_INTERVAL=30

  redis1:
    image: redis:alpine
    
  redis2:
    image: redis:alpine
```

## Building from Source

```bash
# Clone the repository
git clone https://github.com/thielj/estrella-haproxy.git
cd estrella-haproxy

# Build the image
docker build -t estrella-haproxy .

# Run the built image
docker run -d -p 80:80 -p 8404:8404 estrella-haproxy
```

## Configuration Files

### supervisord.conf
Main supervisord configuration file that manages all processes.

### haproxy-supervisord.conf
HAProxy-specific supervisord configuration that handles clean shutdown signals.

### docker-entrypoint.sh
Custom entrypoint script that:
- Generates default HAProxy config if none provided
- Automatically discovers and configures scripts
- Handles shutdown signals properly

## Monitoring and Logs

- **Supervisord logs**: `/var/log/supervisor/supervisord.log`
- **HAProxy logs**: `/var/log/supervisor/haproxy.log`
- **Script logs**: `/var/log/supervisor/{script-name}.log`

Access logs via docker:
```bash
docker logs <container-id>
docker exec <container-id> tail -f /var/log/supervisor/supervisord.log
```

## Multi-Architecture Support

Images are automatically built for multiple architectures when tags matching `v*.*` are created:

- `linux/amd64`
- `linux/arm64`

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
