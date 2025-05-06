#!/bin/bash

# Master script to safely clean and seal namespace resources
# This script will:
# 1. Clean up Kubernetes resources
# 2. Seal sensitive data
# Usage: ./process_namespace.sh <namespace>

if [ -z "$1" ]; then
  echo "Usage: ./process_namespace.sh <namespace>"
  exit 1
fi

NAMESPACE=$1
REPO_DIR="/home/dave/src/k3s-config"
KUSTOMIZE_DIR="${REPO_DIR}/kustomize/${NAMESPACE}"
CLEAN_DIR="/tmp/k3s-clean-${NAMESPACE}"
SEAL_DIR="/tmp/k3s-seal-${NAMESPACE}"
BACKUP_DIR="/tmp/k3s-backup-${NAMESPACE}-$(date +%Y%m%d%H%M%S)"

# Check if the namespace exists
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
  echo "Error: Namespace $NAMESPACE does not exist"
  exit 1
fi

# Check if the namespace directory exists
if [ ! -d "$KUSTOMIZE_DIR" ]; then
  echo "Error: Namespace directory $KUSTOMIZE_DIR does not exist"
  exit 1
fi

# Special handling for certain namespaces
case "$NAMESPACE" in
  "choremane-prod"|"choremane-staging"|"flux-system"|"kube-system"|"kube-public"|"kube-node-lease"|"cert-manager")
    echo "Warning: $NAMESPACE is a special namespace that might be managed differently."
    read -p "Are you sure you want to process this namespace? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Operation cancelled."
      exit 1
    fi
    ;;
esac

# Create backup directory
echo "Creating backup in $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
cp -r "$KUSTOMIZE_DIR"/* "$BACKUP_DIR"

# Step 1: Clean resources
echo
echo "===================================="
echo "Step 1: Cleaning up resources"
echo "===================================="
./clean_export.sh "$NAMESPACE"

# Step 2: Seal sensitive data
echo
echo "===================================="
echo "Step 2: Sealing sensitive data"
echo "===================================="
./seal_secrets.sh "$NAMESPACE"

# Step 3: Merge and apply changes
echo
echo "===================================="
echo "Step 3: Applying changes"
echo "===================================="

# Merge clean resources and sealed secrets
MERGED_DIR="/tmp/k3s-merged-${NAMESPACE}"
mkdir -p "$MERGED_DIR"

# Copy resource files from clean directory
echo "Merging clean resources..."
for file in "$CLEAN_DIR"/*.yaml; do
  if [ -f "$file" ]; then
    cp "$file" "$MERGED_DIR/"
    echo "Copied $(basename "$file")"
  fi
done

# Copy sealed secrets
echo "Merging sealed secrets..."
for file in "$SEAL_DIR"/*-sealed.yaml; do
  if [ -f "$file" ]; then
    cp "$file" "$MERGED_DIR/"
    echo "Copied $(basename "$file")"
  fi
done

# Use the kustomization file from seal_secrets.sh which should have both
# resources and sealed secrets
if [ -f "$SEAL_DIR/kustomization.yaml" ]; then
  cp "$SEAL_DIR/kustomization.yaml" "$MERGED_DIR/"
  echo "Using sealed kustomization.yaml"
else
  # If no sealed kustomization, use the clean one
  cp "$CLEAN_DIR/kustomization.yaml" "$MERGED_DIR/"
  echo "Using clean kustomization.yaml"
fi

# Review and apply changes
echo
echo "Changes ready to apply from $MERGED_DIR"
echo "Files to be updated:"
ls -la "$MERGED_DIR"

# Ask for confirmation
read -p "Apply these changes to $KUSTOMIZE_DIR? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Operation cancelled. No changes were made."
  echo "You can find the prepared files in $MERGED_DIR"
  exit 1
fi

# Apply changes
echo "Applying changes..."
cp -f "$MERGED_DIR"/* "$KUSTOMIZE_DIR/"

echo
echo "===================================="
echo "Processing of $NAMESPACE completed successfully!"
echo "===================================="
echo
echo "A backup of the original files is available at: $BACKUP_DIR"
echo
echo "The namespace is now ready to be committed to the repository."
