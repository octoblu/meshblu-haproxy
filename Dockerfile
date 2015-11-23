FROM haproxy:1.6

RUN apt-get update && \
    apt-get install -y socat && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 1883
EXPOSE 59890

ADD run.sh .
ADD haproxy.cfg.sh .
CMD ["./run.sh"]
