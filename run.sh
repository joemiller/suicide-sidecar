#!/bin/bash

set -eou pipefail

POD_NAME="${POD_NAME:-}"
NAMESPACE="${NAMESPACE:-}"
INOTIFYWAIT_OPTIONS="${INOTIFYWAIT_OPTIONS:- -e modify -e delete -e delete_self}"
KUBECTL_OPTIONS="${KUBECTL_OPTIONS:-}"

# POD_NAME env var must be set.
# We could fallback to the hostname which is Kubernetes sets to the pod-name, however, it has
# been indicated that this may not always be the case and we shouldn't rely on it.
if [[ -z "$POD_NAME" ]]; then
	echo "ERROR: Missing POD_NAME environment variable"
	exit 1
fi

# verify we can talk to the kubernetes api
if ! kubectl get pod "$POD_NAME" --namespace="$NAMESPACE" >/dev/null; then
	echo "Unable to contact kubernetes API"
	exit 1
fi

inotifywait $INOTIFYWAIT_OPTIONS "$@"
kubectl delete pod "$POD_NAME" --namespace="$NAMESPACE" $KUBECTL_OPTIONS
