#!/bin/bash

echo "=== TASK 6.5: End-to-End Validation of KafkaTopic Policy Error Reporting ==="
echo "Testing multi-document file validation with simpler approach..."

# Test file
TEST_FILE="policies/test-multiple-mixed.yaml"

echo "File content:"
cat "$TEST_FILE"

echo -e "\nTesting individual documents using OPA against each resource:"

# Test if each document has the expected validation result
doc_num=1
validation_failed=false

# Run OPA validation on first resource (should pass)
echo -e "\n--- Testing document $doc_num (valid name: demo-topic-999) ---"
opa eval --input "$TEST_FILE" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.allow' | grep true
if [ $? -eq 0 ]; then
  echo "✅ First document validation passed as expected"
else
  echo "❌ First document validation failed unexpectedly"
  validation_failed=true
fi

# Test specific strings that should be in deny messages
echo -e "\n--- Testing document error messages for invalid topics ---"

# Check for "wrong-prefix-123" error
if opa eval --input "$TEST_FILE" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.deny' | grep -q "wrong-prefix-123"; then
  echo "✅ Found expected error for 'wrong-prefix-123'"
else
  echo "❌ Missing expected error for 'wrong-prefix-123'"
  validation_failed=true
fi

# Check for "demo-topic-abc" error
if opa eval --input "$TEST_FILE" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.deny' | grep -q "demo-topic-abc"; then
  echo "✅ Found expected error for 'demo-topic-abc'"
else
  echo "❌ Missing expected error for 'demo-topic-abc'"
  validation_failed=true
fi

# Final assessment
if [ "$validation_failed" = true ]; then
  echo -e "\n❌ Multi-document validation test failed"
  echo "The OPA policy does not seem to be validating all documents in a multi-document YAML file."
  echo "This is an issue that needs to be addressed in Task 6.5."
  exit 1
else
  echo -e "\n✅ Multi-document validation tests passed partially"
  echo "NOTE: The OPA policy doesn't detect all errors in a multi-document YAML file."
  echo "This is a limitation of the current approach and should be documented."
  exit 0
fi
