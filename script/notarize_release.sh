#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${VERSION:-1.0.0}"
APP_NAME="Nowbar"
ARTIFACT="${1:-$ROOT_DIR/release/$APP_NAME-$VERSION.pkg}"
APP_BUNDLE="${APP_BUNDLE:-$ROOT_DIR/release/$APP_NAME.app}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-}"
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_PASSWORD="${APP_PASSWORD:-}"

if [[ ! -f "$ARTIFACT" ]]; then
  echo "artifact not found: $ARTIFACT" >&2
  exit 2
fi

args=("$ARTIFACT" "--wait")

if [[ -n "$KEYCHAIN_PROFILE" ]]; then
  args+=("--keychain-profile" "$KEYCHAIN_PROFILE")
elif [[ -n "$APPLE_ID" && -n "$TEAM_ID" && -n "$APP_PASSWORD" ]]; then
  args+=("--apple-id" "$APPLE_ID" "--team-id" "$TEAM_ID" "--password" "$APP_PASSWORD")
else
  cat >&2 <<EOF
Missing notary credentials.

Use either:
  KEYCHAIN_PROFILE=nowbar-notary $0

or:
  APPLE_ID=you@example.com TEAM_ID=ABCDE12345 APP_PASSWORD=xxxx-xxxx-xxxx-xxxx $0

Create a keychain profile with:
  xcrun notarytool store-credentials nowbar-notary --apple-id you@example.com --team-id ABCDE12345 --password xxxx-xxxx-xxxx-xxxx
EOF
  exit 2
fi

xcrun notarytool submit "${args[@]}"

case "$ARTIFACT" in
  *.zip)
    if [[ ! -d "$APP_BUNDLE" ]]; then
      echo "app bundle not found for stapling: $APP_BUNDLE" >&2
      exit 2
    fi
    xcrun stapler staple "$APP_BUNDLE"
    xcrun stapler validate "$APP_BUNDLE"
    ditto -c -k --keepParent "$APP_BUNDLE" "$ARTIFACT"
    ;;
  *.pkg|*.dmg|*.app)
    xcrun stapler staple "$ARTIFACT"
    xcrun stapler validate "$ARTIFACT"
    ;;
  *)
    echo "notarized, but do not know how to staple artifact: $ARTIFACT" >&2
    exit 2
    ;;
esac
