#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
dir=$(mktemp -d "${TMPDIR:-/tmp}/wg-widget-test.XXXXXX")
trap 'rm -f -- "$dir/Polling.qml" "$dir/WireGuardModel.qml" "$dir/WireGuardModel.js"; rmdir -- "$dir"' EXIT
cp tests/Polling.qml WireGuardModel.qml WireGuardModel.js "$dir/"
QT_QPA_PLATFORM=offscreen timeout 9s quickshell -p "$dir/Polling.qml"
