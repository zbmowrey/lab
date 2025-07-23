#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/lib/styles.sh"

APP_NAME="reloader"
NAMESPACE="default"
REPO_NAME="stakater"
REPO_URL="https://stakater.github.io/stakater-charts"
CHART="${REPO_NAME}/${APP_NAME}"
DESIRED_VERSION="latest" # Change to fixed version if desired

section "Installing Reloader with Helm"

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

# --- Add/Update Helm Repo ---
section "Helm Repository Setup"
info "Adding or updating helm repo: $REPO_NAME"
if helm repo add "$REPO_NAME" "$REPO_URL" &>/dev/null; then
  success "Helm repo ${BOLD}${CYAN}$REPO_NAME${RESET} added."
else
  info "Helm repo ${BOLD}${CYAN}$REPO_NAME${RESET} already exists, updating..."
fi
helm repo update &>/dev/null
success "Helm repo updated."

# --- Install or Upgrade Reloader ---
if helm_installed; then
  INSTALLED_CHART_VER="$(get_installed_chart_version)"
  LATEST_CHART_VER="$(get_latest_chart_version)"
  INSTALLED_APP_VER="$(get_installed_app_version)"
  LATEST_APP_VER="$(get_latest_app_version)"

  section "Reloader Already Installed"
  info "Installed chart version: ${BOLD}${CYAN}$INSTALLED_CHART_VER${RESET} (latest: ${LATEST_CHART_VER})"
  info "Installed app version: ${BOLD}${CYAN}$INSTALLED_APP_VER${RESET} (latest: ${LATEST_APP_VER})"

  if [[ "$INSTALLED_APP_VER" == "$LATEST_APP_VER" ]]; then
    success "Reloader is already up to date! No action needed."
  else
    info "Upgrade available:"
    echo -e "    App version:   ${YELLOW}${INSTALLED_APP_VER}${RESET} ${ARROW} ${GREEN}${LATEST_APP_VER}${RESET}"

    prompt "Proceed with upgrade? [${BOLD}Y${RESET}/${DIM}n${RESET}]: "
    read -r CONFIRM
    if [[ "$CONFIRM" =~ ^([yY][eE][sS]|[yY]|"")$ ]]; then
      info "Upgrading ${APP_NAME} to chart ${GREEN}${LATEST_CHART_VER}${RESET}, app ${GREEN}${LATEST_APP_VER}${RESET}..."
      helm upgrade "$APP_NAME" "$CHART" \
        --namespace "$NAMESPACE" \
        --set logLevel=info \
        --set logFormat=json \
        --set image.repository=stakater/reloader \
        --set image.tag="$DESIRED_VERSION"
      success "Reloader upgraded successfully."
    else
      info "Upgrade cancelled by user."
      exit 0
    fi
  fi

else
  section "Reloader Not Found"
  info "Installing ${BOLD}${CYAN}$APP_NAME${RESET} in namespace ${BOLD}${CYAN}$NAMESPACE${RESET}..."
  helm install "$APP_NAME" "$CHART" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --set logLevel=info \
    --set logFormat=json \
    --set image.repository=stakater/reloader \
    --set image.tag="$DESIRED_VERSION"
  success "Reloader installed successfully."
fi

section "Reloader Installation Script Complete"
success "Stakater Reloader install/update process finished."
