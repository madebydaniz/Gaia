#!/usr/bin/env bash

set -euo pipefail

PROJECT_PATH="Gaia.xcodeproj"
SCHEME="Gaia"
CONFIGURATION="Release"
DESTINATION="platform=macOS"
APP_NAME="Gaia"
DIST_DIR="dist"
TMP_DIR="${DIST_DIR}/.dmg-tmp"
RW_DMG_PATH="${DIST_DIR}/${APP_NAME}-rw.dmg"
FINAL_DMG_PATH="${DIST_DIR}/${APP_NAME}.dmg"
BACKGROUND_SRC=".github/assets/dmg-background.png"
VOLUME_NAME="Gaia"
ICON_SIZE=128
ATTACH_PLIST="${DIST_DIR}/.dmg-attach.plist"
MOUNT_POINT="${TMP_DIR}/mount"

# Target window size in logical points
WINDOW_WIDTH=860
WINDOW_HEIGHT=560

APP_X=$((WINDOW_WIDTH / 2 - 180))
APPS_X=$((WINDOW_WIDTH / 2 + 180))
ICON_Y=$((WINDOW_HEIGHT - 185))
WINDOW_BOUNDS="{100, 100, ${WINDOW_WIDTH}, ${WINDOW_HEIGHT}}"
APP_ICON_POS="{${APP_X}, ${ICON_Y}}"
APPS_ICON_POS="{${APPS_X}, ${ICON_Y}}"

echo "==> Building ${APP_NAME}.app (${CONFIGURATION})"
xcodebuild \
  -project "${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination "${DESTINATION}" \
  build

echo "==> Locating built app"
APP_PATH="$(find "${HOME}/Library/Developer/Xcode/DerivedData" -path "*/Build/Products/${CONFIGURATION}/${APP_NAME}.app" | head -n 1)"
if [[ -z "${APP_PATH}" ]]; then
  echo "Error: ${APP_NAME}.app not found in DerivedData."
  exit 1
fi

mkdir -p "${DIST_DIR}"
rm -f "${FINAL_DMG_PATH}" "${RW_DMG_PATH}"

# Resize background to exactly the window size at 72 DPI (standard 1x)
# This guarantees the background always covers the full DMG window
BACKGROUND_PATH="${DIST_DIR}/dmg-background-scaled.png"
echo "==> Scaling background to ${WINDOW_WIDTH}x${WINDOW_HEIGHT} at 72 DPI"
cp "${BACKGROUND_SRC}" "${BACKGROUND_PATH}"
sips \
  --resampleHeightWidth "${WINDOW_HEIGHT}" "${WINDOW_WIDTH}" \
  --setProperty dpiWidth 72 \
  --setProperty dpiHeight 72 \
  "${BACKGROUND_PATH}" > /dev/null

if command -v create-dmg >/dev/null 2>&1; then
  echo "==> Using create-dmg"
  create-dmg \
    --volname "${VOLUME_NAME}" \
    --window-pos 100 100 \
    --window-size "${WINDOW_WIDTH}" "${WINDOW_HEIGHT}" \
    --icon-size "${ICON_SIZE}" \
    --icon "${APP_NAME}.app" "${APP_X}" "${ICON_Y}" \
    --icon "Applications" "${APPS_X}" "${ICON_Y}" \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link "${APPS_X}" "${ICON_Y}" \
    --background "${BACKGROUND_PATH}" \
    "${FINAL_DMG_PATH}" \
    "${APP_PATH}"
  rm -f "${BACKGROUND_PATH}"
  echo "==> Done"
  echo "DMG: ${FINAL_DMG_PATH}"
  exit 0
fi

echo "==> create-dmg not found; using built-in fallback"
rm -rf "${TMP_DIR}"
mkdir -p "${TMP_DIR}"

echo "==> Preparing DMG payload"
cp -R "${APP_PATH}" "${TMP_DIR}/${APP_NAME}.app"
ln -s /Applications "${TMP_DIR}/Applications"

echo "==> Creating read-write DMG"
hdiutil create \
  -volname "${VOLUME_NAME}" \
  -srcfolder "${TMP_DIR}" \
  -ov \
  -format UDRW \
  "${RW_DMG_PATH}"

echo "==> Mounting DMG"
mkdir -p "${MOUNT_POINT}"
ATTACH_OUTPUT="$(hdiutil attach -readwrite -noverify -noautoopen -mountpoint "${MOUNT_POINT}" "${RW_DMG_PATH}")"
DEVICE="$(echo "${ATTACH_OUTPUT}" | awk '/^\/dev\// {print $1}' | tail -n 1)"

if [[ -z "${DEVICE}" || -z "${MOUNT_POINT}" ]]; then
  echo "Error: failed to mount DMG."
  exit 1
fi

echo "==> Applying Finder layout"
mkdir -p "${MOUNT_POINT}/.background"
cp "${BACKGROUND_PATH}" "${MOUNT_POINT}/.background/background.png"

osascript <<EOF
tell application "Finder"
  tell folder (POSIX file "${MOUNT_POINT}" as alias)
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to ${WINDOW_BOUNDS}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to ${ICON_SIZE}
    set text size of viewOptions to 14
    set background picture of viewOptions to file ".background:background.png"
    set position of item "${APP_NAME}.app" of container window to ${APP_ICON_POS}
    set position of item "Applications" of container window to ${APPS_ICON_POS}
    close
    open
    update without registering applications
    delay 2
  end tell
end tell
EOF

echo "==> Finalizing DMG"
sync
hdiutil detach "${DEVICE}"
rm -f "${FINAL_DMG_PATH}"
hdiutil convert "${RW_DMG_PATH}" \
  -ov \
  -format UDZO \
  -o "${FINAL_DMG_PATH}"
rm -f "${RW_DMG_PATH}"
rm -rf "${TMP_DIR}"
rm -f "${ATTACH_PLIST}"
rm -f "${BACKGROUND_PATH}"

echo "==> Done"
echo "DMG: ${FINAL_DMG_PATH}"