#!/usr/bin/env bash

# Create namespace
k create namespace argocd

# Apply Manifest
k apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready (re-run until pods all show as Running)
k get pods -n argocd

# Patch the ArgoCD server service to use ClusterIP
k patch svc argocd-server -n argocd \
  -p '{"spec": {"type": "ClusterIP"}}'

# Create an ingress resource for ArgoCD

k apply -n argocd -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  rules:
  - host: argocd.zbmowrey.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
EOF

