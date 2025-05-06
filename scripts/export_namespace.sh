#!/bin/bash

# Script to export Kubernetes resources from a namespace to the k3s-config repository
# Usage: ./export_namespace.sh <namespace>

if [ -z "$1" ]; then
  echo "Usage: ./export_namespace.sh <namespace>"
  exit 1
fi

NAMESPACE=$1
REPO_DIR="/home/dave/src/k3s-config"
KUSTOMIZE_DIR="${REPO_DIR}/kustomize/${NAMESPACE}"
APPS_FILE="${REPO_DIR}/apps/${NAMESPACE}.yaml"

# Check if namespace exists
if ! kubectl get namespace ${NAMESPACE} &>/dev/null; then
  echo "Namespace ${NAMESPACE} does not exist"
  exit 1
fi

# Create Flux Kustomization
if [ ! -f "${APPS_FILE}" ]; then
  cat > "${APPS_FILE}" << EOF
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: ${NAMESPACE}
  namespace: flux-system
spec:
  targetNamespace: ${NAMESPACE}
  interval: 5m
  path: ./kustomize/${NAMESPACE}
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  wait: true
  timeout: 2m
EOF
  echo "Created ${APPS_FILE}"
fi

# Create kustomize directory
mkdir -p "${KUSTOMIZE_DIR}"

# Create kustomization.yaml
if [ ! -f "${KUSTOMIZE_DIR}/kustomization.yaml" ]; then
  cat > "${KUSTOMIZE_DIR}/kustomization.yaml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
EOF

  # Check for deployments
  if kubectl get deployments -n ${NAMESPACE} &>/dev/null && [ "$(kubectl get deployments -n ${NAMESPACE} -o json | jq '.items | length')" -gt 0 ]; then
    echo "- deployment.yaml" >> "${KUSTOMIZE_DIR}/kustomization.yaml"
    kubectl get deployments -n ${NAMESPACE} -o yaml > "${KUSTOMIZE_DIR}/deployment.yaml"
    echo "Exported deployments"
  fi

  # Check for statefulsets
  if kubectl get statefulsets -n ${NAMESPACE} &>/dev/null && [ "$(kubectl get statefulsets -n ${NAMESPACE} -o json | jq '.items | length')" -gt 0 ]; then
    echo "- statefulset.yaml" >> "${KUSTOMIZE_DIR}/kustomization.yaml"
    kubectl get statefulsets -n ${NAMESPACE} -o yaml > "${KUSTOMIZE_DIR}/statefulset.yaml"
    echo "Exported statefulsets"
  fi

  # Check for services
  if kubectl get services -n ${NAMESPACE} &>/dev/null && [ "$(kubectl get services -n ${NAMESPACE} -o json | jq '.items | length')" -gt 0 ]; then
    echo "- service.yaml" >> "${KUSTOMIZE_DIR}/kustomization.yaml"
    kubectl get services -n ${NAMESPACE} -o yaml > "${KUSTOMIZE_DIR}/service.yaml"
    echo "Exported services"
  fi

  # Check for ingress
  if kubectl get ingress -n ${NAMESPACE} &>/dev/null && [ "$(kubectl get ingress -n ${NAMESPACE} -o json | jq '.items | length')" -gt 0 ]; then
    echo "- ingress.yaml" >> "${KUSTOMIZE_DIR}/kustomization.yaml"
    kubectl get ingress -n ${NAMESPACE} -o yaml > "${KUSTOMIZE_DIR}/ingress.yaml"
    echo "Exported ingress"
  fi

  # Check for PVCs
  if kubectl get pvc -n ${NAMESPACE} &>/dev/null && [ "$(kubectl get pvc -n ${NAMESPACE} -o json | jq '.items | length')" -gt 0 ]; then
    echo "- pvc.yaml" >> "${KUSTOMIZE_DIR}/kustomization.yaml"
    kubectl get pvc -n ${NAMESPACE} -o yaml > "${KUSTOMIZE_DIR}/pvc.yaml"
    echo "Exported PVCs"
  fi

  # Check for configmaps
  if kubectl get configmaps -n ${NAMESPACE} &>/dev/null && [ "$(kubectl get configmaps -n ${NAMESPACE} -o json | jq '.items | length')" -gt 0 ]; then
    echo "- configmap.yaml" >> "${KUSTOMIZE_DIR}/kustomization.yaml"
    kubectl get configmaps -n ${NAMESPACE} -o yaml > "${KUSTOMIZE_DIR}/configmap.yaml"
    echo "Exported ConfigMaps"
  fi

  echo "Created ${KUSTOMIZE_DIR}/kustomization.yaml"
else
  echo "${KUSTOMIZE_DIR}/kustomization.yaml already exists, skipping"
fi

echo "Export of namespace ${NAMESPACE} completed"
