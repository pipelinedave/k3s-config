#!/bin/bash
# extract_namespace_resources.sh
# Script to extract all Kubernetes resources from a namespace, clean them, and save as individual files
# Usage: ./extract_namespace_resources.sh <namespace>

set -e

# Function to display usage information
usage() {
  echo "Usage: $0 <namespace>"
  echo "Extracts all Kubernetes resources from a namespace, cleans metadata, and saves as individual files"
  echo ""
  echo "Arguments:"
  echo "  namespace     The Kubernetes namespace to extract resources from"
  exit 1
}

# Check if namespace argument is provided
if [ -z "$1" ]; then
  usage
fi

NAMESPACE="$1"
OUTPUT_DIR="./${NAMESPACE}"
TMP_DIR="/tmp/k8s-extract-${NAMESPACE}"

# Create output directory if it doesn't exist
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${TMP_DIR}"

echo "Extracting resources from namespace: ${NAMESPACE}"
echo "Output directory: ${OUTPUT_DIR}"
echo ""

# Function to sanitize a filename (replace invalid characters)
sanitize_filename() {
  echo "$1" | tr -cd '[:alnum:]._-' | tr '[:upper:]' '[:lower:]'
}

# Function to get a unique filename if a file already exists
get_unique_filename() {
  local base_name=$1
  local extension=$2
  local dir=$3
  local filename="${base_name}.${extension}"
  local counter=2
  
  while [ -f "${dir}/${filename}" ]; do
    filename="${base_name}_${counter}.${extension}"
    counter=$((counter + 1))
  done
  
  echo "${filename}"
}

# Function to clean Kubernetes resource metadata
clean_resource() {
  local file=$1
  local output=$2
  
  # Skip if file doesn't exist or is empty
  if [ ! -s "$file" ]; then
    echo "Warning: Empty or non-existent file: $file"
    return 1
  fi
  
  # Remove status section and runtime-specific metadata
  < "$file" yq eval '
    # Strip out status
    del(.status) |
    # Remove various metadata
    del(.metadata.resourceVersion) |
    del(.metadata.uid) |
    del(.metadata.selfLink) |
    del(.metadata.creationTimestamp) |
    del(.metadata.generation) |
    del(.metadata.ownerReferences) |
    del(.metadata.managedFields) |
    del(.metadata.annotations["kubectl.kubernetes.io/last-applied-configuration"]) |
    del(.metadata.annotations["deployment.kubernetes.io/revision"]) |
    del(.metadata.annotations["control-plane.alpha.kubernetes.io/leader"]) |
    # Remove spec.template.metadata.creationTimestamp if null
    del(.spec.template.metadata.creationTimestamp) |
    # Remove empty metadata.annotations
    if .metadata.annotations == {} then del(.metadata.annotations) else . end
  ' > "$output"
  
  # Additional cleanups with sed for fields yq might miss
  sed -i \
    -e '/creationTimestamp: null/d' \
    -e '/terminationMessagePath: "\/dev\/termination-log"/d' \
    -e '/terminationMessagePolicy: File/d' \
    -e '/dnsPolicy: ClusterFirst/d' \
    -e '/schedulerName: default-scheduler/d' \
    -e '/serviceAccountName: default/d' \
    -e '/securityContext: {}/d' \
    -e '/resources: {}/d' \
    -e '/defaultMode: 420/d' \
    -e '/progressDeadlineSeconds: 600/d' \
    -e '/revisionHistoryLimit: 10/d' \
    -e '/restartPolicy: Always/d' \
    -e '/imagePullPolicy: Always/d' \
    -e '/imagePullPolicy: IfNotPresent/d' \
    -e '/\(\s*\)clusterIP: [0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+/d' \
    -e '/\(\s*\)clusterIPs:/,+1d' \
    -e '/internalTrafficPolicy: Cluster/d' \
    -e '/ipFamilies:/,+1d' \
    -e '/ipFamilyPolicy: SingleStack/d' \
    -e '/^[ ]*$/d' \
    "$output"
  
  # If the file is now empty or just contains a few lines, it might have been completely filtered out
  if [ ! -s "$output" ] || [ $(wc -l < "$output") -lt 3 ]; then
    echo "Warning: File was emptied after cleaning, will be skipped: $output"
    return 1
  fi
  
  return 0
}

# Get all resource types in the namespace
echo "Fetching resource types in namespace ${NAMESPACE}..."
RESOURCE_TYPES=$(kubectl api-resources --verbs=list --namespaced -o name | sort | uniq)

