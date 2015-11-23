#!/bin/bash

main(){
  echo "show table meshblu-socket-io" | socat stdio /tmp/haproxy.sock
}
main

