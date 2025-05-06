#!/bin/bash

# Script to identify potentially sensitive ConfigMaps and Secrets and seal them
# Usage: ./seal_sensitive_data.sh <namespace>

if [ -z "$1" ]; then
  echo "Usage: ./seal_sensitive_data.sh <namespace>"
  exit 1
fi

NAMESPACE=$1
REPO_DIR="/home/dave/src/k3s-config"
KUSTOMIZE_DIR="${REPO_DIR}/kustomize/${NAMESPACE}"

# Check if namespace directory exists
if [ ! -d "$KUSTOMIZE_DIR" ]; then
  echo "Namespace directory not found: $KUSTOMIZE_DIR"
  exit 1
fi

# Check if kubeseal is installed
if ! command -v kubeseal &> /dev/null; then
  echo "kubeseal command not found. Please install it first."
  exit 1
fi

# Get the configmaps that contain potentially sensitive data
get_sensitive_configmaps() {
  # Export configmaps to a temporary file
  local tmpfile=$(mktemp)
  kubectl get configmaps -n ${NAMESPACE} -o yaml > "$tmpfile"
  
  # Look for potentially sensitive patterns
  local patterns=("password" "secret" "token" "auth" "key" "cert" "cred" "private")
  local sensitive_configmaps=()
  
  # Get list of configmap names
  local configmap_names=$(kubectl get configmaps -n ${NAMESPACE} -o name | cut -d/ -f2)
  
  for cm in $configmap_names; do
    # Skip default token configmaps
    if [[ "$cm" == *"default-token"* ]]; then
      continue
    fi
    
    # Extract just this configmap to check
    local cm_data=$(kubectl get configmap "$cm" -n ${NAMESPACE} -o yaml)
    
    # Check if any sensitive pattern exists
    for pattern in "${patterns[@]}"; do
      if echo "$cm_data" | grep -i "$pattern" &> /dev/null; then
        sensitive_configmaps+=("$cm")
        break
      fi
    done
  done
  
  # Output the sensitive configmap names
  echo "${sensitive_configmaps[@]}"
  
  # Clean up
  rm "$tmpfile"
}

# Seal a ConfigMap from the cluster using kubeseal
seal_configmap() {
  local name=$1
  local output_file="${KUSTOMIZE_DIR}/${name}-sealed.yaml"
  
  echo "Sealing ConfigMap ${name}..."
  
  # Get the configmap and pipe directly to kubeseal
  kubectl get configmap ${name} -n ${NAMESPACE} -o yaml | \
    kubeseal --format yaml --controller-namespace kube-system > "$output_file"
  
  if [ $? -eq 0 ]; then
    echo "Created sealed file: $output_file"
    
    # Update kustomization.yaml to use the sealed file
    if [ -f "${KUSTOMIZE_DIR}/kustomization.yaml" ]; then
      # Check if configmap.yaml is referenced
      if grep -q "configmap.yaml" "${KUSTOMIZE_DIR}/kustomization.yaml"; then
        # If we're sealing the main configmap.yaml, replace it
        if [ "$name" == "configmap" ]; then
          sed -i "s|configmap.yaml|${name}-sealed.yaml|g" "${KUSTOMIZE_DIR}/kustomization.yaml"
        else
          # Otherwise, add this as a new resource
          sed -i "/resources:/a \ \ - ${name}-sealed.yaml" "${KUSTOMIZE_DIR}/kustomization.yaml"
        fi
        echo "Updated kustomization.yaml to use ${name}-sealed.yaml"
      else
        # If configmap isn't already in kustomization, add the sealed one
        sed -i "/resources:/a \ \ - ${name}-sealed.yaml" "${KUSTOMIZE_DIR}/kustomization.yaml"
        echo "Added ${name}-sealed.yaml to kustomization.yaml"
      fi
    else
      echo "Warning: kustomization.yaml not found in $KUSTOMIZE_DIR"
    fi
  else
    echo "Error sealing ConfigMap ${name}"
  fi
}

# Seal all secrets in the namespace
seal_all_secrets() {
  local secret_names=$(kubectl get secrets -n ${NAMESPACE} -o name | cut -d/ -f2 | grep -v "default-token")
  
  if [ -z "$secret_names" ]; then
    echo "No secrets found in namespace ${NAMESPACE}"
    return
  fi
  
  for secret in $secret_names; do
    local output_file="${KUSTOMIZE_DIR}/${secret}-sealed.yaml"
    
    echo "Sealing Secret ${secret}..."
    
    # Get the secret and pipe directly to kubeseal
    kubectl get secret ${secret} -n ${NAMESPACE} -o yaml | \
      kubeseal --format yaml --controller-namespace kube-system > "$output_file"
    
    if [ $? -eq 0 ]; then
      echo "Created sealed file: $output_file"
      
      # Update kustomization.yaml to use the sealed file
      if [ -f "${KUSTOMIZE_DIR}/kustomization.yaml" ]; then
        # Add this as a new resource if not already there
        if ! grep -q "${secret}-sealed.yaml" "${KUSTOMIZE_DIR}/kustomization.yaml"; then
          sed -i "/resources:/a \ \ - ${secret}-sealed.yaml" "${KUSTOMIZE_DIR}/kustomization.yaml"
          echo "Added ${secret}-sealed.yaml to kustomization.yaml"
        fi
      else
        echo "Warning: kustomization.yaml not found in $KUSTOMIZE_DIR"
      fi
    else
      echo "Error sealing Secret ${secret}"
    fi
  done
}

# Main execution

# First, seal any sensitive ConfigMaps
echo "Checking for sensitive ConfigMaps in namespace ${NAMESPACE}..."
sensitive_cms=$(get_sensitive_configmaps)

if [ -n "$sensitive_cms" ]; then
  echo "Found sensitive ConfigMaps: $sensitive_cms"
  for cm in $sensitive_cms; do
    seal_configmap "$cm"
  done
else
  echo "No sensitive ConfigMaps found in namespace ${NAMESPACE}"
fi

# Then, seal all Secrets
echo "Sealing all Secrets in namespace ${NAMESPACE}..."
seal_all_secrets

echo "Sealing completed for namespace $NAMESPACE"
