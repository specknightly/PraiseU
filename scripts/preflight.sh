#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

printf 'Checking plist...\n'
plutil -lint WorkEvidence/Info.plist
plutil -lint WorkEvidence/WorkEvidence.entitlements

printf 'Checking for common generated files...\n'
if find . -type f \( -name '.DS_Store' -o -name '*.xcuserstate' \) | grep -q .; then
  echo 'Generated/user-specific files found.' >&2
  exit 1
fi

if command -v xcodebuild >/dev/null 2>&1; then
  printf 'Type-check/building macOS target without code signing...\n'
  xcodebuild \
    -project WorkEvidence.xcodeproj \
    -target WorkEvidence \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    build
else
  printf 'xcodebuild unavailable; skipped SDK-level build.\n'
fi
