# Android release signing (Play upload key)

The release build signs with a real **upload key** when one is configured,
and falls back to the debug key otherwise (so `flutter run --release` and
the plain CI APK build keep working without the key). The keystore and its
passwords are secrets: never commit them. `.gitignore` already excludes
`*.jks`, `*.keystore` and `android/key.properties`.

## One-time: make the upload key
```
bash tool/make_upload_key.sh         # writes ~/atlas-upload.jks
```
Keep the `.jks` and its password backed up somewhere safe. **Losing the
upload key means you cannot update the app on Play** (short of Google's key
reset). Google Play App Signing holds the real app-signing key; this upload
key only signs what you upload.

## Local signed build
Create `android/key.properties` from `android/key.properties.example`,
pointing `storeFile` at your `.jks`, then:
```
flutter build appbundle --release   # build/app/outputs/bundle/release/app-release.aab
```

## CI signed build (.github/workflows/android-release.yml, manual)
Add these repo **secrets** (Settings → Secrets → Actions):
- `ATLAS_UPLOAD_KEYSTORE_BASE64` = `base64 -w0 ~/atlas-upload.jks`
- `ATLAS_UPLOAD_STORE_PASSWORD`, `ATLAS_UPLOAD_KEY_PASSWORD`, `ATLAS_UPLOAD_KEY_ALIAS`

Then run the **"Android release (signed AAB)"** workflow; it produces the
`atlas-play-aab` artifact to upload to Play.

## Firebase security (push + analytics only)
The app uses Firebase for **Cloud Messaging and Analytics only** — it never
reads or writes Firestore, the Realtime Database or Storage from the client,
so there are no client-side database security rules to get wrong. The
`google-services.json` API key is a client identifier that ships in every
app; security must not depend on hiding it. The hardening that matters here:

1. **FCM send stays server-side.** Pushes are sent by the Atlas backend with
   its FCM server credential; the app only registers to receive. Keep that
   credential on the server, never in the app. (Backend concern.)
2. **Firebase App Check** (recommended) so only genuine, unmodified app
   instances can call Firebase backends:
   - Firebase Console → App Check → register the Android app with **Play
     Integrity** and the iOS app with **App Attest**.
   - Then add `firebase_app_check` to the app and call `activate()` at
     startup. Enforcement is a Console toggle, so the SDK can be added first
     and enforced later without breaking existing installs.
3. If a Firebase data product (Firestore/Storage/RTDB) is ever enabled,
   ship locked security rules **before** any client uses it — never leave
   the test/open default.
