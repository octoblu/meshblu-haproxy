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
  cookie MESHBLUSRV insert indirect nocache

backend meshblu-http
  balance leastconn
  option redispatch
  option forwardfor
  option httpchk GET /healthcheck
  server meshblu-http meshblu-messages.octoblu.com:80 cookie meshblu-websocket-$SERVER
  http-request set-header Host meshblu-messages.octoblu.com

backend meshblu-original-flavor
  balance leastconn
  option redispatch
  option forwardfor
  option httpchk GET /healthcheck
EOF

for SERVER in $SERVERS; do
  echo "server meshblu-original-flavor-$SERVER $SERVER:61723 cookie meshblu-websocket-$SERVER check-send-proxy send-proxy check inter 10s"
done

cat <<EOF
  http-request set-header Host meshblu.octoblu.com

backend meshblu-websocket
  balance source
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
  echo "server meshblu-websocket-$SERVER $SERVER:61723 cookie meshblu-websocket-$SERVER check-send-proxy send-proxy check inter 10s"
done

cat <<EOF
  http-request set-header Host meshblu.octoblu.com

backend meshblu-socket-io
  balance source
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
  echo "server meshblu-socket-io-$SERVER $SERVER:61723 cookie meshblu-socket-io-$SERVER check-send-proxy send-proxy check inter 10s"
done

cat <<EOF
  http-request set-header Host meshblu.octoblu.com

backend meshblu-mqtt
  mode tcp
  balance leastconn
EOF

for SERVER in $SERVERS; do
  echo "server meshblu-mqtt-$SERVER $SERVER:52377"
done

cat <<EOF

frontend http-in
  bind :80 accept-proxy

  acl use-meshblu-http path_reg ^/devices/.+/subscriptions$
  acl use-meshblu-http path_beg /messages
  acl use-meshblu-socket-io path_beg /socket.io
  acl use-meshblu-websocket hdr(Upgrade) -i WebSocket

  use_backend meshblu-websocket if use-meshblu-websocket
  use_backend meshblu-socket-io if use-meshblu-socket-io
  use_backend meshblu-http if use-meshblu-http

  default_backend meshblu-original-flavor

frontend mqtt-in
  mode tcp
  bind :1883 accept-proxy

  default_backend meshblu-mqtt
EOF
