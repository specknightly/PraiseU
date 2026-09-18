#!/bin/zsh
set -euo pipefail

forbidden_path_regex='(^|/)(incidents\.json|accomplishments\.json|work-graph\.json|prevention-ledger\.json|operational-burden\.json)$|(^|/)(Evidence|Backups|Evidence Inbox)(/|$)'
forbidden_extension_regex='\.(eml|msg|mbox|pdf|doc|docx|xls|xlsx|csv|rtf|pages|numbers|key)$'

violations="$(git ls-files | grep -Ei "$forbidden_path_regex|$forbidden_extension_regex" || true)"

if [[ -n "$violations" ]]; then
  echo "Privacy guard failed. Runtime WorkRecord data or evidence-like files are tracked:"
  echo "$violations"
  echo "GitHub must remain source-only. Remove these files from Git before continuing."
  exit 1
fi

echo "Privacy guard passed: no tracked runtime WorkRecord databases, evidence directories, or blocked attachment formats."
