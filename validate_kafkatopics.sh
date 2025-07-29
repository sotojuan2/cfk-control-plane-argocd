#!/bin/bash

echo "=== TASK 6.5: End-to-End Validation of KafkaTopic OPA Validation and Error Reporting ==="
echo "Running comprehensive validation test across all test scenarios..."

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Define test files - organize them by expected outcome
VALID_FILES=(
  "policies/topics_valid.yml"
  "policies/test-valid-topic.yaml"
  "policies/test_kafkatopic_valid.yaml"
)

INVALID_FILES=(
  "policies/topics_invalid.yml"
  "policies/test-invalid-name.yaml"
  "policies/test-wrong-prefix.yaml"
  "policies/test-wrong-suffix.yaml"
  "policies/test-empty-name.yaml"
)

MIXED_FILES=(
  "policies/test-multiple-mixed.yaml"
)

ERROR_FILES=(
  "policies/test-missing-metadata.yaml"
)

# Track test results
total_tests=0
passed_tests=0
failed_tests=0

# Function to run validation
validate_file() {
  local file=$1
  local expected_result=$2
  local test_type=$3
  
  total_tests=$((total_tests + 1))
  
  echo -e "\n${YELLOW}=======================================${NC}"
  echo -e "${YELLOW}Testing: ${file} (Expected: ${expected_result})${NC}"
  echo -e "${YELLOW}=======================================${NC}"
  
  # Check if file exists
  if [[ ! -f "$file" ]]; then
    echo -e "${RED}Error: File ${file} not found!${NC}"
    failed_tests=$((failed_tests + 1))
    return 1
  fi
  
  # Run OPA validation
  echo "File content:"
  cat "$file"
  echo ""
  
  # Run validation and capture result
  # For diagnosis, show the raw 'allow' result
  echo "OPA allow result:"
  opa eval --input "$file" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.allow'
  
  # Check if there are any deny messages
  deny_output=$(opa eval --input "$file" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.deny')
  if [[ "$deny_output" == *"[]"* ]]; then
    validation_result="pass"
  else
    validation_result="fail"
  fi
  
  # Show deny messages regardless of pass/fail for diagnosis
  echo "OPA deny messages:"
  opa eval --input "$file" --data policies/kafkatopic_naming.rego 'data.kafkatopic_naming.deny'
  
  # Check if result matches expectation
  if [[ "$validation_result" == "$expected_result" ]]; then
    echo -e "${GREEN}✓ Test PASSED: ${file} - Result: ${validation_result} (Expected: ${expected_result})${NC}"
    passed_tests=$((passed_tests + 1))
  else
    echo -e "${RED}✗ Test FAILED: ${file} - Result: ${validation_result} (Expected: ${expected_result})${NC}"
    failed_tests=$((failed_tests + 1))
  fi
}

# Test valid files - should pass validation
echo -e "\n${YELLOW}=== Testing valid KafkaTopic resources (should PASS) ===${NC}"
for file in "${VALID_FILES[@]}"; do
  validate_file "$file" "pass" "valid"
done

# Test invalid files - should fail validation
echo -e "\n${YELLOW}=== Testing invalid KafkaTopic resources (should FAIL with specific error messages) ===${NC}"
for file in "${INVALID_FILES[@]}"; do
  validate_file "$file" "fail" "invalid"
done

# Test malformed files - should fail validation
echo -e "\n${YELLOW}=== Testing malformed KafkaTopic resources (should FAIL with specific error messages) ===${NC}"
for file in "${ERROR_FILES[@]}"; do
  validate_file "$file" "fail" "error"
done

# Test mixed files - should fail validation (because they contain at least one invalid resource)
echo -e "\n${YELLOW}=== Testing mixed KafkaTopic resources (should FAIL with detailed errors for each invalid resource) ===${NC}"
for file in "${MIXED_FILES[@]}"; do
  validate_file "$file" "fail" "mixed"
done

# Print summary
echo -e "\n${YELLOW}=== TEST SUMMARY ===${NC}"
echo -e "Total tests run: ${total_tests}"
echo -e "${GREEN}Tests passed: ${passed_tests}${NC}"
echo -e "${RED}Tests failed: ${failed_tests}${NC}"

# Exit with failure if any tests failed
if [ $failed_tests -gt 0 ]; then
  echo -e "\n${RED}❌ One or more validation tests failed${NC}"
  exit 1
else
  echo -e "\n${GREEN}✅ All validation tests passed${NC}"
  exit 0
fi
