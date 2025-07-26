#!/usr/bin/env zsh

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/lib/styles.sh"

section "Cluster Initialization: MicroK8s Installation"

REMOTE_HOST="jarvis"

REMOTE_COMMANDS=(
  "sudo snap install microk8s --classic --channel=1.32"
  "/snap/bin/microk8s start"
  "/snap/bin/microk8s status --wait-ready"
  "sudo usermod -a -G microk8s \$(stat -c '%U' ~)"
  "sudo ufw allow 16443/tcp"
  "/snap/bin/microk8s config > ~/.kube/config"
)

REMOTE_COMMAND=""
for command in "${REMOTE_COMMANDS[@]}"; do
  ssh $REMOTE_HOST "$command" || {
    error "Failed to execute command: $command on $REMOTE_HOST"
    exit 1
  }
done

scp $REMOTE_HOST:~/.kube/config ~/.kube/config || {
  error "Failed to copy kube/config from $REMOTE_HOST."
  exit 1
}

kubectl get nodes || {
  error "Failed to get nodes from the cluster. Ensure MicroK8s is running."
  exit 1
}

success "MicroK8s installed and configured on $REMOTE_HOST."