FROM haproxy:1.6

EXPOSE 1883
EXPOSE 59890

ADD run.sh .
ADD haproxy.cfg.sh .
CMD ["./run.sh"]
