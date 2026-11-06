#!/usr/bin/env bash
# Generates the Play upload key once. Keep the .jks and its passwords safe
# and OUT of git (losing the key means you can never update the app on Play
# unless you enrol in Play App Signing key reset). Run from the repo root:
#   bash tool/make_upload_key.sh
set -euo pipefail
OUT="${1:-$HOME/atlas-upload.jks}"
ALIAS="${2:-atlas-upload}"
if [ -f "$OUT" ]; then echo "Refusing to overwrite existing $OUT" >&2; exit 1; fi
read -r -s -p "New keystore password: " PW; echo
keytool -genkeypair -v -keystore "$OUT" -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PW" -keypass "$PW" \
  -dname "CN=CoreMind, O=CoreMind, C=EG"
cat <<NOTE

Done: $OUT  (alias: $ALIAS)

Next:
  1) Create android/key.properties (see android/key.properties.example) with
     storeFile=$OUT, storePassword/keyPassword=<the password you just set>,
     keyAlias=$ALIAS.
  2) For CI, add these GitHub secrets on the repo:
     ATLAS_UPLOAD_KEYSTORE_BASE64  = base64 of the .jks  (base64 -w0 "$OUT")
     ATLAS_UPLOAD_STORE_PASSWORD, ATLAS_UPLOAD_KEY_PASSWORD, ATLAS_UPLOAD_KEY_ALIAS
  3) Keep a backup of $OUT somewhere safe. Do NOT commit it.
NOTE
