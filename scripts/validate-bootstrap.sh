#!/bin/bash
set -euo pipefail

# Validate bootstrap.yaml structure
echo "🔍 Validating bootstrap.yaml structure..."

# Check if bootstrap.yaml exists
if [[ ! -f "bootstrap.yaml" ]]; then
    echo "❌ bootstrap.yaml not found in root directory"
    exit 1
fi

# Validate YAML syntax
if ! kubectl --dry-run=client apply -f bootstrap.yaml >/dev/null 2>&1; then
    echo "❌ bootstrap.yaml has invalid YAML syntax"
    exit 1
fi

# Check for required resources
resources=$(kubectl --dry-run=client apply -f bootstrap.yaml 2>/dev/null | wc -l)
echo "✅ bootstrap.yaml contains $resources resources"

# Check for required resource types
if ! grep -q "kind: Namespace" bootstrap.yaml; then
    echo "⚠️  Warning: No Namespace resource found in bootstrap.yaml"
fi

if ! grep -q "kind: GitRepository" bootstrap.yaml; then
    echo "❌ No GitRepository resource found in bootstrap.yaml"
    exit 1
fi

if ! grep -q "kind: Kustomization" bootstrap.yaml; then
    echo "❌ No Kustomization resource found in bootstrap.yaml"
    exit 1
fi

echo "✅ Bootstrap validation passed!"
echo ""
echo "📋 Bootstrap.yaml purpose:"
echo "  1. Creates flux-system namespace"
echo "  2. Defines GitRepository pointing to this repo"
echo "  3. Creates root Kustomization for ./clusters/homelab"
echo ""
echo "🚀 Usage:"
echo "  - Applied by Ansible during gitops-bootstrap role"
echo "  - Single entry point for Flux to manage entire cluster"
echo "  - After bootstrap, everything is managed via GitOps"
