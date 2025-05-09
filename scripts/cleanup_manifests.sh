#!/bin/bash

# Script to clean Kubernetes manifests by removing unnecessary metadata
# Usage: ./cleanup_manifests.sh <directory>

if [ -z "$1" ]; then
  echo "Usage: ./cleanup_manifests.sh <directory>"
  exit 1
fi

DIRECTORY=$1

# Function to clean up a YAML file
clean_yaml() {
  local file=$1
  
  # Check if the file exists
  if [ ! -f "$file" ]; then
    echo "File not found: $file"
    return
  fi
  
  echo "Cleaning $file..."
  
  # Check if file contains a List kind
  if grep -q "kind: List" "$file"; then
    echo "  Detected List resource in $file - cleaning List format..."
    clean_list_type "$file"
    return
  fi
  
  # Use sed for basic cleanup
  # Remove common metadata fields and status
  sed -i \
    -e '/creationTimestamp:/d' \
    -e '/resourceVersion:/d' \
    -e '/uid:/d' \
    -e '/selfLink:/d' \
    -e '/generation:/d' \
    -e '/kubectl.kubernetes.io\/last-applied-configuration:/,/^[^ ]/s/^  [^ ].*//g' \
    -e '/last-applied-configuration:/d' \
    -e '/status:/,/^[^ ]/s/^  [^ ].*//g' \
    -e '/status: {}/d' \
    "$file"
    
  # Remove other runtime fields
  sed -i \
    -e '/terminationMessagePath:/d' \
    -e '/terminationMessagePolicy:/d' \
    -e '/dnsPolicy: ClusterFirst/d' \
    -e '/schedulerName: default-scheduler/d' \
    -e '/deployment.kubernetes.io\/revision:/d' \
    -e '/restartedAt:/d' \
    -e '/defaultMode: 420/d' \
    -e '/imagePullPolicy: Always/d' \
    -e '/securityContext: {}/d' \
    "$file"
  
  # Remove empty sections and annotations
  sed -i '/annotations:/,/^[^ ]/s/^    [^ ].*//g' "$file"
  sed -i '/annotations: {}/d' "$file"
  sed -i '/^[ ]*$/d' "$file" # Remove empty lines
  
  echo "Cleaned $file"
}

# Function to clean List type resources (keeping the original file)
clean_list_type() {
  local file=$1
  local tmp_file=$(mktemp)
  
  # Extract the relevant data from the List and convert to proper YAML
  # First, get the actual resource from items array
  # Remove the List wrapper and items array
  sed -e '/^kind: List$/d' \
      -e '/^apiVersion: v1$/d' \
      -e '/^items:$/d' \
      -e '/^- /s/^- //' \
      -e '/^metadata:$/,/^[^ ]/d' \
      "$file" > "$tmp_file"
  
  # Clean the extracted resource
  clean_yaml "$tmp_file"
  
  # Replace the original file with the cleaned one
  mv "$tmp_file" "$file"
  
  echo "  List resource cleaned and saved back to $file"
}

# Process all YAML files in the directory
find "$DIRECTORY" -type f \( -name "*.yaml" -o -name "*.yml" \) | while read file; do
  # Skip files in test directory or with "sealed" in the name as they may be already sealed
  if [[ "$file" != *"/test/"* ]] && [[ "$file" != *sealed* ]]; then
    clean_yaml "$file"
  fi
done

echo "Cleanup completed for $DIRECTORY"

# Make script executable again if needed
chmod +x "$0"

# Process all YAML files in the directory
find "$DIRECTORY" -type f \( -name "*.yaml" -o -name "*.yml" \) | while read file; do
  # Skip files in test directory or with "sealed" in the name as they may be already sealed
  if [[ "$file" != *"/test/"* ]] && [[ "$file" != *sealed* ]]; then
    clean_yaml "$file"
  fi
done

echo "Cleanup completed for $DIRECTORY"

# Make script executable again if needed
chmod +x "$0"
