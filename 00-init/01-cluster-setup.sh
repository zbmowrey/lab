#!/usr/bin/env zsh

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/lib/styles.sh"

is_node_configured() {
  local ip="$1"
  talosctl --nodes "$ip" --insecure get machineconfig &>/dev/null
}

CONFIG_LOCATION_FILE="$SCRIPT_DIR/talos-config/config_location"
if [[ -f "$CONFIG_LOCATION_FILE" ]]; then
  CONFIG_PATH=$(<"$CONFIG_LOCATION_FILE")
  TALOS_DIR="$(eval echo "$CONFIG_PATH")"
  mkdir -p "$TALOS_DIR" || {
    error "Failed to create Talos configuration directory: $TALOS_DIR"
    exit 1
  }
  info "Using external Talos configuration directory from config_location: $TALOS_DIR"
else
  TALOS_DIR="$SCRIPT_DIR/talos-config"
fi

section "Pre-Requisite: TalosCTL Installation"

if ! command -v talosctl &>/dev/null; then
  error "TalosCTL is not installed. Please install it first: brew install siderolabs/tap/talosctl"
  exit 1
else
  success "TalosCTL found: $(talosctl version)"
fi

section "Pre-Requisite: Cluster Nodes In Place"

echo "You must first have at least one node intended for the control plane and at least one node intended for worker nodes."
echo "When you've set up Talos OS on those nodes, record their IP addresses."

# Prompt for the control plane node IP address
read -p "Enter the control plane node IP address: " CONTROL_PLANE_IP

# Validate the control plane IP address
if [[ -z "$CONTROL_PLANE_IP" ]]; then
  error "Control plane IP address cannot be empty."
  exit 1
fi

