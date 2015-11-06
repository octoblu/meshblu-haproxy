FROM haproxy:1.6
ADD run.sh .
ADD haproxy.cfg.sh .
CMD ["./run.sh"]
