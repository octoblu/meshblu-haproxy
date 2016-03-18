#!/bin/bash
cat <<EOF
global
  debug

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
  stats uri /haproxy?stats

backend meshblu-http
  option redispatch
  option forwardfor
  server meshblu-http meshblu-server-http.octoblu.dev:80 cookie meshblu-http
  http-request set-header Host meshblu-server-http.octoblu.dev
  http-request add-header X-Forwarded-Proto https if { ssl_fc }
  http-request set-header X-Forwarded-Port %[dst_port]

backend meshblu-original-flavor
  balance roundrobin
  option redispatch
  option forwardfor
  server meshblu-old meshblu-old.octoblu.dev:80
  http-request set-header Host meshblu-old.octoblu.dev

backend meshblu-long-lasting
  balance roundrobin
  timeout queue 5000
  timeout server 86400000
  timeout connect 86400000
  timeout check 1s
  option redispatch
  option forwardfor
  server meshblu-long-lasting meshblu-old.octoblu.dev:80
  http-request set-header Host meshblu-old.octoblu.dev
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
  server meshblu-websocket meshblu-old.octoblu.dev:80
  http-request set-header Host meshblu-old.octoblu.dev

backend meshblu-socket-io
  timeout queue 5000
  timeout server 86400000
  timeout connect 86400000
  timeout check 1s
  option forwardfor
  no option httpclose
  option http-server-close
  option forceclose
  stick-table type string len 40 size 20M expire 2m
  stick store-response set-cookie(io)
  stick on cookie(io)
  stick on url_param(sid)
  server meshblu-socket-io meshblu-old.octoblu.dev:80
  http-request set-header Host meshblu-old.octoblu.dev

frontend http-in
  bind *:80
  mode http

  acl is-delete method DELETE
  acl is-get method GET
  acl is-patch method PATCH
  acl is-put method PUT
  acl is-post method POST

  acl use-meshblu-http path_reg ^/v2/devices/[^/]+/subscriptions$
  acl use-meshblu-http-v2-devices path_reg ^/v2/devices/[^/]+$
  acl use-meshblu-http-v2-get-devices path_reg ^/v2/devices$
  acl use-meshblu-http-v1-get-devices path_reg ^/devices$
  acl use-meshblu-http-devices path_reg ^/devices/[^/]+$
  acl use-meshblu-http-my-devices path_reg ^/mydevices$
  acl use-meshblu-http-claim-device path_reg ^/claimdevice/[^/]+$
  acl use-meshblu-http-delete-tokens path_reg ^/devices/[^/]+/tokens$
  acl use-meshblu-http-get-global-public-key path_reg ^/publickey$
  acl use-meshblu-http-get-status path_reg ^/status$
  acl use-meshblu-http-register-device path_reg ^/devices$
  acl use-meshblu-http-unregister-device path_reg ^/devices/[^/]+$
  acl use-meshblu-http-new-authenticate path_reg ^/authenticate$
  acl use-meshblu-http-old-authenticate path_reg ^/authenticate/[^/]+$
  acl use-meshblu-http-subscriptions path_reg ^/v2/devices/[^/]+/subscriptions/[^/]+/[^/]+$

  acl use-meshblu-http path_reg ^/v3/devices/[^/]+$
  acl use-meshblu-http path_reg ^/search/devices$

  acl use-meshblu-http path_beg /messages
  acl use-meshblu-http path_beg /v2/whoami
  acl use-meshblu-http path_beg /subscribe

  acl use-meshblu-long-lasting path_beg /data
  acl use-meshblu-socket-io path_beg /socket.io
  acl use-meshblu-websocket hdr(Upgrade) -i WebSocket

  use_backend meshblu-socket-io if use-meshblu-socket-io
  use_backend meshblu-websocket if use-meshblu-websocket
  use_backend meshblu-long-lasting if use-meshblu-long-lasting

  use_backend meshblu-http if is-delete use-meshblu-http-delete-tokens
  use_backend meshblu-http if is-get use-meshblu-http-v2-devices
  use_backend meshblu-http if is-get use-meshblu-http-devices
  use_backend meshblu-http if is-get use-meshblu-http-get-global-public-key
  use_backend meshblu-http if is-get use-meshblu-http-get-status
  use_backend meshblu-http if is-post use-meshblu-http-register-device
  use_backend meshblu-http if is-delete use-meshblu-http-unregister-device
  use_backend meshblu-http if is-get use-meshblu-http-v2-get-devices
  use_backend meshblu-http if is-get use-meshblu-http-v1-get-devices
  use_backend meshblu-http if is-get use-meshblu-http-my-devices
  use_backend meshblu-http if is-post use-meshblu-http-claim-device
  use_backend meshblu-http if is-post use-meshblu-http-new-authenticate
  use_backend meshblu-http if is-get use-meshblu-http-old-authenticate
  use_backend meshblu-http if is-post use-meshblu-http-subscriptions
  use_backend meshblu-http if is-delete use-meshblu-http-subscriptions


  use_backend meshblu-http if is-patch use-meshblu-http-v2-devices
  use_backend meshblu-http if is-put use-meshblu-http-v2-devices
  use_backend meshblu-http if is-put use-meshblu-http-devices

  use_backend meshblu-http if use-meshblu-http

  default_backend meshblu-original-flavor

EOF
