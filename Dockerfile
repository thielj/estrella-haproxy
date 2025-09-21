FROM haproxy:2.8-alpine

# Switch to root for package installation
USER root

# Install supervisord and other required packages
RUN apk update && apk add --no-cache \
    py3-supervisor \
    bash \
    curl \
    socat \
    && mkdir -p /var/log/supervisor \
    && mkdir -p /etc/supervisor/conf.d \
    && mkdir -p /usr/local/bin/scripts

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY haproxy-supervisord.conf /etc/supervisor/conf.d/haproxy.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy example scripts
COPY scripts/ /usr/local/bin/scripts/
RUN chmod +x /usr/local/bin/scripts/*.sh

# Create the socket directory for HAProxy admin socket
RUN mkdir -p /var/run/haproxy

# Expose HAProxy ports
EXPOSE 80 443 8404

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]