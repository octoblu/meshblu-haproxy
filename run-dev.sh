#!/bin/sh
if [ -z "$SERVER_NAME" ]; then
  echo "SERVER_NAME not found, cowardly refusing to do anything"
  exit 1
fi

haproxy -f ./haproxy.cfg-dev -L $SERVER_NAME
