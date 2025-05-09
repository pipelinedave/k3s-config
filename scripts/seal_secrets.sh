#!/bin/bash

# Improved script to seal sensitive ConfigMaps and Secrets
# Usage: ./seal_secrets.sh <namespace>

if [ -z "$1" ]; then
  echo "Usage: ./seal_secrets.sh <namespace>"
  exit 1
fi

NAMESPACE=$1
REPO_DIR="/home/dave/src/k3s-config"
KUSTOMIZE_DIR="${REPO_DIR}/kustomize/${NAMESPACE}"
TEMP_DIR="/tmp/k3s-seal-${NAMESPACE}"

# Create a temporary directory
mkdir -p "$TEMP_DIR"
echo "Working in temporary directory: $TEMP_DIR"

# Check if kubeseal is installed
if ! command -v kubeseal &> /dev/null; then
  echo "Error: kubeseal command not found. Please install it first."
  exit 1
fi

# Function to check if a Secret or ConfigMap contains sensitive data
contains_sensitive_data() {
  local resource_type=$1
  local name=$2
  
  # Get the resource as YAML
  local data=$(kubectl get $resource_type $name -n $NAMESPACE -o yaml 2>/dev/null)
  
  # Patterns that indicate sensitive data
  local patterns=("password" "secret" "token" "auth" "key" "cert" "cred" "private")
  
  # Check for each pattern
  for pattern in "${patterns[@]}"; do
    if echo "$data" | grep -i "$pattern" &> /dev/null; then
      return 0  # Contains sensitive data
    fi
  done
  
  return 1  # No sensitive data found
}

# Function to seal a Secret or ConfigMap
seal_resource() {
  local resource_type=$1
  local name=$2
  local output_file="${TEMP_DIR}/${name}-sealed.yaml"
  
  echo "Sealing $resource_type/${name}..."
  
  # Use kubeseal to create a SealedSecret
  kubectl get $resource_type $name -n $NAMESPACE -o yaml | \
    kubeseal --format yaml --controller-namespace kube-system > "$output_file"
  
  if [ $? -eq 0 ]; then
    echo "Created sealed file: $output_file"
    return 0
  else
    echo "Error sealing $resource_type/${name}"
    return 1
  fi
}

# Function to update kustomization.yaml with sealed resources
update_kustomization() {
  local kustomization="${TEMP_DIR}/kustomization.yaml"
  
  # Copy the original kustomization file if it exists
  if [ -f "${KUSTOMIZE_DIR}/kustomization.yaml" ]; then
    cp "${KUSTOMIZE_DIR}/kustomization.yaml" "$kustomization"
  else
    # Create a basic kustomization file if none exists
    cat > "$kustomization" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
EOF
  fi
  
  # Find all sealed files
  for sealed in "${TEMP_DIR}"/*-sealed.yaml; do
    if [ -f "$sealed" ]; then
      # Get the basename
      local sealed_name=$(basename "$sealed")
      
      # Check if it's already in the kustomization file
      if ! grep -q "$sealed_name" "$kustomization"; then
        # Add it to the resources section
        sed -i "/resources:/a\- $sealed_name" "$kustomization"
        echo "Added $sealed_name to kustomization.yaml"
      fi
    fi
  done
  
  # Remove references to unsealed ConfigMaps and Secrets
  for resource_type in configmap secret; do
    if grep -q "$resource_type.yaml" "$kustomization"; then
      sed -i "s/- $resource_type.yaml/# - $resource_type.yaml # Replaced with sealed version/g" "$kustomization"
      echo "Commented out reference to $resource_type.yaml in kustomization.yaml"
    fi
  done
}

# Process ConfigMaps
echo
echo "Processing ConfigMaps..."
CM_LIST=$(kubectl get configmaps -n $NAMESPACE -o name | cut -d/ -f2 | grep -v "default-token")
for cm in $CM_LIST; do
  if contains_sensitive_data configmap "$cm"; then
    seal_resource configmap "$cm"
  else
    echo "ConfigMap/$cm does not contain sensitive data, skipping"
  fi
done

# Process Secrets
echo
echo "Processing Secrets..."
SECRET_LIST=$(kubectl get secrets -n $NAMESPACE -o name | cut -d/ -f2 | grep -v "default-token\|service-account-token")
for secret in $SECRET_LIST; do
  seal_resource secret "$secret"
done

# Update kustomization file
echo
echo "Updating kustomization.yaml..."
update_kustomization

echo
echo "Sealing completed. Files are in $TEMP_DIR"
echo "To apply these changes, review the files and run:"
echo "cp $TEMP_DIR/*.yaml $KUSTOMIZE_DIR/"
