#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Nowbar"
BUNDLE_ID="com.marlonjd.Nowbar"
VERSION="${VERSION:-1.0.0}"
MIN_SYSTEM_VERSION="13.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
BUILD_ROOT="$RELEASE_DIR/build"
PAYLOAD_ROOT="$BUILD_ROOT/pkg-root"
APP_BUNDLE="$RELEASE_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON="$ROOT_DIR/Resources/AppIcon.icns"
ZIP_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.zip"
COMPONENT_PKG="$BUILD_ROOT/$APP_NAME-component.pkg"
PKG_PATH="$RELEASE_DIR/$APP_NAME-$VERSION.pkg"
SWIFTPM_HOME="$ROOT_DIR/.swiftpm-home"

CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
INSTALLER_SIGN_IDENTITY="${INSTALLER_SIGN_IDENTITY:-}"

SWIFT_BUILD_ARGS=(
  -c release
  --disable-sandbox
  --cache-path "$ROOT_DIR/.build/swiftpm-cache"
  --config-path "$ROOT_DIR/.build/swiftpm-config"
  --security-path "$ROOT_DIR/.build/swiftpm-security"
  --manifest-cache local
)

rm -rf "$RELEASE_DIR"
mkdir -p "$RELEASE_DIR" "$APP_MACOS" "$APP_RESOURCES" "$SWIFTPM_HOME"

HOME="$SWIFTPM_HOME" swift build "${SWIFT_BUILD_ARGS[@]}"
BUILD_BINARY="$(HOME="$SWIFTPM_HOME" swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)/$APP_NAME"

cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$APP_ICON" "$APP_RESOURCES/AppIcon.icns"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$VERSION</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>Shows currently playing media from Music, Spotify, and YouTube browser tabs in the macOS menu bar.</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ -n "$CODE_SIGN_IDENTITY" ]]; then
  codesign --force --timestamp --options runtime --sign "$CODE_SIGN_IDENTITY" "$APP_BUNDLE"
else
  echo "warning: CODE_SIGN_IDENTITY is not set; creating ad-hoc signed local artifact." >&2
  codesign --force --sign - "$APP_BUNDLE"
fi

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
/usr/sbin/spctl --assess --type execute --verbose=4 "$APP_BUNDLE" || true

ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

mkdir -p "$PAYLOAD_ROOT/Applications"
ditto "$APP_BUNDLE" "$PAYLOAD_ROOT/Applications/$APP_NAME.app"
chmod +x "$ROOT_DIR/packaging/pkg-scripts/postinstall"

pkgbuild \
  --root "$PAYLOAD_ROOT" \
  --scripts "$ROOT_DIR/packaging/pkg-scripts" \
  --identifier "$BUNDLE_ID.pkg" \
  --version "$VERSION" \
  --install-location "/" \
  "$COMPONENT_PKG"

if [[ -n "$INSTALLER_SIGN_IDENTITY" ]]; then
  productsign --sign "$INSTALLER_SIGN_IDENTITY" "$COMPONENT_PKG" "$PKG_PATH"
else
  echo "warning: INSTALLER_SIGN_IDENTITY is not set; package is unsigned and cannot be notarized for public distribution." >&2
  cp "$COMPONENT_PKG" "$PKG_PATH"
fi

pkgutil --check-signature "$PKG_PATH" || true

echo "$APP_BUNDLE"
echo "$ZIP_PATH"
echo "$PKG_PATH"
