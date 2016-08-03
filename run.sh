#!/bin/sh

assert_password() {
  local password="$1"

  if [ -z "$password" ]; then
    echo "PASSWORD not found, cowardly refusing to do anything"
    exit 1
  fi
}

assert_cluster_domain() {
  local cluster_domain="$1"

  if [ -z "$cluster_domain" ]; then
    echo "CLUSTER_DOMAIN not found, cowardly refusing to do anything"
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
  local cluster_domain="$2"

  cat ./haproxy.cfg | sed s/{{PASSWORD}}/${password}/g | sed s/{{CLUSTER_DOMAIN}}/${cluster_domain}/g > /usr/local/etc/haproxy/haproxy.cfg
}

main(){
  local password="${PASSWORD}"
  assert_password "${password}"
  local cluster_domain="${CLUSTER_DOMAIN}"
  assert_cluster_domain "${cluster_domain}"

  write_haproxy "${password}" "${cluster_domain}"
  run_haproxy
}

main $@
