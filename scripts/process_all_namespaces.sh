#!/bin/bash

# Master script to clean and seal all namespaces
# This will:
# 1. Clean up exported resources
# 2. Seal sensitive data
# 3. Verify the repository matches the cluster

# Get a list of all namespaces from the apps directory
NAMESPACES=$(ls /home/dave/src/k3s-config/apps/ | sed 's/\.yaml$//')

echo "Processing the following namespaces:"
echo "$NAMESPACES"
echo ""

# Exclude list - namespaces we won't process because they're managed differently
EXCLUDES=("flux-system" "test" "kube-system" "kube-public" "kube-node-lease" "cert-manager")

# Ask for confirmation
read -p "This will clean and seal all the namespaces. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 1
fi

echo "Starting processing..."
echo ""

# Process each namespace
for ns in $NAMESPACES; do
    # Skip excluded namespaces
    if [[ " ${EXCLUDES[@]} " =~ " ${ns} " ]]; then
        echo "Skipping $ns (in exclude list)"
        continue
    fi
    
    echo "========================================"
    echo "Processing namespace: $ns"
    echo "========================================"
    
    # Clean up the resources
    echo "Step 1: Cleaning resources for $ns"
    ./clean_k8s_export.sh "$ns"
    
    # Only continue if clean directory was created
    if [ -d "/home/dave/src/k3s-config/kustomize/${ns}-clean" ]; then
        # Replace the old files with clean versions
        echo "Replacing old resources with clean versions..."
        # Preserve the original kustomization.yaml
        cp "/home/dave/src/k3s-config/kustomize/${ns}/kustomization.yaml" "/home/dave/src/k3s-config/kustomize/${ns}/kustomization.yaml.orig"
        # Copy clean files
        cp -f "/home/dave/src/k3s-config/kustomize/${ns}-clean"/* "/home/dave/src/k3s-config/kustomize/${ns}/"
        # Restore original kustomization
        mv "/home/dave/src/k3s-config/kustomize/${ns}/kustomization.yaml.orig" "/home/dave/src/k3s-config/kustomize/${ns}/kustomization.yaml"
        # Remove clean directory
        rm -rf "/home/dave/src/k3s-config/kustomize/${ns}-clean"
        
        echo "Step 2: Sealing sensitive data for $ns"
        ./seal_sensitive_data.sh "$ns"
    else
        echo "Clean directory was not created for $ns, skipping further processing"
    fi
    
    echo "Processing of $ns completed"
    echo ""
done

echo "All namespaces processed. Running verification..."
./verify_cluster.sh

echo ""
echo "Processing complete!"
echo ""
echo "Next steps:"
echo "1. Review the changes with 'git diff'"
echo "2. If everything looks good, commit the changes"
