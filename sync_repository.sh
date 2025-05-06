#!/bin/bash

# Master script for ensuring k3s-config repository is the source of truth
# This script:
# 1. Verifies current repository state against the cluster
# 2. Exports missing namespaces
# 3. Process existing namespaces for proper cleanup and secret sealing
# 4. Verifies the final state

set -e

REPO_DIR="/home/dave/src/k3s-config"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
LOG_FILE="/tmp/k3s-sync-${TIMESTAMP}.log"

echo "======================================================="
echo "K3s Repository Synchronization - Starting"
echo "======================================================="
echo "Timestamp: $(date)"
echo "Log file: ${LOG_FILE}"
echo

# Redirect all output to both console and log file
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "Step 1: Initial verification of repository state"
echo "------------------------------------------------"
./verify_cluster.sh

# Get lists of namespaces
kubectl get namespaces -o json | jq -r '.items[] | select(.metadata.name | test("^(kube-|cert-manager|default|flux-system)$") | not) | .metadata.name' | sort > /tmp/cluster_namespaces.txt
find "${REPO_DIR}/apps" -name "*.yaml" -exec basename {} \; | sed 's/\.yaml$//' | sort > /tmp/repo_namespaces.txt
comm -23 /tmp/cluster_namespaces.txt /tmp/repo_namespaces.txt > /tmp/missing_namespaces.txt

# Check for missing namespaces
if [ -s /tmp/missing_namespaces.txt ]; then
  echo
  echo "Step 2: Exporting missing namespaces"
  echo "------------------------------------"
  
  cat /tmp/missing_namespaces.txt | while read namespace; do
    echo "Exporting namespace: ${namespace}"
    ./export_namespace.sh "${namespace}"
    echo "Namespace ${namespace} exported successfully"
    echo
  done
else
  echo
  echo "Step 2: No missing namespaces to export"
  echo "-------------------------------------"
fi

echo
echo "Step 3: Processing existing namespaces"
echo "-------------------------------------"

# Get the list of namespaces to process
find "${REPO_DIR}/apps" -name "*.yaml" -exec basename {} \; | sed 's/\.yaml$//' | sort > /tmp/repo_namespaces.txt

# Exclude system namespaces and other special cases
EXCLUDE_LIST="kube-system kube-public kube-node-lease cert-manager flux-system"

cat /tmp/repo_namespaces.txt | while read namespace; do
  # Skip excluded namespaces
  if [[ "$EXCLUDE_LIST" =~ "$namespace" ]]; then
    echo "Skipping system namespace: ${namespace}"
    continue
  fi
  
  # Check if the namespace exists in the cluster
  if ! kubectl get namespace "${namespace}" >/dev/null 2>&1; then
    echo "WARNING: Namespace ${namespace} is in the repository but not in the cluster"
    continue
  fi
  
  echo "Processing namespace: ${namespace}"
  ./process_namespace.sh "${namespace}"
  echo "Namespace ${namespace} processed successfully"
  echo
done

echo
echo "Step 4: Final verification"
echo "-------------------------"
./verify_cluster.sh

echo
echo "======================================================="
echo "K3s Repository Synchronization - Complete"
echo "======================================================="
echo "Timestamp: $(date)"
echo "Log file: ${LOG_FILE}"
echo
echo "Next steps:"
echo "1. Review changes with 'git diff'"
echo "2. Commit and push changes to the repository"
echo "   git add ."
echo "   git commit -m 'Update repository to match cluster state'"
echo "   git push"
