# Homelab GitOps Infrastructure

> **Fully automated, GitOps-based homelab for kragh.dev domain using k3s, Tailscale, External Secrets Operator, and Flux**

A complete infrastructure-as-code solution for a self-hosted homelab that provides secure, reproducible, and automated deployment of applications and services.

## 🏗️ Architecture

```raw
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   VPS Edge      │    │    Gigabyte     │    │    Beelink      │
│   (k3s agent)   │    │  (k3s server)   │    │  (k3s agent)    │
│                 │    │                 │    │                 │
│ - Public access │    │ - Control plane │    │ - Worker node   │
│ - Load balancer │    │ - GitOps        │    │ - Applications  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Tailscale     │
                    │  Mesh Network   │
                    │                 │
                    │ - Secure VPN    │
                    │ - Zero-config   │
                    │ - Auto-discovery│
                    └─────────────────┘
```

## 🔧 Technology Stack

### **Infrastructure**
- **Kubernetes**: k3s (lightweight Kubernetes distribution)
- **GitOps**: Flux CD (continuous deployment from Git)
- **Networking**: Tailscale (secure mesh VPN)
- **Ingress**: Traefik (reverse proxy and load balancer)
- **Secrets**: External Secrets Operator + Bitwarden
- **Encryption**: SOPS with Age encryption

### **Deployment**
- **Provisioning**: Ansible (infrastructure automation)
- **DNS**: Hetzner DNS (automated certificate management)
- **Storage**: Local storage with Restic backups

## 🚀 Quick Start

### Prerequisites
- 3x Linux servers (VPS + 2 local machines)
- Bitwarden account with API access
- Hetzner DNS API token
- Age encryption key

### 1. Bootstrap Infrastructure

```bash
# Clone the repository
git clone <your-repo-url>
cd homelab

# Generate Age encryption key
./scripts/generate-age-key.sh

# Configure secrets in Bitwarden and update ansible/secrets/homelab.yaml
# Run Ansible to provision cluster
cd ansible
ansible-playbook -i inventory/hosts.ini site.yaml
```

### 2. Deploy Applications via GitOps

```bash
# Flux will automatically deploy everything from Git
# Check deployment status
kubectl get gitrepository -A
kubectl get kustomization -A
kubectl get helmrelease -A
```

## 📁 Project Structure

```raw
homelab/
├── ansible/                    # Infrastructure provisioning
│   ├── roles/
│   │   ├── base/              # Base system setup
│   │   ├── tailscale-interactive/  # Tailscale mesh networking
│   │   ├── k3s-server/        # Kubernetes control plane
│   │   ├── k3s-agent/         # Kubernetes worker nodes
│   │   └── k8s-secrets/       # Bootstrap secrets
│   ├── inventory/             # Server inventory
│   ├── secrets/               # SOPS-encrypted secrets
│   └── site.yaml             # Main playbook
│
├── clusters/homelab/          # Kubernetes manifests
│   ├── kustomization.yaml    # 🎯 Single GitOps entry point
│   ├── infrastructure/       # Infrastructure components
│   │   ├── external-secrets/ # Secret management
│   │   └── ingress/          # Traefik reverse proxy
│   └── apps/                 # Application deployments
│
├── scripts/                  # Utility scripts
├── docs/                     # Documentation
└── README.md                 # This file
```

## 🔐 Security & Secrets

### **Secret Management Strategy**
1. **Bootstrap Secret**: Bitwarden credentials stored in k3s `default` namespace (via Ansible)
2. **Dynamic Secrets**: All other secrets fetched from Bitwarden via External Secrets Operator
3. **Encryption**: All sensitive files encrypted with SOPS + Age

### **Key Security Features**
- ✅ SOPS encryption for all sensitive data
- ✅ External Secrets Operator for dynamic secret injection
- ✅ Tailscale mesh VPN for secure inter-node communication
- ✅ Automated TLS certificates via cert-manager + Hetzner DNS
- ✅ GitOps workflow prevents configuration drift

## 🏠 Applications

### **Infrastructure Services**
- **Traefik**: Reverse proxy and load balancer
- **External Secrets Operator**: Dynamic secret management
- **cert-manager**: Automated TLS certificate management

### **Homelab Applications**

#### ✅ **Planned Applications**
- **Home Assistant**: Smart home automation platform
- **CV/Portfolio**: Personal website and portfolio
- **Jellyfin**: Media server for movies, TV shows, and music
- **Nextcloud**: Self-hosted cloud storage and productivity suite
- **Restic**: Automated backup solution

## 📋 Todo List

### **Infrastructure List**
- [ ] Complete Flux bootstrap automation in Ansible
- [ ] Test GitOps reconciliation from Git repository
- [ ] Set up automated backups with Restic
- [ ] Configure monitoring with Prometheus/Grafana
- [ ] Implement cert-manager for automated TLS

### **Applications**
- [ ] **Home Assistant**: Deploy smart home automation
  - [ ] Configure device integrations
  - [ ] Set up automation rules
  - [ ] Implement secure external access
- [ ] **CV/Portfolio Website**: Deploy personal website
  - [ ] Set up custom domain (kragh.dev)
  - [ ] Configure static site hosting
  - [ ] Implement CI/CD for updates
- [ ] **Jellyfin Media Server**: Deploy media streaming
  - [ ] Configure media storage
  - [ ] Set up hardware transcoding
  - [ ] Configure user accounts and libraries
- [ ] **Nextcloud**: Deploy cloud storage
  - [ ] Configure persistent storage
  - [ ] Set up user accounts
  - [ ] Configure external access
- [ ] **Vaultwarden**: Deploy password manager
  - [ ] Configure secure access
  - [ ] Set up backup strategy
  - [ ] Migrate from Bitwarden cloud

### **Operations**
- [ ] Document deployment procedures
- [ ] Create disaster recovery plan
- [ ] Set up log aggregation
- [ ] Implement security scanning
- [ ] Create maintenance schedules

### **Networking & Security**
- [ ] Configure Tailscale exit nodes
- [ ] Set up VPN access for external devices
- [ ] Implement network segmentation
- [ ] Configure firewall rules
- [ ] Set up intrusion detection

## 🔄 GitOps Workflow

```mermaid
graph TD
    A[Developer pushes to Git] --> B[Flux detects changes]
    B --> C[Flux reconciles cluster state]
    C --> D[External Secrets fetches secrets]
    D --> E[Applications deployed]
    E --> F[Traefik routes traffic]
    F --> G[cert-manager issues certificates]
```

## 🚨 Disaster Recovery

### **Backup Strategy**
- **Configuration**: Everything in Git (GitOps)
- **Secrets**: Stored in Bitwarden (external)
- **Data**: Automated Restic backups to multiple locations
- **Recovery**: Full cluster recreation from Ansible + Git

### **Recovery Steps**
1. Provision new infrastructure with Ansible
2. Restore from Git repository (automatic via Flux)
3. Secrets automatically restored from Bitwarden
4. Application data restored from Restic backups

## 📖 Documentation

- [Architecture Overview](docs/ARCHITECTURE.md)
- [Backup Strategy](docs/BACKUP-STRATEGY.md)
- [Operations Guide](docs/OPERATIONS.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and test locally
4. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flux CD](https://fluxcd.io/) for GitOps automation
- [External Secrets Operator](https://external-secrets.io/) for secret management
- [Tailscale](https://tailscale.com/) for secure networking
- [k3s](https://k3s.io/) for lightweight Kubernetes
- [SOPS](https://github.com/mozilla/sops) for secret encryption
