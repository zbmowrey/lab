#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/lib/styles.sh"

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
  labels:
    kubernetes.io/metadata.name: metallb-system
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/warn: privileged
EOF


info "Installing Global Infrastructure with Kustomize"

# --- Ensure Kustomize is installed ---
if ! command -v kustomize &>/dev/null; then
  error "Kustomize is not installed. Please install it first."
  exit 1
else
  success "Kustomize found: $(kustomize version)"
fi

kustomize build apps/overlays/prod/global | kubectl apply -f -