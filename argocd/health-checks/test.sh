#!/usr/bin/env bash
# Runs the CFK custom health checks in argocd/cfk-health-checks.yaml against
# sample resources using the Argo CD CLI (no cluster needed).
set -euo pipefail
cd "$(dirname "$0")"
CM=../cfk-health-checks.yaml
failed=0
for f in testdata/*.yaml; do
  case "$f" in
    *-healthy.yaml) expected=Healthy ;;
    *-degraded.yaml) expected=Degraded ;;
    *-progressing.yaml) expected=Progressing ;;
  esac
  out=$(argocd admin settings resource-overrides health "$f" --argocd-cm-path "$CM" 2>/dev/null)
  actual=$(echo "$out" | awk '/^STATUS:/ {print $2}')
  if [ "$actual" = "$expected" ]; then
    echo "PASS $f -> $actual"
  else
    echo "FAIL $f -> expected $expected, got: $out"
    failed=1
  fi
done
exit $failed
