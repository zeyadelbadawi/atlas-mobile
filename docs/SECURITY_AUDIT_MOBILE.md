# Mobile security audit (Atlas app)

Date: 6 November 2026. Scope: the mobile repo only (Dart `lib/`, Android,
iOS). No backend or web review. Method: OWASP MASVS v2.1.0 / MASTG
(`mobile-code-review` skill), dependency CVEs (`sca-audit` + OSV.dev),
secret scan (`secrets-scan`), Semgrep (Dart/Kotlin/Swift, security-audit +
secrets rules), and a manual review of the auth, network, storage, deep
link, WebView and platform-channel surface.

## Result: clean overall, six hardening fixes applied

No critical or high issues. No hardcoded secrets. No known CVEs across 203
Dart packages; no git/path dependencies; no dependency overrides. Semgrep
found nothing in Dart, Kotlin or Swift.

### Fixed (all mobile-only, no backend/web change)

| # | Area (MASVS) | Severity | Finding | Fix |
|---|---|---|---|---|
| 1 | PLATFORM | Medium | A home-screen widget tap and an app-icon shortcut navigated with `router.go(path)` using a path from the `atlaswidget://` URL scheme, which any app on the phone can invoke (CWE-939). An external app could push the app to an arbitrary screen. | `lib/app/launch_paths.dart`: an allowlist (`safeLaunchPath`) of the exact paths the app itself emits; the widget and shortcut handlers navigate only to those. |
| 2 | PLATFORM | Low–Med | The lesson WebView's navigation allowlist compared the academy origin with `uri.toString().startsWith(origin)`, so `https://<academy>.evil.com` passed (CWE-20). | `youtube_embed_html.dart`: compare scheme + host + port, not a string prefix. |
| 3 | NETWORK | Low | `AcademyEndpoint.parse` and `parseAcademyLink` accepted `http://`, so a QR code or link could point the app at a cleartext origin (CWE-319). | Release builds require `https` (loopback and debug/profile aside), so a scanned or pasted academy link can't downgrade the session. |
| 4 | STORAGE | Medium | Android `allowBackup` was unset (defaults on): app data (prefs, caches, the Keystore-wrapped session) was eligible for cloud backup and device-to-device transfer (CWE-530). | `allowBackup=false` + `backup_rules.xml` (Android ≤11) + `data_extraction_rules.xml` (12+) excluding all app data from cloud backup and transfer. |
| 5 | STORAGE | Low | The secure cookie/session store used default accessibility. | iOS Keychain accessibility `first_unlock_this_device`: the session is never in an iCloud or transfer backup and is readable only after the first unlock since boot. (Android is Keystore-encrypted by default.) |
| 6 | PRIVACY | Low | `debugPrint` stays active in release, so error detail could reach the device log (CWE-532). | `main.dart`: `debugPrint` is silenced in release builds. |

### Positive observations (kept as-is)

- Session design: the 15-minute access token lives only in memory; the
  refresh token is an HttpOnly cookie kept in the Keystore/Keychain-backed
  secure store; refresh and sign-out carry an `Origin` header; refresh is
  single-flight with rotation/theft handling.
- No TLS override anywhere (no `badCertificateCallback`), no cleartext
  endpoints, iOS ATS left at its secure default.
- Minimal Android permissions; the advertising ID is removed; receivers are
  not exported; App Links use `autoVerify`.
- Push deep links go through a strict allowlist (`appPathForWebLink`).
- The lesson WebView restricts navigation to YouTube hosts and the academy
  origin, with a single minimal JS channel.
- Quiz/lesson screens block screenshots and screen capture where the OS
  allows it (earlier work).

### Noted, not code-fixable here (for the store/release step)

- The release build still signs with debug keys (`build.gradle.kts`); a real
  upload key is needed before shipping (already in STORE_REVIEW_NOTES).
- `android/app/google-services.json` carries the Firebase client API key.
  That is a client identifier by design, not a secret to rotate — but
  Firebase security must rest on server rules / App Check, never on the key
  being hidden.
- `.gitignore` now should keep signing keys out (added).

## Tools installed for this audit

OWASP `mobile-code-review`, `sca-audit`, `secrets-scan` (CC-BY, instructions
+ the MASVS/MASTG data), and Trail of Bits `semgrep` (vetted: forces
`--metrics=off`, clones only validated https rule repos, approval-gated).
