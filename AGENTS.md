# Homelab Agent Guidelines

## Agent Restrictions

⚠️ **IMPORTANT**: Agents cannot commit git changes unless explicitly granted permission by the user.

**PLEASE** also understand that this project is GitOps, which means that any changes will need to be pushed to Git and reconciled (potentially automatically) by Flux CD.

**DO NOT** apply kubectl files directly without asking for permission. You can use kubectl and delete stuff if you have permission, but most changes should go through Git and Flux for consistency and traceability.

## Documentation Policy

- **No docs/ folder**: All documentation deleted
- **Only README.md and AGENT.md**: These are the sole documentation files
- **Self-documenting code**: Code should be clear and comments only where necessary

## Helm Chart Guidelines

- **No complex templating**: Keep charts as simple as possible
- **No Helm best practices needed**: These charts are only used by you, not shared
- **Avoid unnecessary abstractions**: Don't use helper templates, values files, or complex conditionals
- **Direct is better**: Use static manifests with simple substitutions where needed
- **Focus on working, not elegant**: Deployments that work are more important than perfectly templated charts

## Other notes

- **Cloud registry with proxy**: Use Ollama Cloud or similar services for application deployments
- **External Secrets v1**: Always use `apiVersion: external-secrets.io/v1` for ExternalSecret manifests
- **Immutable PVCs**: For bound PVCs, ensure Chart.yaml version is incremented to force recreation rather than update
- **App chart structure**: Each app has its own chart in `charts/<app>/` with individual manifest files (deployment.yaml, service.yaml, ingress.yaml, pvc.yaml, externalsecret.yaml) without app name prefixes
- **HelmReleases**: Add HelmRelease to `charts/homelab-apps/templates/<app>.yaml` referencing `./charts/<app>`
- **Bitwarden/ExternalSecrets**: Always use the secret store of "bitwarden-secrets-manager" to get secrets

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
- **Flux timeout**: Always use prefix `timeout 10` for flux commands to avoid hanging indefinitely

## Project Structure

```tree
homelab/
├── ansible/          # Infrastructure provisioning (Ansible)
├── charts/           # Helm charts for applications
├── README.md         # Main project documentation
├── AGENT.md          # Agent guidelines and project context
└── scripts/          # Utility scripts
```
