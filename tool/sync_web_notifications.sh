#!/usr/bin/env bash
# Copies the web's notification texts (the backend's titleKey/messageKey →
# text) so the app's notifications read exactly like the web's. Run after
# the web adds or changes notification events:
#   tool/sync_web_notifications.sh ../atlas
set -euo pipefail
WEB="${1:-../atlas}"
for lang in en ar; do
  cp "$WEB/src/localization/resources/$lang/notifications.json" "assets/l10n/notifications_$lang.json"
done
echo "synced notifications_en.json and notifications_ar.json from $WEB"
