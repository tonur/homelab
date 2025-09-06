# Ansible Homelab

## Collections

Install required collections before running:

```bash
ansible-galaxy collection install -r collections/requirements.yml
```

## WireGuard peer key helper

Generate a peer keypair and instructions:

```bash
./scripts/generate-wireguard-peer.sh --endpoint mygw.example.com:51820 --ip 10.172.90.2
```

Store the private key encrypted (SOPS) as `edge_gateway_wg_private_key` and set the peer public key / endpoint vars.

## Run

```bash
./ansible/run.sh --tags edge
```
