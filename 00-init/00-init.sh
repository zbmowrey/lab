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
  "Addons: Configure the K8S Cluster with Essential Addons (Storage, DNS, Ingress, Cert-Manager)"
  "Secrets: Configure 1Password Operator & Connect for Secrets Management"
  "Replicator: Install Kubernetes Replicator to handle cloning of secrets and configmaps across namespaces"
  "Reloader: Install Reloader to automatically redeploy pods when secrets or configmaps change"
)
SCRIPTS=(
  "$SCRIPT_DIR/01-addons.sh"
  "$SCRIPT_DIR/02-secrets.sh"
  "$SCRIPT_DIR/03-kubernetes-replicator.sh"
  "$SCRIPT_DIR/04-reloader.sh"
)
HELP=(
  "Checks and enables core addons for the cluster, currently: cert-manager, cis-hardening, dashboard, dns, gpu, hostpath-storage, ingress, metrics-server"
  "This step installs and configures the [1Password Operator and Connect Server]
(https://developer.1password.com/docs/k8s/operator/?deployment-type=helm) so we
can define and manage secrets in 1Password. Secrets can automatically be pulled
into Kubernetes as part of deployments, and if done correctly, updated secrets
will result in automatic redeployment."
  "Installs the [Kubernetes Replicator](https://github.com/mittwald/kubernetes-replicator),
which allows us to clone secrets and configmaps across namespaces. This is useful for
sharing secrets between different namespaces in a secure way."
  "Installs the [Reloader](https://github.com/stakater/Reloader) to automatically redeploy pods on detection of changes to their associated secrets or configmaps."
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

