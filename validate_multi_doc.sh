#!/bin/bash

echo "Testing split multi-document YAML validation..."

# Create a temporary directory
TEMP_DIR=$(mktemp -d)
echo "Using temporary directory: $TEMP_DIR"

# Manual method to split YAML documents by processing line by line
echo "Splitting policies/test-multiple-mixed.yaml into individual documents..."
awk 'BEGIN { count=0; path=ENVIRON["TEMP_DIR"] "/doc-" count ".yaml"; } 
/^---$/ { count++; path=ENVIRON["TEMP_DIR"] "/doc-" count ".yaml"; next; } 
{ print > path; }' TEMP_DIR="$TEMP_DIR" policies/test-multiple-mixed.yaml

# List the generated files
echo "Generated document files:"
ls -la $TEMP_DIR

# Initialize validation status
validation_failed=false

# Check each document
for doc in $TEMP_DIR/doc-*; do
  echo -e "\nValidating document: $doc"
  cat $doc
  echo ""
  
  # Run OPA validation
  if ! opa eval --fail --input "$doc" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.allow'; then
    echo "❌ Validation failed for document"
    validation_failed=true
    
    # Show the specific deny messages
    echo "Denial reasons:"
    opa eval --input "$doc" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.deny'
  else
    echo "✅ Validation passed for document"
  fi
done

# Clean up
echo -e "\nCleaning up temporary files..."
rm -rf $TEMP_DIR

# Report overall result
if [ "$validation_failed" = true ]; then
  echo -e "\n❌ One or more KafkaTopic resources failed validation"
  exit 1
else
  echo -e "\n✅ All KafkaTopic resources passed validation"
  exit 0
fi
