#!/bin/bash

# Master Sync Script - Comprehensive tool to make k3s-config the source of truth
# This script integrates all the individual tools to ensure your repository
# matches your cluster state with proper handling of sensitive data
# Usage: ./master_sync.sh [--all] [namespace1 namespace2 ...]

set -e

REPO_DIR="/home/dave/src/k3s-config"
APPS_DIR="${REPO_DIR}/apps"
KUSTOMIZE_DIR="${REPO_DIR}/kustomize"
TEMP_DIR="/tmp/k3s-sync-$(date +%Y%m%d%H%M%S)"
LOG_FILE="${TEMP_DIR}/sync.log"

# Create temp directories
mkdir -p "${TEMP_DIR}"
mkdir -p "${TEMP_DIR}/backup"

# Setup logging
exec > >(tee -a "${LOG_FILE}") 2>&1

# Print header
echo "=========================================================="
echo "K3s Configuration Repository Master Sync Tool"
echo "=========================================================="
echo "Started at: $(date)"
echo "Log file: ${LOG_FILE}"
echo

# Check required tools
echo "Checking prerequisites..."
for tool in kubectl yq jq kubeseal; do
  if ! command -v $tool &> /dev/null; then
    echo "ERROR: Required tool '$tool' is not installed"
    exit 1
  fi
done
echo "All required tools are available"
echo

# Determine which namespaces to process
process_all=false
namespaces_to_process=()

if [ "$1" == "--all" ]; then
  process_all=true
  # Get all non-system namespaces from the cluster
  readarray -t namespaces_to_process < <(kubectl get namespaces -o json | \
    jq -r '.items[] | select(.metadata.name | test("^(kube-|cert-manager|default|flux-system)$") | not) | .metadata.name' | sort)
  shift
elif [ $# -gt 0 ]; then
  # Process specified namespaces
  namespaces_to_process=("$@")
else
  # No arguments - interactive mode
  echo "No namespaces specified. Available options:"
  echo "  1. Process all non-system namespaces"
  echo "  2. Process namespaces that need updating (recommended)"
  echo "  3. Specify namespaces manually"
  echo "  4. Exit"
  read -p "Select an option (1-4): " option
  
  case $option in
    1)
      process_all=true
      readarray -t namespaces_to_process < <(kubectl get namespaces -o json | \
        jq -r '.items[] | select(.metadata.name | test("^(kube-|cert-manager|default|flux-system)$") | not) | .metadata.name' | sort)
      ;;
    2)
      echo "Checking for namespaces that need updating..."
      # Run verify script and capture output
      ./verify_cluster.sh > "${TEMP_DIR}/verify_output.txt"
      # Parse the output to find namespaces with issues
      readarray -t namespaces_to_process < <(grep -E "WARNING|MISSING" "${TEMP_DIR}/verify_output.txt" | \
        grep -oE "namespace [a-zA-Z0-9-]+" | awk '{print $2}' | sort | uniq)
      if [ ${#namespaces_to_process[@]} -eq 0 ]; then
        echo "No namespaces need updating. Exiting."
        exit 0
      fi
      echo "The following namespaces need updating:"
      printf "  - %s\n" "${namespaces_to_process[@]}"
      ;;
    3)
      echo "Available namespaces in the cluster:"
      kubectl get namespaces -o name | cut -d/ -f2 | grep -v "kube-\|cert-manager\|default\|flux-system" | sort | \
        awk '{print "  - " $1}'
      echo
      read -p "Enter namespaces (space-separated): " -a namespaces_to_process
      ;;
    4)
      echo "Exiting."
      exit 0
      ;;
    *)
      echo "Invalid option. Exiting."
      exit 1
      ;;
  esac
fi

# Check if any namespaces were selected
if [ ${#namespaces_to_process[@]} -eq 0 ]; then
  echo "No namespaces to process. Exiting."
  exit 0
fi

# Confirm the namespaces to process
echo
echo "The following namespaces will be processed:"
printf "  - %s\n" "${namespaces_to_process[@]}"
echo
read -p "Continue? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 0
fi

# For each namespace
for namespace in "${namespaces_to_process[@]}"; do
  echo
  echo "=========================================================="
  echo "Processing namespace: $namespace"
  echo "=========================================================="
  
  # Check if namespace exists in cluster
  if ! kubectl get namespace "$namespace" &>/dev/null; then
    echo "WARNING: Namespace $namespace does not exist in the cluster."
    read -p "Continue anyway? (y/n): " continue_missing
    if [[ ! $continue_missing =~ ^[Yy]$ ]]; then
      echo "Skipping $namespace"
      continue
    fi
  fi
  
  # Check if namespace exists in repository
  namespace_app_file="${APPS_DIR}/${namespace}.yaml"
  namespace_dir="${KUSTOMIZE_DIR}/${namespace}"
  
  # Backup existing files if any
  if [ -f "$namespace_app_file" ] || [ -d "$namespace_dir" ]; then
    echo "Creating backup of existing files for $namespace..."
    mkdir -p "${TEMP_DIR}/backup/${namespace}"
    
    if [ -f "$namespace_app_file" ]; then
      cp "$namespace_app_file" "${TEMP_DIR}/backup/${namespace}/"
    fi
    
    if [ -d "$namespace_dir" ]; then
      cp -r "$namespace_dir" "${TEMP_DIR}/backup/${namespace}/"
    fi
    
    echo "Backup created at: ${TEMP_DIR}/backup/${namespace}"
  fi
  
  # Step 1: Export/update namespace if needed
  if [ ! -f "$namespace_app_file" ] || [ ! -d "$namespace_dir" ]; then
    echo "Step 1: Creating initial export for $namespace..."
    ./export_namespace.sh "$namespace"
  else
    echo "Step 1: Namespace files already exist, moving to cleaning stage"
  fi
  
  # Step 2: Clean resources
  echo
  echo "Step 2: Cleaning resources for $namespace..."
  ./clean_export.sh "$namespace"
  
  # Step 3: Seal sensitive data
  echo
  echo "Step 3: Sealing sensitive data for $namespace..."
  ./seal_secrets.sh "$namespace"
  
  # Step 4: Apply the changes
  echo
  echo "Step 4: Applying changes to $namespace..."
  
  # Process namespace script handles the merge and application
  ./process_namespace.sh "$namespace"
  
  echo "Namespace $namespace processing complete"
  echo
done

# Final verification
echo
echo "=========================================================="
echo "Final Verification"
echo "=========================================================="
./verify_cluster.sh

echo
echo "=========================================================="
echo "K3s Configuration Repository Sync Complete"
echo "=========================================================="
echo "Completed at: $(date)"
echo
echo "Next steps:"
echo "  1. Review the changes with: git diff"
echo "  2. If everything looks good, commit and push:"
echo "     git add ."
echo "     git commit -m 'Update repository to match cluster state'"
echo "     git push"
echo
echo "Logs and backups are available at: $TEMP_DIR"
