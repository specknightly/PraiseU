#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
echo "Building Entropy Shield Work Record v1.9.0..."
echo "Cleaning stale SwiftPM build artifacts..."
swift package clean
rm -rf "$ROOT/.build"
echo "Building release..."
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"
OUT_DIR="$ROOT/build"
APP="$OUT_DIR/Entropy Shield Work Record.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"
cp "$BIN_DIR/IncidentTracker" "$MACOS/IncidentTracker"
chmod +x "$MACOS/IncidentTracker"
cp "$ROOT/Resources/EntropyShieldLogo.png" "$RESOURCES/EntropyShieldLogo.png"

ICON_NAME="EntropyShieldAppIcon"
ICONSET="$OUT_DIR/${ICON_NAME}.iconset"
mkdir -p "$ICONSET"
if command -v sips >/dev/null 2>&1 && command -v iconutil >/dev/null 2>&1; then
  SRC="$ROOT/Resources/EntropyShieldAppIcon.png"
  sips -z 16 16 "$SRC" --out "$ICONSET/icon_16x16.png" >/dev/null
  sips -z 32 32 "$SRC" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
  sips -z 32 32 "$SRC" --out "$ICONSET/icon_32x32.png" >/dev/null
  sips -z 64 64 "$SRC" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
  sips -z 128 128 "$SRC" --out "$ICONSET/icon_128x128.png" >/dev/null
  sips -z 256 256 "$SRC" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
  sips -z 256 256 "$SRC" --out "$ICONSET/icon_256x256.png" >/dev/null
  sips -z 512 512 "$SRC" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
  sips -z 512 512 "$SRC" --out "$ICONSET/icon_512x512.png" >/dev/null
  sips -z 1024 1024 "$SRC" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
  iconutil -c icns "$ICONSET" -o "$RESOURCES/$ICON_NAME.icns"
  rm -rf "$ICONSET"
fi

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleDisplayName</key><string>Entropy Shield Work Record</string>
<key>CFBundleExecutable</key><string>IncidentTracker</string>
<key>CFBundleIdentifier</key><string>com.entropyshield.workrecord</string>
<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
<key>CFBundleName</key><string>Entropy Shield Work Record</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.9.0</string>
<key>CFBundleVersion</key><string>11</string>
<key>LSMinimumSystemVersion</key><string>15.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSAppleEventsUsageDescription</key><string>Entropy Shield can optionally read one Apple Mail mailbox you select for local evidence and request intelligence.</string>
<key>CFBundleIconFile</key><string>EntropyShieldAppIcon</string>
<key>CFBundleURLTypes</key><array><dict><key>CFBundleURLName</key><string>Entropy Shield Capture</string><key>CFBundleURLSchemes</key><array><string>entropyshield</string><string>accomplishmenttracker</string></array></dict></array>
</dict></plist>
PLIST
if command -v codesign >/dev/null 2>&1; then codesign --force --deep --sign - "$APP"; fi
echo "Built: $APP"
open "$APP"
