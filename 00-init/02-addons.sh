#!/usr/bin/env zsh

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/lib/styles.sh"


section "Kubernetes Addons: Enabling Essential Addons"

# Cert Manager
helm repo add jetstack https://charts.jetstack.io
# Ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# OpenEBS
helm repo add openebs https://openebs.github.io/charts

helm repo update

# Installs...

section "Installing Cert Manager"

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

section "Installing Ingress NGINX"

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.publishService.enabled=true

success "Kubernetes addons installed successfully."