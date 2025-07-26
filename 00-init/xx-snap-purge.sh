#!/usr/bin/env bash
# If running in Zsh, enable Bash compatibility mode
if [ -n "$ZSH_VERSION" ]; then
  emulate -L sh
fi

set -euo pipefail

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/lib/styles.sh"

# Prompt the User that this will be destructive and all configuration will be lost. Require confirmation.
# The user must type "I understand" to proceed.

section "Kubernetes Snap Purge: Destructive Action"

read -p "This will purge all Kubernetes Snap configurations and data. Type 'I understand' to proceed: " confirmation
if [ "$confirmation" != "I understand" ]; then
  error "Aborting. You must type 'I understand' to proceed."
  exit 1
fi

info "Purging all Kubernetes Snap configurations and data..."

ssh jarvis "sudo snap remove microk8s --purge || true" || {
  error "Failed to purge Kubernetes Snap on remote host."
  exit 1
}

info "Kubernetes Snap purged successfully."