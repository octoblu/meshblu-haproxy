#!/bin/bash

if [ -z "$SERVERS" ]; then
  echo "SERVERS not found, cowardly refusing to do anything"
  exit 1
fi

if [ -z "$SERVER_NAME" ]; then
  echo "SERVER_NAME not found, cowardly refusing to do anything"
  exit 1
fi

function _term {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
}

trap _term SIGTERM

./haproxy.cfg.sh > /usr/local/etc/haproxy/haproxy.cfg
haproxy -f /usr/local/etc/haproxy/haproxy.cfg -L $SERVER_NAME &

child=$!
echo "Waiting for child process: $child"
wait "$child"
