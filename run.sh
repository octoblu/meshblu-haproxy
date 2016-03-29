#!/bin/sh

assert_password() {
  local password="$1"

  if [ -z "$password" ]; then
    echo "PASSWORD not found, cowardly refusing to do anything"
    exit 1
  fi
}

run_haproxy() {
  haproxy -f /usr/local/etc/haproxy/haproxy.cfg &
  child=$!
  echo "Waiting for child process: $child"
  wait "$child"
}

write_haproxy() {
  local password="$1"

  cat ./haproxy.cfg | sed s/{{PASSWORD}}/${password}/g > /usr/local/etc/haproxy/haproxy.cfg
}

main(){
  local password="${PASSWORD}"
  assert_password "${password}"

  write_haproxy "${password}"
  run_haproxy
}

main $@
