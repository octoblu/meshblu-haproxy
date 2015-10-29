FROM haproxy:1.5
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
CMD ["haproxy", "-d", "-f", "/usr/local/etc/haproxy/haproxy.cfg"]
