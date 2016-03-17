#!/bin/bash
cat <<EOF
global
  debug

defaults
  log     global
  mode    http
  option  httplog
  option  dontlognull
  option  redispatch
  timeout client  50000
  timeout queue 5000
  timeout server 86400000
  timeout connect 86400000

frontend http
  bind *:80
  mode http

  acl is-delete method DELETE
  acl is-get method GET
  acl is-patch method PATCH
  acl is-put method PUT
  acl is-post method POST

  acl use-meshblu-http path_reg ^/v2/devices/[^/]+/subscriptions$
  acl use-meshblu-http-v2-devices path_reg ^/v2/devices/[^/]+$
  acl use-meshblu-http-devices path_reg ^/devices/[^/]+$
  acl use-meshblu-http-v2-get-devices path_reg ^/v2/devices$
  acl use-meshblu-http-v1-get-devices path_reg ^/devices$
  acl use-meshblu-http-my-devices path_reg ^/mydevices$
  acl use-meshblu-http-delete-tokens path_reg ^/devices/[^/]+/tokens$
  acl use-meshblu-http-get-global-public-key path_reg ^/publickey$
  acl use-meshblu-http-get-status path_reg ^/status$
  acl use-meshblu-http-register-device path_reg ^/devices$
  acl use-meshblu-http-unregister-device path_reg ^/devices/[^/]+$

  acl use-meshblu-http path_reg ^/v3/devices/[^/]+$
  acl use-meshblu-http path_reg ^/search/devices$

  acl use-meshblu-http path_beg /messages
  acl use-meshblu-long-lasting path_beg /subscribe
  acl use-meshblu-http path_beg /v2/whoami

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

  use_backend meshblu-http if is-patch use-meshblu-http-v2-devices
  use_backend meshblu-http if is-put use-meshblu-http-v2-devices
  use_backend meshblu-http if is-put use-meshblu-http-devices

  use_backend meshblu-http if use-meshblu-http

  use_backend meshblu-long-lasting if use-meshblu-long-lasting

  default_backend meshblu-old

backend meshblu-old
  option forwardfor
  server meshblu-old meshblu-old.octoblu.dev:80 cookie meshblu-old
  http-request set-header Host meshblu-old.octoblu.dev

backend meshblu-http
  option forwardfor
  server meshblu-http meshblu-server-http.octoblu.dev:80
  http-request set-header Host meshblu-server-http.octoblu.dev
  http-request add-header X-Forwarded-Proto https if { ssl_fc }
  http-request set-header X-Forwarded-Port %[dst_port]

backend meshblu-long-lasting
  balance roundrobin
  timeout queue 5000
  timeout server 86400000
  timeout connect 86400000
  timeout check 1s
  option redispatch
  option httpchk HEAD / HTTP/1.1\r\nHost:localhost
  server meshblu-ll meshblu-server-http.octoblu.dev:80
  http-request add-header X-Forwarded-Proto https if { ssl_fc }
  http-request set-header X-Forwarded-Port %[dst_port]

EOF