# Add explicitly some resources that might be missed
RESOURCE_TYPES="$RESOURCE_TYPES deployments services configmaps secrets ingresses statefulsets daemonsets cronjobs jobs persistentvolumeclaims roles rolebindings serviceaccounts"

# Process each resource type
for RESOURCE_TYPE in $RESOURCE_TYPES; do
  echo "Processing resource type: ${RESOURCE_TYPE}"
  
  # Get the resources of this type
  RESOURCES=$(kubectl get ${RESOURCE_TYPE} -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
  
  # Skip if no resources found or command failed
  if [ $? -ne 0 ] || [ -z "$RESOURCES" ]; then
    echo "  No ${RESOURCE_TYPE} found in namespace ${NAMESPACE}, skipping."
    continue
  fi
  
  # Process each resource
  for RESOURCE in $RESOURCES; do
    echo "  Processing ${RESOURCE_TYPE}/${RESOURCE}"
    SANITIZED_RESOURCE=$(sanitize_filename "${RESOURCE}")
    
    # Skip if it's a system secret (like service-account-token)
    if [ "$RESOURCE_TYPE" == "secrets" ] && kubectl get secret $RESOURCE -n $NAMESPACE -o jsonpath='{.type}' | grep -q "kubernetes.io/service-account-token"; then
      echo "    Skipping service account token secret: ${RESOURCE}"
      continue
    fi
    
    # Get base filename
    BASE_FILENAME="${RESOURCE_TYPE%s}"  # Remove trailing 's' for singular form
    if [ "$BASE_FILENAME" == "endpoints" ]; then BASE_FILENAME="endpoint"; fi
    if [ "$BASE_FILENAME" == "ingresse" ]; then BASE_FILENAME="ingress"; fi
    if [ "$BASE_FILENAME" == "service" ] && [ "$RESOURCE_TYPE" != "services" ]; then BASE_FILENAME="${RESOURCE_TYPE}"; fi
    
    # Create unique filename
    FILENAME=$(get_unique_filename "${BASE_FILENAME}" "yaml" "${OUTPUT_DIR}")
    
    # Export the resource to a temporary file
    TMP_FILE="${TMP_DIR}/${RESOURCE_TYPE}_${SANITIZED_RESOURCE}.yaml"
    
    # Export to YAML (using -o yaml to get full manifest)
    kubectl get ${RESOURCE_TYPE} ${RESOURCE} -n ${NAMESPACE} -o yaml > "${TMP_FILE}"
    
    # Clean the resource and save to output directory
    if clean_resource "${TMP_FILE}" "${OUTPUT_DIR}/${FILENAME}"; then
      echo "    Saved to ${OUTPUT_DIR}/${FILENAME}"
    else
      echo "    Failed to process ${RESOURCE_TYPE}/${RESOURCE}"
      # Remove the output file if it exists but cleaning failed
      [ -f "${OUTPUT_DIR}/${FILENAME}" ] && rm "${OUTPUT_DIR}/${FILENAME}"
    fi
  done
done

# Create a kustomization.yaml file in the output directory
echo "Creating kustomization.yaml file..."
{
  echo "apiVersion: kustomize.config.k8s.io/v1beta1"
  echo "kind: Kustomization"
  echo ""
  echo "namespace: ${NAMESPACE}"
  echo ""
  echo "resources:"
} > "${OUTPUT_DIR}/kustomization.yaml"

# List all files in the output directory and add them to kustomization.yaml
find "${OUTPUT_DIR}" -maxdepth 1 -type f -name "*.yaml" -not -name "kustomization.yaml" | sort | while read -r file; do
  echo "- $(basename "$file")" >> "${OUTPUT_DIR}/kustomization.yaml"
done

# Create a namespace manifest
{
  echo "apiVersion: v1"
  echo "kind: Namespace"
  echo "metadata:"
  echo "  name: ${NAMESPACE}"
} > "${OUTPUT_DIR}/namespace.yaml"

# Clean up temporary directory
rm -rf "${TMP_DIR}"

echo ""
echo "Extraction complete. Resources saved to ${OUTPUT_DIR}/"
echo "A kustomization.yaml file has been created to reference all extracted resources."
echo "A namespace.yaml file has been created for the ${NAMESPACE} namespace."
echo ""
echo "To apply these resources using kustomize:"
echo "  kubectl apply -k ${OUTPUT_DIR}/"
