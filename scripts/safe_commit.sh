#!/bin/bash

# Script to safely commit and apply repository changes
# This script:
# 1. Suspends Flux reconciliation for critical namespaces
# 2. Commits and pushes changes
# 3. Selectively reconciles non-critical namespaces
# 4. Allows manual verification before restoring critical namespaces

# Critical namespaces to protect
CRITICAL_NAMESPACES=(
  "docspell"
  "choremane-prod"
  "choremane-staging"
  "memodawg"
)

# Function to suspend a namespace kustomization
suspend_namespace() {
  local namespace=$1
  echo "Suspending Flux reconciliation for $namespace..."
  flux suspend kustomization $namespace
  if [ $? -eq 0 ]; then
    echo "✅ Successfully suspended $namespace"
  else
    echo "❌ Failed to suspend $namespace"
    exit 1
  fi
}

# Function to resume a namespace kustomization
resume_namespace() {
  local namespace=$1
  echo "Resuming Flux reconciliation for $namespace..."
  flux resume kustomization $namespace
  if [ $? -eq 0 ]; then
    echo "✅ Successfully resumed $namespace"
  else
    echo "❌ Failed to resume $namespace"
    exit 1
  fi
}

# Step 1: Suspend critical namespaces
echo "=== Step 1: Suspending critical namespaces ==="
for ns in "${CRITICAL_NAMESPACES[@]}"; do
  suspend_namespace $ns
done

# Display status of suspensions
echo
echo "Current suspension status:"
flux get kustomization --all-namespaces

# Step 2: Commit and push changes
echo
echo "=== Step 2: Commit and push changes ==="
echo "This will commit all changes but Flux won't reconcile the critical namespaces."
read -p "Proceed with git commit and push? (y/n): " proceed

if [[ ! $proceed =~ ^[Yy]$ ]]; then
  echo "Operation cancelled. You can manually resume namespaces with:"
  for ns in "${CRITICAL_NAMESPACES[@]}"; do
    echo "  flux resume kustomization $ns"
  done
  exit 0
fi

# Perform git operations
git add .
read -p "Enter commit message: " commit_message
git commit -m "$commit_message"
git push

# Step 3: Allow user to verify non-critical namespaces
echo
echo "=== Step 3: Allow time for Flux to reconcile non-critical namespaces ==="
echo "Flux is now applying changes to non-critical namespaces."
echo "You should monitor the cluster for any issues."
read -p "Press Enter when you're ready to proceed..." proceed

# Step 4: Selectively resume critical namespaces
echo
echo "=== Step 4: Selectively resume critical namespaces ==="
echo "You will now be prompted to resume each critical namespace individually."
echo "This allows you to verify each service before moving to the next."

for ns in "${CRITICAL_NAMESPACES[@]}"; do
  echo
  echo "Namespace: $ns"
  read -p "Resume Flux reconciliation for $ns? (y/n): " resume
  
  if [[ $resume =~ ^[Yy]$ ]]; then
    resume_namespace $ns
    echo "Waiting for reconciliation to complete..."
    sleep 10
    echo "Check the status of $ns and verify it's working correctly."
    read -p "Press Enter when ready for the next namespace..." proceed
  else
    echo "Skipping $ns. You can manually resume it later with:"
    echo "  flux resume kustomization $ns"
  fi
done

echo
echo "=== Process complete ==="
echo "All selected namespaces have been resumed."
echo "For any skipped namespaces, you can manually resume them with:"
for ns in "${CRITICAL_NAMESPACES[@]}"; do
  echo "  flux resume kustomization $ns"
done
