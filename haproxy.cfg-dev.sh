#!/bin/bash
cat <<EOF
global
  debug

defaults
  log     global
  mode    http
  option  httplog
  option  dontlognull
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
  acl use-meshblu-http path_reg ^/v2/devices/[^/]+/subscriptions$
  acl use-meshblu-http-v2-devices path_reg ^/v2/devices/[^/]+$
  acl use-meshblu-http-devices path_reg ^/devices/[^/]+$
  acl use-meshblu-http-delete-tokens path_reg ^/devices/[^/]+/tokens$
  acl use-meshblu-http-get-global-public-key path_reg ^/publicKey$

  acl use-meshblu-http path_reg ^/v3/devices/[^/]+$
  acl use-meshblu-http path_reg ^/search/devices$

  acl use-meshblu-http path_beg /messages
  acl use-meshblu-http path_beg /v2/whoami

  use_backend meshblu-http if is-delete use-meshblu-http-delete-tokens
  use_backend meshblu-http if is-get use-meshblu-http-v2-devices
  use_backend meshblu-http if is-get use-meshblu-http-devices
  use_backend meshblu-http if is-get use-meshblu-http-get-global-public-key

  use_backend meshblu-http if is-patch use-meshblu-http-v2-devices
  use_backend meshblu-http if is-put use-meshblu-http-v2-devices
  use_backend meshblu-http if is-put use-meshblu-http-devices

  use_backend meshblu-http if use-meshblu-http

  default_backend meshblu-old

backend meshblu-old
  option forwardfor
  server meshblu-old meshblu-old.octoblu.dev:80 cookie meshblu-old
  http-request set-header Host meshblu-old.octoblu.dev

backend meshblu-http
  option forwardfor
  server meshblu-http meshblu-server-http.octoblu.dev:80 cookie meshblu-http
  http-request set-header Host meshblu-server-http.octoblu.dev

EOF