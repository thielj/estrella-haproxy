FROM haproxy:2.8-alpine

ENV _VAR_DIR="/var/lib/haproxy" \
    _ETC_DIR="/usr/local/etc/haproxy"
ENV _LOG_DIR="${_VAR_DIR}/logs" \
    HAPROXY_SOCKET="${_VAR_DIR}/haproxy.sock" \
    HAPROXY_MASTR_SOCKET="${_VAR_DIR}/master.sock"

VOLUME "${_VAR_DIR}" "${_ETC_DIR}"
    
USER root
COPY bin/* /usr/local/bin/
RUN set -eux; \
	\
    chmod +x /usr/local/bin/*; \
    mkdir "${_ETC_DIR}/services.d" "${_ETC_DIR}/scripts.d"; \
    apk add --no-cache \
        bash \
        curl \
        redis \
	;

#COPY scripts/* "${_ETC_DIR}/scripts.d/"
#RUN chmod +x "${_ETC_DIR}/scripts.d/"*

USER haproxy
WORKDIR ${_VAR_DIR}

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["haproxy", "-f", "/usr/local/etc/haproxy/haproxy.cfg", "-f", "/usr/local/etc/haproxy/services.d"]