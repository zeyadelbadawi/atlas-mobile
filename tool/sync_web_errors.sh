#!/usr/bin/env bash
# Copies the web's error catalogue (the backend's messageKey → text) so the
# app shows the same messages. Run after the web adds or changes error keys:
#   tool/sync_web_errors.sh ../atlas
set -euo pipefail
WEB="${1:-../atlas}"
for lang in en ar; do
  cp "$WEB/src/localization/resources/$lang/errors.json" "assets/l10n/errors_$lang.json"
done
echo "synced errors_en.json and errors_ar.json from $WEB"
