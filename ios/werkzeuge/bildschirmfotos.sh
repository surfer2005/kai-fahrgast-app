#!/usr/bin/env bash
# Bildschirmfotos der App im iPhone-Simulator — Vorführdaten (-demo) und einmal echt gegen KAI.
#   bildschirmfotos.sh <Simulator-UDID> <Pfad zur .app> <Zielordner>
set -euo pipefail
UDID=$1; APP=$2; ZIEL=$3; ID=de.kaibsb.fahrgastinfo
mkdir -p "$ZIEL"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl status_bar "$UDID" override --time 10:14 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
xcrun simctl install "$UDID" "$APP"
foto() {
  local name=$1; shift
  xcrun simctl terminate "$UDID" "$ID" 2>/dev/null || true
  xcrun simctl launch "$UDID" "$ID" -AppleLanguages "(de)" -AppleLocale de_DE "$@" >/dev/null
  sleep "${WARTE:-5}"
  xcrun simctl io "$UDID" screenshot "$ZIEL/$name.png" >/dev/null
  echo "✔ $name"
}
xcrun simctl ui "$UDID" appearance light
foto 01-meldungen -demo stoerung
foto 02-mitteilungen -demo stoerung -zeige benachrichtigungen
foto 03-datenschutz -demo stoerung -zeige datenschutz
foto 04-keine-meldung -demo leer
WARTE=10 foto 05-echt-kai-test
xcrun simctl ui "$UDID" appearance dark
foto 06-meldungen-dunkel -demo stoerung
xcrun simctl ui "$UDID" appearance light
