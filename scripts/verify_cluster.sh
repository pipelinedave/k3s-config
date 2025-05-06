#!/bin/bash

# Script to verify if the k3s-config repository matches the cluster state
# This script:
# 1. Identifies namespaces that exist in the cluster but are not represented in the repository
# 2. Checks if all resource types are represented in each namespace
# 3. Compares repository resources with cluster resources for discrepancies

REPO_DIR="/home/dave/src/k3s-config"
APPS_DIR="${REPO_DIR}/apps"
KUSTOMIZE_DIR="${REPO_DIR}/kustomize"
TEMP_DIR="/tmp/k3s-verification"
DIFF_DIR="${TEMP_DIR}/diff"

# Create temp directories
mkdir -p "${TEMP_DIR}"
mkdir -p "${DIFF_DIR}"

echo "Checking for namespaces in cluster that are not represented in repository..."
echo

# Get all non-system namespaces
kubectl get namespaces -o json | jq -r '.items[] | select(.metadata.name | test("^(kube-|cert-manager|default|flux-system)$") | not) | .metadata.name' | sort > /tmp/cluster_namespaces.txt

# Get all namespaces represented in the apps directory
find "${APPS_DIR}" -name "*.yaml" -exec basename {} \; | sed 's/\.yaml$//' | sort > /tmp/repo_namespaces.txt

# Find namespaces in cluster but not in repository
comm -23 /tmp/cluster_namespaces.txt /tmp/repo_namespaces.txt > /tmp/missing_namespaces.txt

if [ -s /tmp/missing_namespaces.txt ]; then
  echo "The following namespaces exist in the cluster but are not represented in the repository:"
  cat /tmp/missing_namespaces.txt
  echo
  echo "You can add these namespaces to the repository by running:"
  echo
  cat /tmp/missing_namespaces.txt | while read namespace; do
    echo "  ./export_namespace.sh ${namespace}"
  done
else
  echo "All non-system namespaces in the cluster are represented in the repository."
fi

echo
echo "Checking for resources in each namespace..."
echo

# Resource types to check
RESOURCE_TYPES=("deployment" "statefulset" "service" "ingress" "pvc" "configmap" "secret" "daemonset" "cronjob")

