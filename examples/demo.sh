#!/bin/bash

set -eou pipefail

# Usage: run_with_timeout N cmd args...
run_with_timeout () {
	local time=$1
	shift
	# Run in a subshell to avoid job control messages
	( "$@" &
	  child=$!
	  # Avoid default notification in non-interactive shell for SIGTERM
	  trap -- "" SIGTERM
	  ( sleep "$time"
	    kill $child 2> /dev/null ) &
	  wait $child
	)
}

cleanup() {
  echo "==> Cleaning up kube resources"
  kubectl delete pod,secret -lapp=suicide-sidecar-test
}

wait_for_pod_ready() {
  local out
  for _ in {1..60}; do
    sleep 1
    out=$(kubectl get pod suicide-sidecar-test --no-headers)
    echo "$out"
    [[ "$out" =~ Running ]] && return 0
  done

  echo "timed out waiting for pod to become ready"
  return 1
}

wait_for_pod_deletion() {
  for _ in {1..90}; do
    sleep 1
    kubectl get pod suicide-sidecar-test --no-headers || return 0
  done
  echo "timed out waiting for pod to delete"
  return 1
}

main() {
  trap cleanup EXIT

  echo "==> Creating 'suicide-sidecar-test' pod"
  kubectl apply -f ./tests/fixtures/test-pod.yaml

  echo "==> Waiting for pod to enter Running state"
  wait_for_pod_ready
  sleep 3

  echo "==> Modifying secret volume"
  kubectl apply -f ./tests/fixtures/secret-update.yaml

  echo "==> Tailing logs (expect up to a minute wait for the secretVolume to be updated by Kubernetes)"
  if type -P kube-tail >/dev/null; then
    run_with_timeout 120 kube-tail -lapp=suicide-sidecar-test
  else
    run_with_timeout 120 kubectl logs suicide-sidecar-test -c suicide-sidecar -f
  fi
}
main "$@"
