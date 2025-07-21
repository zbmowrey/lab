#!/usr/bin/env zsh

set -euo pipefail

# This can't be copied, because it needs to get this script's absolute path for the source.
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/lib/styles.sh"


NAMESPACE="1password"
CREDENTIAL_FILE="1password-credentials.json"
UPGRADE_MODE=false

# --- 1. Prerequisites ---
section "Environment Validation"

if ! command -v helm &>/dev/null; then
  error "Helm is not installed. See: https://helm.sh/docs/intro/install/"
  exit 1
else
  success "Helm found: $(helm version --short)"
fi

# --- Namespace Comfort: Ensure namespace exists ---
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
  info "Creating namespace '$NAMESPACE'..."
  kubectl create namespace "$NAMESPACE"
  success "Namespace '$NAMESPACE' created."
else
  success "Namespace '$NAMESPACE' already exists."
fi

# --- Comfort: Check if connect is already installed ---
if helm status connect --namespace "$NAMESPACE" &>/dev/null; then
  # Get currently installed chart version (using helm list for accuracy)
  CURRENT_VERSION=$(helm list --namespace "$NAMESPACE" -f "^connect$" -o json | jq -r '.[0].chart' | sed 's/^[^0-9]*-//')
  # Get latest available version from repo
  LATEST_VERSION=$(helm search repo 1password/connect --version '*' -o json | jq -r '.[0].version')

  if [[ -z "$CURRENT_VERSION" || -z "$LATEST_VERSION" ]]; then
    info "Could not determine current or latest chart version. Proceeding with Upgrade Mode."
  elif [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
    success "1Password Connect is already at the latest chart version (${CYAN}$CURRENT_VERSION${RESET}). No upgrade needed."
    info "No changes will be made. Exiting at your request."
    exit 0
  else
    info "Currently installed version: ${CYAN}$CURRENT_VERSION${RESET}"
    info "Latest available version:   ${CYAN}$LATEST_VERSION${RESET}"
    prompt "Would you like to upgrade to the latest version? [Y/n] "
    read -r UPGRADE_CHOICE
    UPGRADE_CHOICE=${UPGRADE_CHOICE:-Y}
    if [[ "$UPGRADE_CHOICE" =~ ^[Yy]$ ]]; then
      UPGRADE_MODE=true
      success "Upgrade mode enabled. We'll upgrade the release later in this script."
    else
      info "No changes will be made. Exiting at your request."
      exit 0
    fi
  fi
fi


if ! command -v jq &>/dev/null; then
  error "jq is not installed. Please install it for JSON processing."
  exit 1
else
  success "jq found: $(jq --version)"
fi

# --- 2. Validate credentials file (structure only, not contents) ---
section "Validating 1Password Credentials File"

while [[ ! -f "$CREDENTIAL_FILE" ]]; do
  error "'$CREDENTIAL_FILE' not found. The file name must match exactly."
  info "You need to download this file from your 1Password developer portal:"
  echo -e "  ${CYAN}DOCS: https://developer.1password.com/docs/connect/get-started${RESET}"
  echo -e "  ${CYAN}PORTAL: https://my.1password.com/developer-tools/active/servers${RESET}"
  prompt "Once you have placed '$CREDENTIAL_FILE' here, press Enter to continue (or Ctrl+C to abort):"
  read
done

if ! jq empty "$CREDENTIAL_FILE" 2>/dev/null; then
  error "'$CREDENTIAL_FILE' is not valid JSON."
  exit 1
fi

# Validate expected fields in credentials file
REQUIRED_FIELDS=(
  ".verifier.salt"
  ".verifier.localHash"
  ".encCredentials.kid"
  ".encCredentials.enc"
  ".encCredentials.cty"
  ".encCredentials.iv"
  ".encCredentials.data"
  ".version"
  ".deviceUuid"
  ".uniqueKey.alg"
  ".uniqueKey.k"
)
for field in "${REQUIRED_FIELDS[@]}"; do
  if [[ "$(jq "$field" "$CREDENTIAL_FILE")" == "null" ]]; then
    error "Missing required field: $field in $CREDENTIAL_FILE"
    exit 1
  fi
done
success "'$CREDENTIAL_FILE' found and structure validated."

# --- 3. Add/Update Helm repo ---
section "1Password Helm Repository Setup"

if helm repo list | grep -q 1password; then
  info "Helm repo '1password' already present."
else
  info "Adding 1Password Helm repo..."
  helm repo add 1password https://1password.github.io/connect-helm-charts/
  success "Repo added."
fi
info "Updating Helm repos..."
helm repo update > /dev/null
success "Helm repos updated."

# --- 4. 1Password Connect Token Handling ---
section "1Password Connect Token"

# Where do we look for the token?
TOKEN_FILE="1password-connect-token"

function validate_jwt() {
  local token="$1"
  if ! [[ "$token" =~ ^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$ ]]; then
    echo "DEBUG: Regex failed"
    return 1
  fi
  local payload=$(echo "$token" | cut -d. -f2)
  b64url_to_b64() {
    local input="$1"
    local b64=$(echo "$input" | tr '_-' '/+')
    local mod4=$(( ${#b64} % 4 ))
    if (( mod4 == 2 )); then
      b64="${b64}=="
    elif (( mod4 == 3 )); then
      b64="${b64}="
    elif (( mod4 != 0 )); then
      echo "DEBUG: Invalid base64url length"
      return 1
    fi
    echo "$b64"
  }
  local decoded
  decoded=$(b64url_to_b64 "$payload" | base64 -d 2>/dev/null) || { echo "DEBUG: base64 decode failed"; return 1; }
  echo "$decoded" | jq empty 2>/dev/null || { echo "DEBUG: jq failed"; return 1; }
  return 0
}

# Try to read a valid token from the file, if it exists
OP_CONNECT_TOKEN=""
if [[ -f "$TOKEN_FILE" ]]; then
  info "Found token file: ${CYAN}$TOKEN_FILE${RESET}"
  OP_CONNECT_TOKEN="$(< "$TOKEN_FILE")"
  if [[ -z "$OP_CONNECT_TOKEN" ]]; then
    error "Token file is empty. We'll prompt you for a token."
  elif ! validate_jwt "$OP_CONNECT_TOKEN"; then
    error "Token file does not contain a valid JWT. We'll prompt you for a new token."
    OP_CONNECT_TOKEN=""
  else
    success "Loaded valid JWT from file."
  fi
fi


# If no valid token, prompt up to MAX_ATTEMPTS times
MAX_ATTEMPTS=3
if [[ -z "$OP_CONNECT_TOKEN" ]]; then
  for ((i=1; i<=$MAX_ATTEMPTS; i++)); do
    echo -e "${BOLD}${CYAN}1Password Connect Token Input (Attempt $i/${MAX_ATTEMPTS})${RESET}"
    echo -e "${YELLOW}You can paste your 1Password Connect JWT token below.${RESET}"
    echo -e "If you'd like, we'll offer to save it for next time! (Stored as plaintext at: ${CYAN}$TOKEN_FILE${RESET})"
    prompt "Paste your 1Password Connect token (JWT): "
    read -r OP_CONNECT_TOKEN

    if [[ -z "$OP_CONNECT_TOKEN" ]]; then
      error "Token cannot be empty."
      continue
    fi
    if ! validate_jwt "$OP_CONNECT_TOKEN"; then
      error "This does not appear to be a valid JWT. Make sure you copied the full token from your 1Password dashboard."
      OP_CONNECT_TOKEN=""
      continue
    fi
    success "Valid JWT received! 🎉"
    prompt "Would you like to save this token for next time? [Y/n] "
    read -r SAVE_TOKEN
    SAVE_TOKEN=${SAVE_TOKEN:-Y}
    if [[ "$SAVE_TOKEN" =~ ^[Yy]$ ]]; then
      echo "$OP_CONNECT_TOKEN" > "$TOKEN_FILE"
      chmod 600 "$TOKEN_FILE"
      success "Token saved to ${CYAN}$TOKEN_FILE${RESET} (plaintext)."
      echo -e "${YELLOW}Safety tip:${RESET} Protect this file like a password!"
    else
      info "Token will be used for this session only."
    fi
    break
  done

  if [[ -z "$OP_CONNECT_TOKEN" ]]; then
    error "Failed to acquire a valid JWT after $MAX_ATTEMPTS attempts."
    exit 1
  fi
fi

# --- 5. Confirm before install/upgrade ---
section "Installation Preview"

if [[ "$UPGRADE_MODE" == "true" ]]; then
  ACTION="Upgrade"
else
  ACTION="Install"
fi

info "Ready to ${ACTION} the 1Password Connect operator with:"
echo -e "• Credentials file:  ${CYAN}$CREDENTIAL_FILE${RESET}"
echo -e "• Token:            ${CYAN}${OP_CONNECT_TOKEN:0:6}...${RESET} (truncated)"

prompt "Proceed with Helm ${ACTION}? [Y/n] "
read -r PROCEED
PROCEED=${PROCEED:-Y}
if ! [[ $PROCEED =~ ^[Yy]$ ]]; then
  error "Aborted by user."
  exit 1
fi

# --- 6. Install or Upgrade Helm Release ---
section "Helm ${UPGRADE_MODE:+Upgrade}${UPGRADE_MODE:-Installation}"

if [[ "$UPGRADE_MODE" == "true" ]]; then
  info "Upgrading 1Password Connect Helm release..."
  helm upgrade connect 1password/connect \
    --set-file connect.credentials="$CREDENTIAL_FILE" \
    --set operator.create=true \
    --namespace "$NAMESPACE" \
    --set operator.token.value="$OP_CONNECT_TOKEN"
  success "1Password Connect Helm release upgraded."
else
  info "Installing 1Password Connect Helm release..."
  helm install connect 1password/connect \
    --set-file connect.credentials="$CREDENTIAL_FILE" \
    --set operator.create=true \
    --namespace "$NAMESPACE" \
    --set operator.token.value="$OP_CONNECT_TOKEN"
  success "1Password Connect Helm release installed."
fi

section "🎉 ${ACTION} Complete"
echo -e "${GREEN}${BOLD}All done! 1Password Connect is now operational. Check your workloads and celebrate your operational excellence.${RESET}\n"
echo -e "• Release:      ${BOLD}connect${RESET}"
echo -e "• Namespace:    ${BOLD}default${RESET} (change with --namespace as needed)"
echo -e "• Docs:         ${CYAN}https://developer.1password.com/docs/connect${RESET}"
