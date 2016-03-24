#!/bin/bash

cat <<EOF
global
  stats socket /tmp/haproxy.sock
  maxconn 80000

defaults
  log    global
  mode   http
  timeout client 60s            # Client and server timeout must match the longest
  timeout server 300s           # time we may wait for a response from the server.
  timeout queue  120s           # Don't queue requests too long if saturated.
  timeout connect 10s           # There's no reason to change this one.
  timeout http-request 300s     # A complete request may never take that long.
  timeout tunnel 2h
  retries         3
  option redispatch
  option httplog
  option dontlognull
  option http-server-close      # enable HTTP connection closing on the server side
  option abortonclose           # enable early dropping of aborted requests from pending queue
  option httpchk                # enable HTTP protocol to check on servers health
  stats auth opsworks:0ct0b1u2014
  stats uri /haproxy?stats

backend meshblu-http
  balance roundrobin
  option redispatch
  option forwardfor
  option httpchk GET /healthcheck
  server meshblu-http meshblu-messages.octoblu.com:80 cookie meshblu-http
  http-request set-header Host meshblu-messages.octoblu.com
  http-request add-header X-Forwarded-Proto https if { ssl_fc }
  http-request set-header X-Forwarded-Port %[dst_port]

backend meshblu-websocket
  balance roundrobin
  timeout queue 5000
  timeout server 86400000
  timeout connect 86400000
  timeout check 1s
  option forwardfor
  no option httpclose
  option http-server-close
  option forceclose
  option httpchk GET /healthcheck
EOF

for SERVER in $SERVERS; do
  echo "  server meshblu-$SERVER $SERVER:50671 $PROXY_ARGS check inter 10s"
done

cat <<EOF
  http-request set-header Host meshblu.octoblu.com

backend meshblu-socket-io
  balance roundrobin
  timeout queue 5000
  timeout server 86400000
  timeout connect 86400000
  timeout check 1s
  option forwardfor
  no option httpclose
  option http-server-close
  option forceclose
  option httpchk GET /healthcheck

  stick-table type string len 40 size 20M expire 2m
  stick store-response set-cookie(io)
  stick on cookie(io)
  stick on url_param(sid)
EOF

for SERVER in $SERVERS; do
  echo "  server meshblu-$SERVER $SERVER:61933 check inter 10s"
done

cat <<EOF
  http-request set-header Host meshblu.octoblu.com

backend meshblu-mqtt
  mode tcp
  balance roundrobin
EOF
  echo "  server meshblu-mqtt $MQTT_URL"
cat <<EOF

frontend http-in
  bind :80
  acl use-meshblu-socket-io path_beg /socket.io
  acl use-meshblu-websocket hdr(Upgrade) -i WebSocket

  use_backend meshblu-socket-io if use-meshblu-socket-io
  use_backend meshblu-websocket if use-meshblu-websocket

  default_backend meshblu-http

frontend mqtt-in
  mode tcp
  bind :1883
  default_backend meshblu-mqtt
EOF
