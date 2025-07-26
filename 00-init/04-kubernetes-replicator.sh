#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/lib/styles.sh"

APP_NAME="kubernetes-replicator"
NAMESPACE="default"
REPO_NAME="mittwald"
REPO_URL="https://helm.mittwald.de"
CHART="${REPO_NAME}/${APP_NAME}"
DESIRED_VERSION="v2.12.0" # You can set a fixed version here

section "Kubernetes Replicator: Smart Helm Installer"

# --- Helper Functions ---
function helm_installed() {
  helm status "$APP_NAME" -n "$NAMESPACE" &>/dev/null
}

function get_installed_chart_version() {
  helm list -n "$NAMESPACE" -o json | jq -r ".[] | select(.name==\"$APP_NAME\") | .chart" | cut -d- -f2
}

function get_latest_chart_version() {
  helm search repo "$CHART" --versions -o json | jq -r '.[0].version'
}

function get_installed_app_version() {
  helm list -n "$NAMESPACE" -o json | jq -r ".[] | select(.name==\"$APP_NAME\") | .app_version"
}

function get_latest_app_version() {
  helm show chart "$CHART" | grep ^appVersion: | awk '{print $2}'
}

# --- Ensure Namespace Exists ---
section "Namespace Check"
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
  success "Namespace ${BOLD}${CYAN}$NAMESPACE${RESET} already exists."
else
  info "Namespace ${BOLD}${CYAN}$NAMESPACE${RESET} does not exist. Creating..."
  kubectl create namespace "$NAMESPACE"
  success "Namespace ${BOLD}${CYAN}$NAMESPACE${RESET} created."
fi

# --- Main Logic ---
info "Adding or updating helm repo: $REPO_NAME"
helm repo add "$REPO_NAME" "$REPO_URL" &>/dev/null || helm repo update "$REPO_NAME" &>/dev/null
helm repo update &>/dev/null
success "Helm repo ready."

if helm_installed; then
  # Installed, check chart & app version
  INSTALLED_CHART_VER="$(get_installed_chart_version)"
  LATEST_CHART_VER="$(get_latest_chart_version)"
  INSTALLED_APP_VER="$(get_installed_app_version)"
  LATEST_APP_VER="$(get_latest_app_version)"

  section "Replicator Already Installed"
  info "Current chart: ${BOLD}${CYAN}$INSTALLED_CHART_VER${RESET} (latest: ${LATEST_CHART_VER})"
  info "Current app: ${BOLD}${CYAN}$INSTALLED_APP_VER${RESET} (latest: ${LATEST_APP_VER})"

  # Smart update logic
  if [[ "$INSTALLED_APP_VER" == "$LATEST_APP_VER" ]]; then
    success "Replicator is already up to date! No action needed."
  else
    info "Update required. Here’s what will change:"
    echo -e "    App version:   ${YELLOW}${INSTALLED_APP_VER}${RESET} ${ARROW} ${GREEN}${LATEST_APP_VER}${RESET}"

    prompt "Proceed with upgrade? [${BOLD}Y${RESET}/${DIM}n${RESET}]: "
    read -r CONFIRM
    if [[ "$CONFIRM" =~ ^([yY][eE][sS]|[yY]|"")$ ]]; then
      info "Upgrading to chart ${GREEN}${LATEST_CHART_VER}${RESET}, app ${GREEN}${LATEST_APP_VER}${RESET}..."
      helm upgrade "$APP_NAME" "$CHART" \
        --namespace "$NAMESPACE" \
        --set logLevel=info \
        --set logFormat=json \
        --set image.repository=quay.io/mittwald/kubernetes-replicator \
        --set image.tag="$DESIRED_VERSION"
      success "Replicator upgraded!"
    else
      info "Upgrade cancelled by user."
      exit 0
    fi
  fi

else
  section "Replicator Not Found"
  info "Replicator not found in namespace ${BOLD}${CYAN}$NAMESPACE${RESET}."
  info "Installing ${BOLD}${CYAN}$APP_NAME${RESET} in namespace ${BOLD}${CYAN}$NAMESPACE${RESET}..."
  helm install "$APP_NAME" "$CHART" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --set logLevel=info \
    --set logFormat=json \
    --set image.repository=quay.io/mittwald/kubernetes-replicator \
    --set image.tag="$DESIRED_VERSION"
  success "Replicator installed!"
fi

section "Helm Replicator Script Complete"
success "Kubernetes-Replicator Install/Update Complete."
