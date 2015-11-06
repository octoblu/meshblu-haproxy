FROM haproxy:1.6

EXPOSE 1883

ADD run.sh .
ADD haproxy.cfg.sh .
CMD ["./run.sh"]
