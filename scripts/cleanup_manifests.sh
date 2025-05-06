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
  
  # Make a backup
  cp "$file" "${file}.bak"
  
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
    
  # Remove empty sections and annotations
  sed -i '/annotations:/,/^[^ ]/s/^    [^ ].*//g' "$file"
  sed -i '/annotations: {}/d' "$file"
  sed -i '/^[ ]*$/d' "$file" # Remove empty lines
  
  echo "Cleaned $file"
}

# Process all YAML files in the directory
find "$DIRECTORY" -type f \( -name "*.yaml" -o -name "*.yml" \) | while read file; do
  # Skip files in test directory or with "sealed" in the name as they may be already sealed
  if [[ "$file" != *"/test/"* ]] && [[ "$file" != *sealed* ]]; then
    clean_yaml "$file"
  fi
done

echo "Cleanup completed for $DIRECTORY"
