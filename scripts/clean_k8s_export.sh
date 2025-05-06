#!/bin/bash

# Script to safely clean Kubernetes manifests and create new versions without sensitive data
# Usage: ./clean_k8s_export.sh <namespace>

if [ -z "$1" ]; then
  echo "Usage: ./clean_k8s_export.sh <namespace>"
  exit 1
fi

NAMESPACE=$1
REPO_DIR="/home/dave/src/k3s-config"
KUSTOMIZE_DIR="${REPO_DIR}/kustomize/${NAMESPACE}"
CLEAN_DIR="${KUSTOMIZE_DIR}-clean"

# Check if namespace directory exists
if [ ! -d "$KUSTOMIZE_DIR" ]; then
  echo "Namespace directory not found: $KUSTOMIZE_DIR"
  exit 1
fi

# Create clean directory
mkdir -p "$CLEAN_DIR"

# Copy kustomization.yaml
if [ -f "${KUSTOMIZE_DIR}/kustomization.yaml" ]; then
  cp "${KUSTOMIZE_DIR}/kustomization.yaml" "${CLEAN_DIR}/kustomization.yaml"
  echo "Copied kustomization.yaml"
fi

# Extract deployments without sensitive data
if kubectl get deployments -n ${NAMESPACE} &> /dev/null; then
  echo "Exporting clean deployments..."
  kubectl get deployments -n ${NAMESPACE} -o yaml | \
    sed '/creationTimestamp:/d; /resourceVersion:/d; /uid:/d; /selfLink:/d; /generation:/d;' | \
    sed '/kubectl.kubernetes.io\/last-applied-configuration/,/^[^ ]/d' | \
    sed '/status:/,/^[^ ]/d' | \
    sed '/annotations: {}/d' | \
    grep -v "^[ ]*$" > "${CLEAN_DIR}/deployment.yaml"
  
  echo "Created clean deployment.yaml"
fi

# Extract statefulsets without sensitive data
if kubectl get statefulsets -n ${NAMESPACE} &> /dev/null; then
  echo "Exporting clean statefulsets..."
  kubectl get statefulsets -n ${NAMESPACE} -o yaml | \
    sed '/creationTimestamp:/d; /resourceVersion:/d; /uid:/d; /selfLink:/d; /generation:/d;' | \
    sed '/kubectl.kubernetes.io\/last-applied-configuration/,/^[^ ]/d' | \
    sed '/status:/,/^[^ ]/d' | \
    sed '/annotations: {}/d' | \
    grep -v "^[ ]*$" > "${CLEAN_DIR}/statefulset.yaml"
  
  echo "Created clean statefulset.yaml"
fi

# Extract services without sensitive data
if kubectl get services -n ${NAMESPACE} &> /dev/null; then
  echo "Exporting clean services..."
  kubectl get services -n ${NAMESPACE} -o yaml | \
    sed '/creationTimestamp:/d; /resourceVersion:/d; /uid:/d; /selfLink:/d; /generation:/d;' | \
    sed '/kubectl.kubernetes.io\/last-applied-configuration/,/^[^ ]/d' | \
    sed '/status:/,/^[^ ]/d' | \
    sed '/annotations: {}/d' | \
    grep -v "^[ ]*$" > "${CLEAN_DIR}/service.yaml"
  
  echo "Created clean service.yaml"
fi

# Extract ingress without sensitive data
if kubectl get ingress -n ${NAMESPACE} &> /dev/null; then
  echo "Exporting clean ingress..."
  kubectl get ingress -n ${NAMESPACE} -o yaml | \
    sed '/creationTimestamp:/d; /resourceVersion:/d; /uid:/d; /selfLink:/d; /generation:/d;' | \
    sed '/kubectl.kubernetes.io\/last-applied-configuration/,/^[^ ]/d' | \
    sed '/status:/,/^[^ ]/d' | \
    sed '/annotations: {}/d' | \
    grep -v "^[ ]*$" > "${CLEAN_DIR}/ingress.yaml"
  
  echo "Created clean ingress.yaml"
fi

# Extract PVCs without sensitive data
if kubectl get pvc -n ${NAMESPACE} &> /dev/null; then
  echo "Exporting clean PVCs..."
  kubectl get pvc -n ${NAMESPACE} -o yaml | \
    sed '/creationTimestamp:/d; /resourceVersion:/d; /uid:/d; /selfLink:/d; /generation:/d;' | \
    sed '/kubectl.kubernetes.io\/last-applied-configuration/,/^[^ ]/d' | \
    sed '/status:/,/^[^ ]/d' | \
    sed '/annotations: {}/d' | \
    grep -v "^[ ]*$" > "${CLEAN_DIR}/pvc.yaml"
  
  echo "Created clean pvc.yaml"
fi

# We don't export ConfigMaps here as they will be handled separately by the seal script

echo "Clean export completed to $CLEAN_DIR"
echo "Review the files and then run: mv $CLEAN_DIR/* $KUSTOMIZE_DIR/"
