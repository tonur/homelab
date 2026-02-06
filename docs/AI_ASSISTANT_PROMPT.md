# AI Assistant Prompt - Homelab Context

`Please read AI_ASSISTANT_PROMPT.md for context about this homelab setup`

Note from developer: please use "flux reconcile kustomization flux-system --with-source" to sync changes.

Use this as system context when working with this homelab repository.

## Quick Overview
- **k3s cluster**: Gigabyte (control) (former edge VPS and Beelink removed; future BGP/pfSense LB planned)
- **GitOps**: FluxCD manages everything from Git
- **Networking**: Tailscale mesh + Traefik ingress
- **Secrets**: External Secrets Operator + Bitwarden
- **Domain**: kragh.dev with auto TLS
- **Provisioning**: Ansible automation

## Key Principles
1. **GitOps First**: All changes go through Git → Flux
2. **No Secrets in Git**: Everything from Bitwarden via External Secrets
3. **Infrastructure as Code**: Ansible provisions, Flux manages
4. **Security**: SOPS encryption, Tailscale mesh, proper RBAC

## Project Structure

```text
├── ansible/                 # Infrastructure provisioning
│   ├── site.yaml           # Main playbook
│   ├── inventory/hosts.yaml # Machines
│   └── secrets/homelab.yaml # SOPS encrypted
├── clusters/homelab/        # GitOps manifests
│   ├── infrastructure/     # cert-manager → config → external-secrets → secrets-config → ingress
│   └── apps/               # Applications (json-resume deployed)
└── docs/                   # Documentation
```

## Current State
- ✅ Infrastructure: k3s + Tailscale + Traefik + External Secrets
- ✅ Applications: json-resume at kragh.dev
- 🚧 Planned: Home Assistant, Jellyfin, Nextcloud, backups

## Critical Dependencies (Respect Order!)
1. cert-manager
2. config (certificates & issuers)
3. external-secrets (depends on #2)
4. secrets-config (ClusterSecretStore, depends on #3)  
5. ingress/traefik (depends on #4)
6. apps (depends on #5)

## When Making Changes
- **Infrastructure**: Edit `clusters/homelab/infrastructure/`
- **Applications**: Edit `clusters/homelab/apps/`
- **Secrets**: Add to Bitwarden, create ExternalSecret resource
- **Provisioning**: Edit `ansible/` roles
- **Always**: Test dependencies and respect GitOps workflow

Read `/home/chkpe/work/homelab/docs/HOMELAB_CONTEXT.md` for comprehensive details.
