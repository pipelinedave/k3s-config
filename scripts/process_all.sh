#!/bin/bash

# Script to process all namespaces
# This script will:
# 1. Find all namespaces in the repository
# 2. Process each namespace to clean resources and seal sensitive data

# Determine repository root based on script location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Get list of namespaces from apps directory
NAMESPACES=$(find "${REPO_ROOT}/apps" -name "*.yaml" -exec basename {} \; | sed 's/\.yaml$//')

# Exclude system namespaces
EXCLUDE_LIST="kube-system kube-public kube-node-lease cert-manager"

# Display plan
echo "This script will process the following namespaces:"
for ns in $NAMESPACES; do
  if [[ ! " $EXCLUDE_LIST " =~ " $ns " ]]; then
    echo "- $ns"
  fi
done

# Ask for confirmation
echo
read -p "Do you want to process all these namespaces? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 1
fi

# Process each namespace
for ns in $NAMESPACES; do
  if [[ ! " $EXCLUDE_LIST " =~ " $ns " ]]; then
    echo
    echo "==============================================="
    echo "Processing namespace: $ns"
    echo "==============================================="
    ./process_namespace.sh "$ns"
    
    # Ask if user wants to continue after each namespace
    echo
    read -p "Continue to the next namespace? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Processing stopped. Namespaces processed so far have been saved."
      exit 0
    fi
  fi
done

echo
echo "All namespaces processed successfully!"
echo
echo "Next steps:"
echo "1. Review the changes with 'git diff'"
echo "2. If everything looks good, commit and push the changes"
