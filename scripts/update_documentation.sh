#!/bin/bash
#
# update_documentation.sh
# 
# This script updates documentation to reflect the current state of the repository
# Run this script after significant changes or as part of a pre-commit/post-commit hook

# Set the base directory
BASE_DIR=$(git rev-parse --show-toplevel)
cd "$BASE_DIR" || exit 1

echo "Starting documentation update..."

# Update the Fully Managed Applications section
echo "Updating fully managed applications list..."
FULLY_MANAGED_APPS=$(find apps/ -type f -name "*.yaml" | sort | sed 's|apps/||g' | sed 's|.yaml||g')

# Update the Partially Managed Applications section
echo "Updating partially managed applications list..."
PARTIAL_APPS=$(find apps-incomplete/ -type f -name "*.yaml" | sort | sed 's|apps-incomplete/||g' | sed 's|.yaml||g')

# Generate the applications markdown content
APPS_MARKDOWN="## Fully Managed Applications\n\nThe following applications are fully Flux-managed:\n\n"

# Process fully managed apps
for app in $FULLY_MANAGED_APPS; do
  # Try to get description from kustomization file
  if [ -f "$BASE_DIR/kustomize/$app/kustomization.yaml" ]; then
    DESCRIPTION=$(grep -A5 "commonAnnotations:" "$BASE_DIR/kustomize/$app/kustomization.yaml" | grep "description:" | sed 's/.*description: //g' || echo "")
    
    if [ -z "$DESCRIPTION" ]; then
      # Try to find description in README if it exists
      if [ -f "$BASE_DIR/kustomize/$app/README.md" ]; then
        DESCRIPTION=$(head -n 3 "$BASE_DIR/kustomize/$app/README.md" | grep -v "#" | tr -d '\n' || echo "")
      fi
    fi
    
    # Default description if none found
    if [ -z "$DESCRIPTION" ]; then
      DESCRIPTION="Application in namespace $app"
    fi
    
    APPS_MARKDOWN+="- $app: $DESCRIPTION\n"
  else
    APPS_MARKDOWN+="- $app\n"
  fi
done

# Process partially managed apps
APPS_MARKDOWN+="\n## Partially Managed Applications\n\nThe following applications are partially managed or incomplete:\n\n"

for app in $PARTIAL_APPS; do
  # Try to get description from kustomization file
  if [ -f "$BASE_DIR/kustomize-incomplete/$app/kustomization.yaml" ]; then
    DESCRIPTION=$(grep -A5 "commonAnnotations:" "$BASE_DIR/kustomize-incomplete/$app/kustomization.yaml" | grep "description:" | sed 's/.*description: //g' || echo "")
    
    if [ -z "$DESCRIPTION" ]; then
      # Try to find description in README if it exists
      if [ -f "$BASE_DIR/kustomize-incomplete/$app/README.md" ]; then
        DESCRIPTION=$(head -n 3 "$BASE_DIR/kustomize-incomplete/$app/README.md" | grep -v "#" | tr -d '\n' || echo "")
      fi
    fi
    
    # Default description if none found
    if [ -z "$DESCRIPTION" ]; then
      DESCRIPTION="Application in namespace $app"
    fi
    
    APPS_MARKDOWN+="- $app: $DESCRIPTION\n"
  else
    APPS_MARKDOWN+="- $app\n"
  fi
done

# Update the docs/README.md file with the new application lists
echo "Updating main documentation file..."

# Create a temporary file
TMP_FILE=$(mktemp)

# Use awk to replace the sections in the README.md
awk -v apps_markdown="$APPS_MARKDOWN" '
BEGIN { in_fully_section = 0; in_partially_section = 0; fully_done = 0; partially_done = 0; }
/^## Fully Managed Applications/ { 
  in_fully_section = 1; 
  print; 
  print ""; 
  print "The following applications are fully Flux-managed:"; 
  print ""; 
  gsub(/\\n/, "\n", apps_markdown);
  split(apps_markdown, lines, "\n");
  in_fully_apps = 1;
  next; 
}
/^## Partially Managed Applications/ { 
  in_fully_section = 0; 
  in_partially_section = 1; 
  fully_done = 1;
  print; 
  print ""; 
  print "The following applications are partially managed or incomplete:"; 
  print ""; 
  in_partially_apps = 1;
  next; 
}
/^##/ && in_fully_section && !in_partially_section { 
  in_fully_section = 0; 
  fully_done = 1;
  print; 
  next; 
}
/^##/ && in_partially_section { 
  in_partially_section = 0; 
  partially_done = 1;
  print; 
  next; 
}
in_fully_section && in_fully_apps { 
  if ($0 ~ /^[^-]/) {
    in_fully_apps = 0;
    print;
  } else {
    # Skip existing list items
  }
  next;
}
in_partially_section && in_partially_apps { 
  if ($0 ~ /^[^-]/) {
    in_partially_apps = 0;
    print;
  } else {
    # Skip existing list items
  }
  next;
}
{ print; }
' "$BASE_DIR/docs/README.md" > "$TMP_FILE"

# Replace the original file
mv "$TMP_FILE" "$BASE_DIR/docs/README.md"

# Update the repository structure section if needed
echo "Checking repository structure..."

# Create Git hook for auto-updates
echo "Setting up Git hook for documentation updates..."
HOOK_DIR="$BASE_DIR/.git/hooks"
POST_COMMIT_HOOK="$HOOK_DIR/post-commit"

mkdir -p "$HOOK_DIR"

# Create or update post-commit hook
cat > "$POST_COMMIT_HOOK" << 'EOF'
#!/bin/bash
# Post-commit hook to update documentation

# Run the update script
./scripts/update_documentation.sh

# Check if any documentation files were changed
if git diff --quiet docs/ .github/; then
  # No changes to documentation
  exit 0
else
  # Documentation was updated, commit the changes
  git add docs/ .github/
  git commit --amend --no-edit --no-verify
fi
EOF

chmod +x "$POST_COMMIT_HOOK"

echo "Documentation update complete!"
exit 0
