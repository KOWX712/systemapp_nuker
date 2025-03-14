#!/bin/sh
# action.sh
# this is part of system app nuker
# this is modified from tricky-addon's action

ORG_PATH=$PATH
MODPATH="/data/adb/modules/system_app_nuker"
TMP_DIR="$MODPATH/common/tmp"
APK_PATH="$TMP_DIR/base.apk"

manual_download() {
    echo "$1"
    sleep 3
    PATH=$ORG_PATH
    am start -a android.intent.action.VIEW -d "https://github.com/5ec1cff/KsuWebUIStandalone/releases"
    exit 1
}

download() {
    PATH=/data/data/com.termux/files/usr/bin:/data/adb/magisk:/data/adb/magisk:$PATH
    for attempt in {1..3}; do  # Try up to 3 times
        if command -v curl >/dev/null 2>&1; then
            timeout 10 curl -Ls "$1" && return 0
        elif command -v busybox wget >/dev/null 2>&1; then
            timeout 10 busybox wget --no-check-certificate -qO- "$1" && return 0
        fi
        echo "[!] Download failed, retrying ($attempt/3)..."
        sleep 3
    done
    echo "[!] Download failed after 3 attempts. Please check your internet." >&2
    return 1
}


get_webui() {
    echo "- Downloading KSU WebUI Standalone..."
    API="https://api.github.com/repos/5ec1cff/KsuWebUIStandalone/releases/latest"
    ping -c 1 -w 5 raw.githubusercontent.com &>/dev/null || manual_download "! Error: Unable to connect to raw.githubusercontent.com, please download manually."
    URL=$(download "$API" | grep -o '"browser_download_url": "[^"]*"' | cut -d '"' -f 4) || manual_download "! Error: Unable to get latest version, please download manually."
    download "$URL" > "$APK_PATH" || manual_download "! Error: APK download failed, please download manually."

    echo "- Installing..."
    pm install -r "$APK_PATH" || {
        rm -f "$APK_PATH"
        manual_download "! Error: APK installation failed, please download manually.."
    }

    echo "- Done."
    rm -f "$APK_PATH"

    echo "- Launching WebUI..."
    PATH=$ORG_PATH
    am start -n "io.github.a13e300.ksuwebui/.WebUIActivity" -e id "system_app_nuker"
}

# Launch KSUWebUI standalone or MMRL, install KSUWebUI standalone if both are not installed
if pm path io.github.a13e300.ksuwebui >/dev/null 2>&1; then
    echo "- Launching WebUI in KSUWebUIStandalone..."
    am start -n "io.github.a13e300.ksuwebui/.WebUIActivity" -e id "system_app_nuker"
elif pm path com.dergoogler.mmrl >/dev/null 2>&1; then
    echo "- Launching WebUI in MMRL WebUI..."
    am start -n "com.dergoogler.mmrl/.ui.activity.webui.WebUIActivity" -e MOD_ID "system_app_nuker"
else
    echo "! No WebUI app found"
    get_webui
fi

echo "- WebUI launched successfully."

# EOF
