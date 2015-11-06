#!/bin/sh

if [ -z "$SERVERS" ]; then
  echo "SERVERS not found, cowardly refusing to do anything"
  exit 1
fi

./haproxy.cfg.sh > /usr/local/etc/haproxy/haproxy.cfg
haproxy -d -f /usr/local/etc/haproxy/haproxy.cfg
