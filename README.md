# estrella-haproxy

A rootless drop-in replacement for the official `haproxy:alpine` image with a minimal supervisord for running additional scripts.

## Differences from `haproxy:alpine`

- **Rootless**: Runs as user `99:99` (haproxy). `/var/lib/haproxy` is haproxy's workdir and writeable.
- **Auto-loaded configs**: Additional HAProxy config files in `/usr/local/etc/haproxy/services.d/` are automatically included.
- **Background scripts**: Executable scripts in `/usr/local/etc/haproxy/scripts.d/` run supervised in the background.

SIGUSR1 (or SIGINT) still trigger a graceful shutdown of haproxy.

Main config remains at `/usr/local/etc/haproxy/haproxy.cfg`. Logs are written to `/var/lib/haproxy/logs`.

The underlying image provides minimalist busybox variants of common utilities like `nc`, `wget`.
To help with scripting, additional packages have been added: `bash`, `curl`, `redis`.

## Usage

Mount config volume at `/usr/local/etc/haproxy`. Optionally, state at `/var/lib/haproxy` and logs at `/var/lib/haproxy/logs`.

Example run as user 99:99:

```bash
docker run -d \
  --user 99:99 \
  -v /host/config:/usr/local/etc/haproxy:ro \
  -v /host/state:/var/lib/haproxy \
  -v /host/logs:/var/lib/haproxy/logs \
  ghcr.io/thielj/estrella-haproxy:latest
```

See [official HAProxy Docker instructions](https://hub.docker.com/_/haproxy) for more details.
