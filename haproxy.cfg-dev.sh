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
  acl use-meshblu-http path_reg ^/devices/[^/]+/subscriptions$
  acl use-meshblu-http-delete-tokens path_reg ^/devices/[^/]+/tokens$

  acl use-meshblu-http path_reg ^/v3/devices/[^/]+$
  acl use-meshblu-http path_reg ^/search/devices$

  acl use-meshblu-http path_beg /messages
  acl use-meshblu-http path_beg /v2/whoami

  use_backend meshblu-http if is-delete use-meshblu-http-delete-tokens
  use_backend meshblu-http if use-meshblu-http

  default_backend meshblu-old

backend meshblu-old
  option forwardfor
  server meshblu-old meshblu-old.octoblu.dev:80 cookie meshblu-old
  http-request set-header Host meshblu-old.octoblu.dev

backend meshblu-http
  option forwardfor
  server meshblu-http meshblu-messages.octoblu.dev:80 cookie meshblu-http
  http-request set-header Host meshblu-messages.octoblu.dev

EOF
