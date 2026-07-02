#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="$ROOT_DIR/.build/IELTSReader.app"
OUTPUT_DIR="${1:-$ROOT_DIR/../../outputs}"
DMG_PATH="$OUTPUT_DIR/IELTSReader-1.0.dmg"
VOLUME_NAME="IELTSReader"
STAGING_DIR="$(mktemp -d /tmp/ieltsreader-dmg.XXXXXX)"
RW_DMG="$STAGING_DIR/IELTSReader-rw.dmg"
MOUNT_DIR="$STAGING_DIR/mount"

cleanup() {
  hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$OUTPUT_DIR" "$MOUNT_DIR"

if [[ ! -d "$APP_PATH" ]]; then
  "$ROOT_DIR/make_app.sh" >/dev/null
fi

mkdir -p "$STAGING_DIR/root"
ditto "$APP_PATH" "$STAGING_DIR/root/IELTSReader.app"
ln -s /Applications "$STAGING_DIR/root/Applications"

cat > "$STAGING_DIR/root/Damaged App Help.txt" <<'TEXT'
If macOS says IELTSReader is damaged
====================================

IELTSReader is an open-source app distributed outside the Mac App Store. On some Macs, Gatekeeper may quarantine the app and show a message such as "IELTSReader is damaged and can't be opened."

If you trust the copy you downloaded from the official GitHub release, run this command in Terminal:

sudo xattr -rd com.apple.quarantine /Applications/IELTSReader.app

Then open IELTSReader again from Applications.
TEXT

cat > "$STAGING_DIR/root/Fix Damaged App.command" <<'SCRIPT'
#!/bin/zsh
set -e
APP="/Applications/IELTSReader.app"
echo "Removing macOS quarantine flag from $APP"
if [[ ! -d "$APP" ]]; then
  echo "IELTSReader.app was not found in /Applications."
  echo "Drag IELTSReader.app into Applications first, then run this script again."
  read "?Press Return to close."
  exit 1
fi
sudo xattr -rd com.apple.quarantine "$APP"
echo
echo "Done. You can open IELTSReader from Applications now."
read "?Press Return to close."
SCRIPT
chmod +x "$STAGING_DIR/root/Fix Damaged App.command"

SWIFTPM_MODULECACHE_OVERRIDE="$ROOT_DIR/.build/module-cache" \
CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/module-cache" \
swiftc "$ROOT_DIR/scripts/make_dmg_background.swift" -o "$STAGING_DIR/make_dmg_background"
"$STAGING_DIR/make_dmg_background" "$STAGING_DIR/root/DMG Background.png"

hdiutil create -srcfolder "$STAGING_DIR/root" -volname "$VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size 24m "$RW_DMG"
hdiutil attach "$RW_DMG" -mountpoint "$MOUNT_DIR" -nobrowse -quiet

/usr/bin/osascript <<APPLESCRIPT
set mountedFolder to POSIX file "$MOUNT_DIR" as alias
set backgroundFile to POSIX file "$MOUNT_DIR/DMG Background.png" as alias
tell application "Finder"
  open mountedFolder
  delay 2
  set containerWindow to front window
  set current view of containerWindow to icon view
  set toolbar visible of containerWindow to false
  set statusbar visible of containerWindow to false
  try
    set sidebar width of containerWindow to 0
  end try
  set the bounds of containerWindow to {100, 100, 820, 540}
  set viewOptions to the icon view options of containerWindow
  set arrangement of viewOptions to not arranged
  set icon size of viewOptions to 76
  tell viewOptions
    set background picture to backgroundFile
  end tell
  set position of item "IELTSReader.app" of containerWindow to {190, 205}
  set position of item "Applications" of containerWindow to {530, 205}
  set position of item "Damaged App Help.txt" of containerWindow to {205, 325}
  set position of item "Fix Damaged App.command" of containerWindow to {515, 325}
  update mountedFolder without registering applications
  delay 2
  close containerWindow
end tell
APPLESCRIPT

chflags hidden "$MOUNT_DIR/DMG Background.png"
sync
hdiutil detach "$MOUNT_DIR" -quiet
hdiutil convert "$RW_DMG" -format UDZO -imagekey zlib-level=9 -ov -o "$DMG_PATH"

echo "$DMG_PATH"
