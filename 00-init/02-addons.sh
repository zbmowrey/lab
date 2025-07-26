#!/usr/bin/env zsh

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/lib/styles.sh"


section "Kubernetes Addons: Enabling Essential Addons"

REMOTE_HOST="jarvis"

# Note that cis-hardening forces you to use 'sudo microk8s' instead of 'microk8s' when
# working on the remote host. On my workstation, kubectl seems to work find on its own.

ADDONS=(
  cert-manager
  cis-hardening
  dashboard
  dns
  hostpath-storage
  ingress
  metrics-server
)

REMOTE_COMMAND=""
for addon in "${ADDONS[@]}"; do
  REMOTE_COMMAND+="sudo microk8s enable $addon;"
done

info "Preparing to enable the following add-ons on $REMOTE_HOST:"

ssh $REMOTE_HOST $REMOTE_COMMAND

success "Add-ons enabled on $REMOTE_HOST."