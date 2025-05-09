#!/bin/bash
# extract_k8s_namespace.sh
# Script to extract and clean Kubernetes resources from a namespace
# Usage: ./extract_k8s_namespace.sh <namespace>

set -e

# Check if namespace is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <namespace>"
  echo "Extract and clean Kubernetes resources from a namespace"
  exit 1
fi

NAMESPACE=$1
OUTPUT_DIR="./${NAMESPACE}"

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo "Output directory created: $OUTPUT_DIR"

# Create namespace manifest
cat > "$OUTPUT_DIR/namespace.yaml" << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $NAMESPACE
EOF
echo "Created namespace.yaml"

# Define common resource types to extract
RESOURCE_TYPES=(
  "deployments.apps"
  "services"
  "configmaps"
  "persistentvolumeclaims"
  "ingresses.networking.k8s.io"
  "statefulsets.apps"
  "daemonsets.apps"
  "cronjobs.batch"
  "jobs.batch"
)

# Function to clean yaml from runtime-specific fields
clean_yaml() {
  local yaml=$1

  # Remove status section
  yaml=$(echo "$yaml" | sed '/^status:/,/^[a-z]/{ /^[a-z]/!d; /^status:/d }')
  
  # Remove various metadata fields
  yaml=$(echo "$yaml" | sed '/creationTimestamp:/d')
  yaml=$(echo "$yaml" | sed '/resourceVersion:/d')
  yaml=$(echo "$yaml" | sed '/uid:/d')
  yaml=$(echo "$yaml" | sed '/generation:/d')
  yaml=$(echo "$yaml" | sed '/selfLink:/d')
  
  # Remove last-applied-configuration
  yaml=$(echo "$yaml" | sed '/kubectl.kubernetes.io\/last-applied-configuration:/,/^[^ ]/{/^[^ ]/!d}')
  yaml=$(echo "$yaml" | sed '/kubectl.kubernetes.io\/last-applied-configuration:/d')
  
  # Remove managed fields
  yaml=$(echo "$yaml" | sed '/managedFields:/,/^[^ ]/{/^[^ ]/!d}')
  yaml=$(echo "$yaml" | sed '/managedFields:/d')
  
  # Remove various other runtime fields
  yaml=$(echo "$yaml" | sed '/clusterIP:/d')
  yaml=$(echo "$yaml" | sed '/clusterIPs:/,/- /d')
  yaml=$(echo "$yaml" | sed '/terminationMessagePath:/d')
  yaml=$(echo "$yaml" | sed '/terminationMessagePolicy:/d')
  yaml=$(echo "$yaml" | sed '/dnsPolicy: ClusterFirst/d')
  yaml=$(echo "$yaml" | sed '/schedulerName:/d')
  yaml=$(echo "$yaml" | sed '/serviceAccountName: default/d')
  yaml=$(echo "$yaml" | sed '/progressDeadlineSeconds:/d')
  yaml=$(echo "$yaml" | sed '/revisionHistoryLimit:/d')
  yaml=$(echo "$yaml" | sed '/imagePullPolicy:/d')
  
  # Remove null creationTimestamps 
  yaml=$(echo "$yaml" | sed '/creationTimestamp: null/d')
  
  # Clean up empty resources sections
  yaml=$(echo "$yaml" | sed '/resources: {}/d')
  
  # Clean up empty annotations
  yaml=$(echo "$yaml" | sed '/annotations: {}/d')
  
  # Clean up security context
  yaml=$(echo "$yaml" | sed '/securityContext: {}/d')
  
  # Clean up empty lines
  yaml=$(echo "$yaml" | sed '/^[[:space:]]*$/d')
  
  echo "$yaml"
}

# Process each resource type
for resource_type in "${RESOURCE_TYPES[@]}"; do
  echo "Processing $resource_type..."
  
  # Get short name for filename
  short_name=$(echo "$resource_type" | cut -d. -f1)
  
  # Get resources of this type
  resource_names=$(kubectl get "$resource_type" -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  
  if [ -z "$resource_names" ]; then
    echo "  No $resource_type found in namespace $NAMESPACE"
    continue
  fi
  
  # Process each resource
  count=1
  for name in $resource_names; do
    echo "  Processing $resource_type/$name"
    
    # Skip default service account and some system resources
    if [[ "$resource_type" == "serviceaccounts" && "$name" == "default" ]]; then
      echo "  Skipping default service account"
      continue
    fi
    
    # Skip some configmaps that are managed by the system
    if [[ "$resource_type" == "configmaps" && "$name" == "kube-root-ca.crt" ]]; then
      echo "  Skipping system configmap: $name"
      continue
    fi
    
    # Generate filename based on resource type and count
    if [ $count -eq 1 ]; then
      filename="${short_name}.yaml"
    else
      filename="${short_name}_${count}.yaml"
    fi
    
    # Get the resource yaml
    yaml=$(kubectl get "$resource_type" "$name" -n "$NAMESPACE" -o yaml)
    
    # Clean the yaml
    cleaned_yaml=$(clean_yaml "$yaml")
    
    # Save to file
    echo "$cleaned_yaml" > "$OUTPUT_DIR/$filename"
    echo "  Saved to $OUTPUT_DIR/$filename"
    
    count=$((count + 1))
  done
done

# Create a kustomization.yaml file
cat > "$OUTPUT_DIR/kustomization.yaml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: $NAMESPACE

resources:
- namespace.yaml
EOF

# Add all yaml files to kustomization.yaml
for file in "$OUTPUT_DIR"/*.yaml; do
  if [[ "$(basename "$file")" != "kustomization.yaml" && "$(basename "$file")" != "namespace.yaml" ]]; then
    echo "- $(basename "$file")" >> "$OUTPUT_DIR/kustomization.yaml"
  fi
done

echo "Done extracting resources for namespace: $NAMESPACE"
echo "All resources have been saved to $OUTPUT_DIR"
