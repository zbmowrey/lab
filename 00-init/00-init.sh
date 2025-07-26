#!/usr/bin/env bash
# If running in Zsh, enable Bash compatibility mode
if [ -n "$ZSH_VERSION" ]; then
  emulate -L sh
fi

set -euo pipefail

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/lib/styles.sh"

# --- Step Definitions ---
STEPS=(
  "Cluster Setup: Install MicroK8s and Get KubeConfig"
  "Addons: Enable Core Addons"
  "Secrets: Install 1Password Operator and Connect Server"
  "Kubernetes Replicator: Install and Configure"
  "Reloader: Install and Configure"
  "Kustomize Global: Apply Global Infrastructure Configuration"
)
SCRIPTS=(
  "$SCRIPT_DIR/01-cluster-setup.sh"
  "$SCRIPT_DIR/02-addons.sh"
  "$SCRIPT_DIR/03-secrets.sh"
  "$SCRIPT_DIR/04-kubernetes-replicator.sh"
  "$SCRIPT_DIR/05-reloader.sh"
  "$SCRIPT_DIR/06-kustomize-global.sh"
)
HELP=(
  "Cluster Setup: Install microk8s snap, start it, add the SSH user to the microk8s group, then export/copy ~/.kube/config to the local machine."
  "Enable essential Kubernetes addons:
  cert-manager
  cis-hardening
  dashboard
  dns
  gpu
  hostpath-storage
  ingress
  metrics-server"
  "Install the 1Password Operator and connect it to your 1Password account for secrets management. Requires JWT Access Token and Credentials JSON file."
  "Install Kubernetes Replicator to sync secrets and configmaps across namespaces."
  "Install Reloader to automatically reload pods when ConfigMaps or Secrets change."
  "This creates the letsencrypt cluster issuer, DNS API secret (1pass), wildcard TLS certificate & secret, and a catch-all 404 ingress page."
)

# --- Banner ---
banner() {
  command -v clear >/dev/null 2>&1 && clear
  printf "%b\n" "${SPARKLE}${BOLD}Home Lab Bootstrap Script${RESET}${SPARKLE}"
  printf "%b\n\n" "${CYAN}./00-init.sh is all you need...${RESET}"
}

# --- Menu ---
show_menu() {
  printf "%b\n" "${BOLD}What would you like to do today?${RESET}"
  printf "%b\n" "  ${BOLD}0${RESET}: Run ${GREEN}ALL STEPS${RESET} (recommended)"
  for ((i = 0; i < ${#STEPS[@]}; i++)); do
    step_name="${STEPS[$i]%%:*}"
    printf "%b\n" "  ${BOLD}$((i+1))${RESET}: Run ${YELLOW}${step_name}${RESET}"
  done
  printf "%b\n" "  ${BOLD}h${RESET}: Help for a step"
  printf "%b\n\n" "  ${BOLD}q${RESET}: Quit (or Ctrl+C, but where's the fun in that?)"
}

# --- Run a Step ---
run_step() {
  local idx="$1"
  if [[ "$idx" -lt 0 || "$idx" -ge ${#STEPS[@]} ]]; then
    printf "%b\n" "${CROSS} No such step."
    return 1
  fi
  printf "%b\n" "${ARROW} ${BOLD}Starting:${RESET} ${STEPS[$idx]}"
  if "${SCRIPTS[$idx]}"; then
    printf "%b\n\n" "${CHECK} ${GREEN}${STEPS[$idx]} completed!${RESET}"
  else
    printf "%b\n\n" "${CROSS} ${RED}Step failed: ${STEPS[$idx]}${RESET}"
    exit 1
  fi
}

# --- Run All Steps ---
run_all() {
  printf "%b\n" "${SPARKLE}Starting bootstrap operations...${RESET}"
  for ((i = 0; i < ${#STEPS[@]}; i++)); do
    run_step "$i"
  done
  printf "%b\n" "${SPARKLE}${BOLD}All done! Your cluster is bootstrapped. ✨${RESET}"
}

# --- Help ---
show_help() {
  printf "%b" "Which step would you like help with? [1-${#STEPS[@]}] "
  read -r step
  if [[ "$step" =~ ^[1-9][0-9]*$ ]] && (( step >= 1 && step <= ${#STEPS[@]} )); then
    idx=$((step-1))
    step_name="${STEPS[$idx]%%:*}"
    printf "%b\n" "${BOLD}${step_name}${RESET}:"
    printf "%b\n\n" "${CYAN}${HELP[$idx]}${RESET}"
  else
    printf "%b\n\n" "${CROSS} Invalid step."
  fi
}

# --- Main Loop ---
banner
while true; do
  show_menu
  printf "%b" "${BOLD}Choose an option:${RESET} "
  read -r opt
  case "$opt" in
    0)
      run_all
      break
      ;;
    [1-9])
      idx=$((opt-1))
      run_step "$idx"
      exit $?
      ;;
    h|help)
      show_help
      ;;
    q|quit|exit)
      printf "%b\n" "${YELLOW}Goodbye!${RESET}"
      break
      ;;
    *)
      printf "%b\n" "${CROSS} Invalid option. Try again!"
      ;;
  esac
done

