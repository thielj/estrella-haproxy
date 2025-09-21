FROM haproxy:2.8-alpine

ENV _VAR_DIR="/var/lib/haproxy" \
    _ETC_DIR="/usr/local/etc/haproxy"
ENV _LOG_DIR="${_VAR_DIR}/log" \
    HAPROXY_SOCKET="${_VAR_DIR}/haproxy.sock"

USER root
COPY bin/* /usr/local/bin/
RUN set -eux; \
	\
    chmod +x /usr/local/bin/*; \
    mkdir "${_ETC_DIR}/services.d" "${_ETC_DIR}/scripts.d"; \
    apk add --no-cache \
        bash \
        curl \
		socat \
        redis \
	;

USER haproxy
WORKDIR ${_VAR_DIR}
RUN mkdir ${_LOG_DIR} && \
    touch ${_LOG_DIR}/supervisord.log && \
    touch ${_LOG_DIR}/supervisord_error.log

## Expose HAProxy ports
#EXPOSE 8404

# Use our custom entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["supervisord", "-f", "/usr/local/etc/haproxy/haproxy.cfg", "-f", "/usr/local/etc/haproxy/services.d"]