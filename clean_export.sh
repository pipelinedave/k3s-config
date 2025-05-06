#!/bin/bash

# Improved script to clean Kubernetes resources from a namespace
# This script exports bare resources without sensitive metadata
# Usage: ./clean_export.sh <namespace>

if [ -z "$1" ]; then
  echo "Usage: ./clean_export.sh <namespace>"
  exit 1
fi

NAMESPACE=$1
REPO_DIR="/home/dave/src/k3s-config"
KUSTOMIZE_DIR="${REPO_DIR}/kustomize/${NAMESPACE}"
TEMP_DIR="/tmp/k3s-clean-${NAMESPACE}"

# Create a temporary directory
mkdir -p "$TEMP_DIR"
echo "Working in temporary directory: $TEMP_DIR"

# Function to clean and export a resource type
clean_export() {
  local resource_type=$1
  local output_file=$2
  
  echo "Exporting clean $resource_type..."
  
  # Create a simple YAML template with only the essential fields
  kubectl get $resource_type -n $NAMESPACE -o yaml | \
    python3 -c "
import sys, yaml, json
data = yaml.safe_load(sys.stdin.read())
clean_items = []

# Process each item
for item in data.get('items', []):
    clean_item = {
        'apiVersion': item.get('apiVersion'),
        'kind': item.get('kind'),
        'metadata': {
            'name': item.get('metadata', {}).get('name'),
            'namespace': item.get('metadata', {}).get('namespace')
        },
        'spec': item.get('spec', {})
    }
    
    # Handle annotations we want to keep
    annotations = item.get('metadata', {}).get('annotations', {})
    kept_annotations = {}
    for key, value in annotations.items():
        if not any(skip in key for skip in ['kubernetes.io', 'kubectl.io']):
            kept_annotations[key] = value
    
    if kept_annotations:
        clean_item['metadata']['annotations'] = kept_annotations
    
    # Handle labels
    labels = item.get('metadata', {}).get('labels', {})
    if labels:
        clean_item['metadata']['labels'] = labels
    
    clean_items.append(clean_item)

# Create clean output
clean_data = {
    'apiVersion': data.get('apiVersion'),
    'kind': data.get('kind'),
    'items': clean_items
}

# If it's a single resource, not a list
if not data.get('items'):
    clean_data = {
        'apiVersion': data.get('apiVersion'),
        'kind': data.get('kind'),
        'metadata': {
            'name': data.get('metadata', {}).get('name'),
            'namespace': data.get('metadata', {}).get('namespace')
        },
        'spec': data.get('spec', {})
    }
    
    # Handle annotations we want to keep
    annotations = data.get('metadata', {}).get('annotations', {})
    kept_annotations = {}
    for key, value in annotations.items():
        if not any(skip in key for skip in ['kubernetes.io', 'kubectl.io']):
            kept_annotations[key] = value
    
    if kept_annotations:
        clean_data['metadata']['annotations'] = kept_annotations
    
    # Handle labels
    labels = data.get('metadata', {}).get('labels', {})
    if labels:
        clean_data['metadata']['labels'] = labels

print(yaml.dump(clean_data, default_flow_style=False))
" > "$output_file"

  echo "Created $output_file"
}

# Copy the kustomization file
if [ -f "${KUSTOMIZE_DIR}/kustomization.yaml" ]; then
  cp "${KUSTOMIZE_DIR}/kustomization.yaml" "${TEMP_DIR}/kustomization.yaml"
  echo "Copied kustomization.yaml"
fi

# Export deployments
if kubectl get deployments -n $NAMESPACE 2>/dev/null | grep -q .; then
  clean_export deployments "${TEMP_DIR}/deployment.yaml"
fi

# Export statefulsets
if kubectl get statefulsets -n $NAMESPACE 2>/dev/null | grep -q .; then
  clean_export statefulsets "${TEMP_DIR}/statefulset.yaml"
fi

# Export services
if kubectl get services -n $NAMESPACE 2>/dev/null | grep -v kubernetes | grep -q .; then
  clean_export services "${TEMP_DIR}/service.yaml"
fi

# Export ingress
if kubectl get ingress -n $NAMESPACE 2>/dev/null | grep -q .; then
  clean_export ingress "${TEMP_DIR}/ingress.yaml"
fi

# Export PVCs
if kubectl get pvc -n $NAMESPACE 2>/dev/null | grep -q .; then
  clean_export pvc "${TEMP_DIR}/pvc.yaml"
fi

# Note: ConfigMaps will be handled separately by the sealing script

echo
echo "Clean export completed to $TEMP_DIR"
echo "To apply these changes, review the files and run:"
echo "cp $TEMP_DIR/*.yaml $KUSTOMIZE_DIR/"
