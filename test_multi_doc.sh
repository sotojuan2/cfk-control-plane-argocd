#!/bin/bash

echo "=== TASK 6.5: End-to-End Validation of KafkaTopic Policy Error Reporting ==="
echo "Testing multi-document file validation directly..."

# Set test file
TEST_FILE="policies/test-multiple-mixed.yaml"

echo "File content:"
cat "$TEST_FILE"

echo -e "\nValidating with OPA directly:"
opa eval --input "$TEST_FILE" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.deny'

echo -e "\nAttempting to split and validate documents:"
csplit -q -z -f "doc-" -b "%d.yaml" "$TEST_FILE" '/^---$/' '{*}'

echo "Generated documents:"
ls -la doc-*.yaml

echo -e "\nValidating each document separately:"
validation_failed=false

for doc in doc-*.yaml; do
  echo -e "\nValidating $doc:"
  cat "$doc"
  echo ""
  
  if ! opa eval --fail --input "$doc" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.allow'; then
    echo "❌ Validation failed for $doc"
    validation_failed=true
    
    echo "Denial reasons:"
    opa eval --input "$doc" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.deny'
  else
    echo "✅ Validation passed for $doc"
  fi
done

echo -e "\nCleaning up split files..."
rm -f doc-*.yaml

if [ "$validation_failed" = true ]; then
  echo -e "\n❌ One or more KafkaTopic resources failed validation"
  exit 1
else
  echo -e "\n✅ All KafkaTopic resources passed validation"
  exit 0
fi
