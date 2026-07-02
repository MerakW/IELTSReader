#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT_DIR/.build/IELTSReader.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
BUILD_INFO_DIR="$RESOURCES_DIR/BuildInfo"

cd "$ROOT_DIR"
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/module-cache" \
CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache" \
swift build -c release \
  --arch arm64 \
  --arch x86_64 \
  --cache-path "$ROOT_DIR/.build/swiftpm-cache"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$BUILD_INFO_DIR"
cp "$ROOT_DIR/.build/apple/Products/Release/IELTSReader" "$MACOS_DIR/IELTSReader"
chmod +x "$MACOS_DIR/IELTSReader"
cp "$ROOT_DIR/AppInfo.plist" "$CONTENTS_DIR/Info.plist"

ACTOOL="/Applications/Xcode.app/Contents/Developer/usr/bin/actool"
if [[ -x "$ACTOOL" && -d "$ROOT_DIR/Resources/IELTSReader.icon" ]]; then
  "$ACTOOL" \
    --compile "$RESOURCES_DIR" \
    --platform macosx \
    --minimum-deployment-target 16.0 \
    --app-icon IELTSReader \
    --output-partial-info-plist "$BUILD_INFO_DIR/AssetCatalogInfo.plist" \
    "$ROOT_DIR/Resources/IELTSReader.icon"
else
  cp "$ROOT_DIR/Resources/IELTSReader.icns" "$RESOURCES_DIR/IELTSReader.icns"
fi

cp -R "$ROOT_DIR/Resources/IELTSReader.icon" "$RESOURCES_DIR/IELTSReader.icon"
xattr -cr "$APP_DIR"
codesign --force --sign - "$APP_DIR"

echo "$APP_DIR"
