FROM haproxy:2.8-alpine

# Switch to root for setup
USER root

# Create necessary directories without downloading packages
RUN mkdir -p /var/log/supervisor \
    && mkdir -p /etc/supervisor/conf.d \
    && mkdir -p /usr/local/bin/scripts \
    && mkdir -p /var/run/haproxy

# Install minimal supervisor manually (Python-based)
# Create a simple supervisord replacement using shell scripts
COPY minimal-supervisord.sh /usr/local/bin/supervisord
COPY simple-socat.sh /usr/local/bin/simple-socat.sh
RUN chmod +x /usr/local/bin/supervisord /usr/local/bin/simple-socat.sh

# Copy supervisord configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY haproxy-supervisord.conf /etc/supervisor/conf.d/haproxy.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy example scripts
COPY scripts/ /usr/local/bin/scripts/
RUN chmod +x /usr/local/bin/scripts/*.sh

# Expose HAProxy ports
EXPOSE 80 443 8404

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]