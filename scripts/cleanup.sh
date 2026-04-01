#!/usr/bin/env bash
# cleanup.sh — Remove transient AI-generated workspace artifacts
set -euo pipefail

FILES=("PR_DESCRIPTION.md" "scaffold.py")

for file in "${FILES[@]}"; do
  if [[ -f "${file}" ]]; then
    rm -f "${file}" || true
    if [[ -f "${file}" ]]; then
      echo "[WARN] Failed to remove: ${PWD}/${file}"
    else
      echo "[OK] Removed: ${PWD}/${file}"
    fi
  else
    echo "[OK] Not present: ${PWD}/${file}"
  fi
done

if [[ -d "_ai_tmp" ]]; then
  rm -rf "_ai_tmp" || true
  if [[ -d "_ai_tmp" ]]; then
    echo "[WARN] Failed to remove: ${PWD}/_ai_tmp"
  else
    echo "[OK] Removed: ${PWD}/_ai_tmp"
  fi
else
  echo "[OK] Not present: ${PWD}/_ai_tmp"
fi

exit 0
