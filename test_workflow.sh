#!/bin/bash

echo "Testing OPA validation workflow logic..."

# Simulate changed files (you can modify this list for testing)
changed_files="policies/topics_invalid.yml"

echo "Simulating validation for files: $changed_files"

validation_failed=false

for file in $changed_files; do
  if [[ -f "$file" ]]; then
    echo "Validating $file..."
    
    # Check if the file contains a KafkaTopic resource
    if grep -q "kind: KafkaTopic" "$file"; then
      echo "Found KafkaTopic in $file, running OPA validation..."
      
      # Run OPA validation
      if ! opa eval --fail --input "$file" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.allow'; then
        echo "❌ Validation failed for $file"
        validation_failed=true
        
        # Show the specific deny messages
        echo "Denial reasons:"
        opa eval --input "$file" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.deny'
      else
        echo "✅ Validation passed for $file"
      fi
    else
      echo "Skipping $file (not a KafkaTopic resource)"
    fi
  else
    echo "Warning: File $file not found"
  fi
done

# Fail the script if any validation failed
if [ "$validation_failed" = true ]; then
  echo "❌ One or more KafkaTopic resources failed validation"
  exit 1
else
  echo "✅ All KafkaTopic resources passed validation"
fi
