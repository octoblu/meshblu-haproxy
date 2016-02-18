#!/bin/sh
if [ -z "$SERVER_NAME" ]; then
  echo "SERVER_NAME not found, cowardly refusing to do anything"
  exit 1
fi

./haproxy.cfg-dev.sh > /usr/local/etc/haproxy/haproxy.cfg
haproxy -f /usr/local/etc/haproxy/haproxy.cfg -L $SERVER_NAME
