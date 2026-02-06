# Homelab Agent Guidelines

## Project Overview

This is a GitOps-managed homelab running k3s with Tailscale mesh networking. The infrastructure uses Flux CD for continuous deployment from Git.

## Key Components

- **Kubernetes**: k3s cluster (single node: Gigabyte)
- **GitOps**: Flux CD manages all deployments from Git repository
- **Networking**: Tailscale VPN + Traefik ingress with native load balancing
- **Secrets**: External Secrets Operator + Bitwarden integration
- **Provisioning**: Ansible automation with SOPS-encrypted secrets
- **Domain**: kragh.dev with automated TLS via cert-manager

## Critical Workflow Notes

- All infrastructure changes go through Git → Flux
- Never commit secrets to Git (use Bitwarden + External Secrets)
- Respect dependency order: cert-manager → config → external-secrets → secrets-config → ingress → apps
- Use `flux reconcile kustomization flux-system --with-source` to sync changes

## Agent Restrictions

⚠️ **IMPORTANT**: Agents cannot commit git changes unless explicitly granted permission by the user.

## Project Structure

```tree
homelab/
├── ansible/          # Infrastructure provisioning (Ansible)
├── charts/           # Helm charts for applications
├── docs/             # Documentation
└── scripts/          # Utility scripts
```
