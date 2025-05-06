#!/bin/bash

# Script to selectively process namespaces, excluding critical ones
# Usage: ./safe_process.sh [namespace1 namespace2 ...]

# Define critical namespaces to exclude by default
CRITICAL_NAMESPACES=(
  "docspell"
  "choremane-prod"
  "choremane-staging"
  "memodawg"
)

# Get all non-system namespaces from apps directory
ALL_NAMESPACES=$(find /home/dave/src/k3s-config/apps -name "*.yaml" -not -path "*/\.*" | xargs -n1 basename | sed 's/\.yaml$//' | sort)

# Function to check if a namespace is in the critical list
is_critical() {
  local ns=$1
  for critical in "${CRITICAL_NAMESPACES[@]}"; do
    if [ "$ns" == "$critical" ]; then
      return 0
    fi
  done
  return 1
}

# Process arguments
if [ $# -gt 0 ]; then
  # Process specific namespaces
  NAMESPACES_TO_PROCESS=()
  
  for ns in "$@"; do
    if is_critical "$ns"; then
      echo "⚠️ Warning: $ns is marked as critical."
      read -p "Are you sure you want to process it? This could cause service disruption. (y/n): " confirm
      if [[ $confirm =~ ^[Yy]$ ]]; then
        NAMESPACES_TO_PROCESS+=("$ns")
      else
        echo "Skipping $ns."
      fi
    else
      NAMESPACES_TO_PROCESS+=("$ns")
    fi
  done
else
  # No arguments - process all non-critical namespaces
  NAMESPACES_TO_PROCESS=()
  
  for ns in $ALL_NAMESPACES; do
    if ! is_critical "$ns"; then
      NAMESPACES_TO_PROCESS+=("$ns")
    fi
  done
  
  echo "Will process all non-critical namespaces."
fi

# Check if we have any namespaces to process
if [ ${#NAMESPACES_TO_PROCESS[@]} -eq 0 ]; then
  echo "No namespaces to process. Exiting."
  exit 0
fi

# Confirm with user
echo
echo "The following namespaces will be processed:"
printf "  - %s\n" "${NAMESPACES_TO_PROCESS[@]}"
echo
echo "Critical namespaces that will NOT be processed:"
printf "  - %s\n" "${CRITICAL_NAMESPACES[@]}"
echo
read -p "Continue? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 0
fi

# Process each namespace
for namespace in "${NAMESPACES_TO_PROCESS[@]}"; do
  echo
  echo "=========================================================="
  echo "Processing namespace: $namespace"
  echo "=========================================================="
  
  # Call process_namespace.sh
  ./process_namespace.sh "$namespace"
  
  echo "Namespace $namespace processing complete"
  echo
done

echo "All selected namespaces have been processed."
echo 
echo "To safely commit these changes, use:"
echo "  ./safe_commit.sh"