# Validate the control plane IP address format
if ! [[ "$CONTROL_PLANE_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  error "Invalid control plane IP address format. Please enter a valid IPv4 address."
  exit 1
fi

# Generate the Talos configuration for the cluster
section "Cluster Configuration: TalosCTL"

# Prompt the user for the cluster name
read -p "Enter the cluster name (default: talos-proxmox-cluster): " CLUSTER_NAME
CLUSTER_NAME=${CLUSTER_NAME:-talos-proxmox-cluster}

talosctl gen config "$CLUSTER_NAME" https://"$CONTROL_PLANE_IP":6443 --output-dir "$TALOS_DIR" || {
  error "Failed to generate Talos configuration."
  exit 1
}

if is_node_configured "$CONTROL_PLANE_IP"; then
  warning "Control plane node $CONTROL_PLANE_IP already configured. Skipping apply-config."
else
  talosctl apply-config --insecure --nodes "$CONTROL_PLANE_IP" --file "$TALOS_DIR"/controlplane.yaml || {
    error "Failed to apply configuration to control plane node."
    exit 1
  }
fi

success "Control Plane is configured. Moving on to worker nodes..."

# Repeat prompt for worker node IP addresses, stopping when the user enters an empty line
WORKER_NODES=()
while true; do
  read -p "Enter a worker node IP address (or press Enter to finish): " WORKER_IP
  if [[ -z "$WORKER_IP" ]]; then
    break
  fi
  WORKER_NODES+=("$WORKER_IP")
done

# Validate worker node IP addresses
if [[ ${#WORKER_NODES[@]} -eq 0 ]]; then
  error "At least one worker node IP address must be provided."
  exit 1
fi

# For each worker node, validate IP format and then apply the configuration
for WORKER_IP in "${WORKER_NODES[@]}"; do
  if ! [[ "$WORKER_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Invalid worker node IP address format: $WORKER_IP"
    exit 1
  fi

  if is_node_configured "$WORKER_IP"; then
    warning "Worker node $WORKER_IP already configured. Skipping apply-config."
  else
    talosctl apply-config --insecure --nodes "$WORKER_IP" --file "$TALOS_DIR"/worker.yaml || {
      error "Failed to apply configuration to worker node: $WORKER_IP"
      exit 1
    }
  fi
done

success "Worker nodes configured successfully."

export TALOSCONFIG="$TALOS_DIR/talosconfig"

talosctl config endpoint "$CONTROL_PLANE_IP"
talosctl config node "$CONTROL_PLANE_IP"

if talosctl --nodes "$CONTROL_PLANE_IP" get etcd &>/dev/null; then
  warning "Cluster already appears to be bootstrapped."
  read -p "Would you like to skip bootstrapping? [Y/n] " SKIP_BOOTSTRAP
  SKIP_BOOTSTRAP=${SKIP_BOOTSTRAP:-Y}
  if [[ "$SKIP_BOOTSTRAP" =~ ^[Yy]$ ]]; then
    SKIP_BOOT=true
  fi
fi

if [[ "$SKIP_BOOT" != true ]]; then
  talosctl bootstrap || {
    error "Bootstrap failed."
    exit 1
  }
fi

section "Kubeconfig Setup: Access Your New Cluster"

notice "Talos will now generate a kubeconfig file so you can interact with your cluster via kubectl."

# Check if ~/.kube/config already exists
if [[ -f "$HOME/.kube/config" ]]; then
  echo ""
  warning "An existing kubeconfig file was detected at ~/.kube/config."
  echo "This file may be used by other clusters or Kubernetes tools."
  echo ""

  while true; do
    read -p "Do you want to overwrite your existing ~/.kube/config? [y/N]: " REPLACE_CONFIG
    REPLACE_CONFIG=${REPLACE_CONFIG:-N}
    if [[ "$REPLACE_CONFIG" =~ ^[Yy]$ ]]; then
      if rm -f "$HOME/.kube/config"; then
        talosctl kubeconfig --output-dir "$HOME/.kube" || {
          error "Failed to generate kubeconfig at ~/.kube/config"
          exit 1
        }
        success "Kubeconfig successfully written to ~/.kube/config"
      else
        error "Could not remove existing kubeconfig. Check permissions."
        exit 1
      fi
      break
    elif [[ "$REPLACE_CONFIG" =~ ^[Nn]$ ]]; then
      echo ""
      read -p "Enter the desired alternate path (default: ~/.kube/talos-config): " ALT_CONFIG
      ALT_CONFIG=${ALT_CONFIG:-$HOME/.kube/talos-config}

      mkdir -p "$(dirname "$ALT_CONFIG")"
      talosctl kubeconfig \
        --output-dir "$(dirname "$ALT_CONFIG")" \
        --output-file "$(basename "$ALT_CONFIG")" || {
          error "Failed to generate kubeconfig at $ALT_CONFIG"
          exit 1
        }

      success "Kubeconfig saved to $ALT_CONFIG"
      echo "To use it temporarily, run:"
      echo ""
      echo "  export KUBECONFIG=$ALT_CONFIG"
      echo ""
      break
    else
      warning "Please answer with 'y' or 'n'."
    fi
  done
else
  # No existing kubeconfig, safe to write
  talosctl kubeconfig --output-dir "$HOME/.kube" || {
    error "Failed to generate kubeconfig at ~/.kube/config"
    exit 1
  }
  success "Kubeconfig successfully written to ~/.kube/config"
fi

# Prompt the user - to permanently add the talosctl config to their environment through bashr or zshrc etc
section "Shell Integration: TALOSCONFIG Environment Variable"
notice "TalosCTL uses the TALOSCONFIG environment variable to locate your cluster configuration."

TALOS_ENV_LINE="export TALOSCONFIG=\"$TALOS_DIR/talosconfig\""
read -p "Would you like to add TALOSCONFIG to your shell profile for future use? [Y/n]: " ADD_TO_PROFILE
ADD_TO_PROFILE=${ADD_TO_PROFILE:-N}

if [[ "$ADD_TO_PROFILE" =~ ^[Yy]$ ]]; then
  UPDATED=false

  for PROFILE in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [[ -f "$PROFILE" ]]; then
      if grep -q "$TALOS_ENV_LINE" "$PROFILE"; then
        info "TALOSCONFIG is already set in $PROFILE — skipping."
      else
        echo "$TALOS_ENV_LINE" >> "$PROFILE"
        success "Added TALOSCONFIG to $PROFILE"
        UPDATED=true
      fi
    fi
  done

  if [[ "$UPDATED" == false ]]; then
    warning "No known shell profile was updated. You may need to add the following manually:"
    echo "$TALOS_ENV_LINE"
  fi
else
  info "Skipped shell profile update. If needed, add this line to your profile:"
  echo "$TALOS_ENV_LINE"
fi
