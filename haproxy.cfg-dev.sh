#!/bin/bash
cat <<EOF
global
  debug

defaults
  log     global
  mode    http
  option  httplog
  option  dontlognull
  timeout connect 5000
  timeout client  50000
  timeout server  50000

frontend localnodes
  bind *:80
  mode http
  default_backend nodes

backend nodes
  mode http
  option forwardfor
  server web01 meshblu-old.octoblu.dev:80 check
  http-request set-header Host meshblu-old.octoblu.dev

EOF