# Check each namespace in the repository to see if all resource types are represented
cat /tmp/repo_namespaces.txt | while read namespace; do
  echo "Checking namespace: ${namespace}"
  
  # Check if the namespace actually exists in the cluster
  if ! kubectl get namespace ${namespace} >/dev/null 2>&1; then
    echo "  WARNING: Namespace ${namespace} is in the repository but does not exist in the cluster"
    continue
  fi
  
  # Get the kustomization file for this namespace
  kustomization_file="${KUSTOMIZE_DIR}/${namespace}/kustomization.yaml"
  if [ ! -f "${kustomization_file}" ]; then
    echo "  WARNING: No kustomization file found for namespace ${namespace}"
    continue
  fi
  
  # Create namespace directory in temp dir for detailed comparison
  mkdir -p "${TEMP_DIR}/${namespace}"
  
  # Track counts for summary
  total_resources=0
  missing_resources=0
  
  # Check each resource type
  for res_type in "${RESOURCE_TYPES[@]}"; do
    # Convert to k8s file naming (e.g., pvc -> persistentvolumeclaim)
    k8s_type="${res_type}"
    if [ "${res_type}" == "pvc" ]; then
      k8s_type="persistentvolumeclaim"
    fi
    
    # Check if resources exist in the cluster
    if kubectl get ${k8s_type} -n ${namespace} -o json | jq -e '.items | length > 0' >/dev/null 2>&1; then
      # Count resources
      count=$(kubectl get ${k8s_type} -n ${namespace} -o json | jq '.items | length')
      total_resources=$((total_resources + count))
      
      # Check if referenced in kustomization
      if ! grep -q "${res_type}.yaml" "${kustomization_file}" && ! grep -q "${k8s_type}.yaml" "${kustomization_file}"; then
        echo "  WARNING: ${count} ${k8s_type}(s) exist in namespace ${namespace} but ${res_type}.yaml is not included in kustomization"
        missing_resources=$((missing_resources + count))
        
        # Check if there are sealed versions for secrets
        if [ "${res_type}" == "secret" ] && grep -q "sealed" "${kustomization_file}"; then
          echo "    INFO: Sealed secrets are included in kustomization, which may replace regular secrets"
        fi
      else
        # Perform deeper comparison
        repo_file="${TEMP_DIR}/${namespace}/${res_type}_repo.yaml"
        cluster_file="${TEMP_DIR}/${namespace}/${res_type}_cluster.yaml"
        diff_file="${DIFF_DIR}/${namespace}_${res_type}_diff.txt"
        
        # Extract from repository
        find "${KUSTOMIZE_DIR}/${namespace}" -name "*${res_type}*.yaml" -type f | xargs cat 2>/dev/null > "${repo_file}"
        
        # Extract from cluster (removing dynamic fields)
        kubectl get ${k8s_type} -n ${namespace} -o yaml | \
          yq eval 'del(.items[].metadata.managedFields, .items[].metadata.generation, 
                       .items[].metadata.resourceVersion, .items[].metadata.uid, 
                       .items[].metadata.creationTimestamp, .items[].status)' - > "${cluster_file}"
        
        # Compare files if both exist and are not empty
        if [ -s "${repo_file}" ] && [ -s "${cluster_file}" ]; then
          # Basic comparison - just check if the names match
          repo_names=$(grep -o "name: [a-zA-Z0-9_-]*" "${repo_file}" | sort)
          cluster_names=$(grep -o "name: [a-zA-Z0-9_-]*" "${cluster_file}" | grep -v "controller-uid\|job-name" | sort)
          
          if [ "$(echo "$repo_names" | wc -l)" -ne "$(echo "$cluster_names" | wc -l)" ]; then
            echo "  WARNING: Number of ${k8s_type}s in repository ($(echo "$repo_names" | wc -l)) does not match cluster ($(echo "$cluster_names" | wc -l))"
            missing_count=$(($(echo "$cluster_names" | wc -l) - $(echo "$repo_names" | wc -l)))
            if [ $missing_count -gt 0 ]; then
              missing_resources=$((missing_resources + missing_count))
            fi
          fi
          
          # Store diff for detailed analysis
          diff -u "${repo_file}" "${cluster_file}" > "${diff_file}" 2>/dev/null
          
          # Check if differences exist (excluding expected metadata differences)
          if [ -s "${diff_file}" ]; then
            echo "  DETAIL: Found differences in ${k8s_type}s, see ${diff_file}"
          fi
        fi
      fi
    fi
  done
  
  # Summary for this namespace
  if [ $total_resources -gt 0 ]; then
    echo "  SUMMARY: ${namespace} has $total_resources resources in cluster, $missing_resources potentially missing from repository"
    percentage=$((100 - (missing_resources * 100 / total_resources)))
    echo "  COVERAGE: Repository is approximately ${percentage}% complete for this namespace"
  else
    echo "  SUMMARY: No resources found in namespace ${namespace}"
  fi
  
  echo
done

echo "===================================="
echo "Verification complete"
echo "===================================="
echo 
echo "Summary of findings:"
echo "1. Namespaces in cluster but missing from repository: $(cat /tmp/missing_namespaces.txt | wc -l)"
echo "2. Detailed differences are available in: ${DIFF_DIR}"
echo
echo "Next steps:"
echo "1. For missing namespaces, run: ./export_namespace.sh <namespace>"
echo "2. For existing namespaces with missing resources, run: ./process_namespace.sh <namespace>"
echo "3. Review detailed differences in ${DIFF_DIR} to find specific discrepancies"
echo
echo "After making changes, run this script again to verify improvements."
