#!/bin/bash
# Homologation driver for the flutter_chrome_cast Android example app.
#
# Drives the in-app HomologationScreen over adb and collects structured results
# from logcat (tag lines prefixed with "HOMOLOG|").
#
# Usage:
#   scripts/homolog.sh launch              # force-stop + launch app
#   scripts/homolog.sh open                # open the Homologation screen
#   scripts/homolog.sh run <suite>         # run one suite (or "all")
#   scripts/homolog.sh collect [timeout]   # print HOMOLOG lines (default 30s wait)
#   scripts/homolog.sh watch [timeout]     # live-stream HOMOLOG lines
#   scripts/homolog.sh taps <text>         # tap UI node whose content-desc == <text>
#   scripts/homolog.sh shots <name>        # screencap -> /tmp/cast_screens/<name>.png
#   scripts/homolog.sh log <pattern>       # grep the app's logcat
#
# Suites: context discovery session load transport queue tracks volume messages

set -uo pipefail

PKG=com.felnanuke.google_cast_example
ACT=$PKG/.MainActivity
SHOTS=/tmp/cast_screens
mkdir -p "$SHOTS"

pid() { adb shell pidof "$PKG" | tr -d '\r'; }

# Print bounds="[x1,y1][x2,y2]" for the first node whose content-desc == $1.
node_bounds() {
  adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
  adb shell cat /sdcard/ui.xml | tr '>' '>\n' \
    | grep -o "content-desc=\"${1//\"/}\"[^>]*bounds=\"\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]\"" \
    | grep -o 'bounds="\[[0-9]*,[0-9]*\]\[[0-9]*,[0-9]*\]"' | head -1
}

# bounds="..." -> "cx cy"
bounds_center() {
  echo "$1" | sed -E 's/bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\1 \2 \3 \4/' \
    | awk '{print int(($1+$3)/2), int(($2+$4)/2)}'
}

cmd="${1:-help}"; shift || true

case "$cmd" in
  launch)
    adb shell am force-stop "$PKG"
    sleep 1
    adb logcat -c
    adb shell am start -n "$ACT" >/dev/null
    sleep 7
    echo "launched pid=$(pid)"
    ;;

  open)
    # Homologation icon is the first AppBar action.
    b=$(node_bounds "Homologation")
    if [ -z "$b" ]; then echo "Homologation button not found"; exit 1; fi
    set -- $(bounds_center "$b")
    adb shell input tap "$1" "$2"
    sleep 3
    echo "opened homologation at ($1,$2)"
    ;;

  run)
    suite="${1:-all}"
    [ "$suite" = "all" ] && label="Run all suites" || label="$suite"
    adb logcat -c
    b=$(node_bounds "$label")
    if [ -z "$b" ]; then echo "chip '$label' not found (is the Homologation screen open?)"; exit 1; fi
    set -- $(bounds_center "$b")
    adb shell input tap "$1" "$2"
    echo "tapped '$label' at ($1,$2)"
    ;;

  collect)
    timeout="${1:-30}"
    adb logcat -d -v time 2>/dev/null | grep "HOMOLOG|" | sed 's/.*HOMOLOG|/HOMOLOG|/'
    ;;

  watch)
    timeout="${1:-60}"
    adb logcat -v time 2>/dev/null | grep --line-buffered "HOMOLOG|" \
      | sed -u 's/.*HOMOLOG|/HOMOLOG|/' &
    LG=$!
    sleep "$timeout"
    kill $LG 2>/dev/null
    wait $LG 2>/dev/null
    ;;

  taps)
    label="$1"
    b=$(node_bounds "$label")
    if [ -z "$b" ]; then echo "node '$label' not found"; exit 1; fi
    set -- $(bounds_center "$b")
    adb shell input tap "$1" "$2"
    echo "tapped '$label' at ($1,$2)"
    ;;

  shots)
    name="${1:-shot}"
    adb exec-out screencap -p > "$SHOTS/$name.png"
    sips -Z 620 "$SHOTS/$name.png" --out "$SHOTS/${name}_s.png" >/dev/null 2>&1
    echo "$SHOTS/${name}_s.png"
    ;;

  log)
    pat="${1:-HOMOLOG}"
    adb logcat -d -v time 2>/dev/null | grep -E "$pat" | tail -60
    ;;

  devices)
    adb devices -l
    ;;

  *)
    sed -n '2,20p' "$0"
    ;;
esac
