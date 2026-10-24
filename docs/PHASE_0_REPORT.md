# المرحلة 0 — التقرير

> 24 أكتوبر 2026. Flutter 3.47.7 (Dart 3.13.5)، مثبّت في CI.
> كل الاختبارات اتعملت على **نسخة محلية** من الباك اند (`scripts/e2e-local-stack.sh`،
> نفس الـ migrations والـ seed). على production عملت **قراءات عامة بس** (من غير حساب).

## النتيجة

**نموذج الـ session بتاع Atlas شغال في Flutter من غير أي تعديل في الباك اند.**
كل المخاطر التقنية الكبيرة اللي في البلان اتجرّبت، وكلها عدّت، ما عدا اللي محتاج موبايل
حقيقي (تحت).

| التجربة | النتيجة | الدليل |
|---|---|---|
| Cookie jar: `atlas_session` و`atlas_device` و`atlas_known` بيتحفظوا من `Set-Cookie` | ✅ | `test/integration/session_spike_test.dart` |
| Refresh **من غير** `Origin` | ❌ 403 `errors.auth.crossOriginSession` (متوقع) | نفس الملف |
| Refresh **مع** `Origin` = origin الأكاديمية | ✅ والـ cookie بيتغيّر (rotation) | نفس الملف |
| استرجاع الجلسة بعد "إعادة تشغيل" (client جديد على نفس الـ jar) | ✅ `POST /auth/refresh` بيرجّع الـ user | نفس الملف |
| Access token منتهي ← refresh تلقائي وإعادة الطلب مرة واحدة | ✅ | نفس الملف |
| 10 refresh في نفس اللحظة | ✅ طلب واحد، والجلسة فضلت شغالة | نفس الملف |
| تسجيل الخروج: الـ cookie اتمسح والـ refresh بعده 401 | ✅ | نفس الملف |
| كود الإيميل (`FLAG_AUTH_EMAIL_OTP_MODE_ACADEMY=new_device`) | ✅ challenge من غير token، والتحقق ← جلسة + `atlas_trust` | `email_code_spike_test.dart` |
| جهاز اتعلّم عليه "افتكرني" ← مفيش كود المرة الجاية | ✅ | نفس الملف |
| التسجيل قبل تأكيد الإيميل | ✅ الدخول مسموح | curl + الاختبارات |
| فتح درس مقفول | ❌ 403 `errors.learning.lessonLocked` (متوقع: `previousIncomplete`) | `lesson_grant_spike_test.dart` |
| Grant لدرس YouTube | ✅ `externalEmbed {provider: youtube, videoId}` + `watermark {code, maskedIdentity}` + `playbackLease {leaseId, ttlSeconds: 60, heartbeatSeconds: 20}` | نفس الملف |
| Heartbeat | ✅ `leaseHeld: true` | نفس الملف |
| اسم الجهاز من الـ UA (`AtlasApp/… (iPhone; …)`) | ✅ "iOS" في صفحة الأجهزة | نفس الملف |
| Production: Cloudflare مع UA التطبيق | ✅ 200 | curl |
| Production: Google sign-in | مقفول (`{"google":false}`) | curl `auth/options` |
| Production: `/.well-known/apple-app-site-association` | بيرجّع HTML الموقع ← محتاج W4 | curl |

## اللي اتبنى

| الملف | الدور |
|---|---|
| `lib/core/api/academy_endpoint.dart` | origin الأكاديمية، وقيمة `Origin` بالظبط زي ما الباك اند بيقارنها |
| `lib/core/api/atlas_api_client.dart` | Dio + cookie jar + `Origin` على `auth/refresh` و`auth/sign-out` بس + Bearer + refresh واحد في نفس الوقت + إعادة الطلب مرة على 401 |
| `lib/core/api/secure_cookie_storage.dart` | الـ cookies في Keychain/Keystore |
| `lib/core/api/api_error.dart` | `NormalizedApiError` ← exception واحدة |
| `lib/core/auth/auth_repository.dart` | sign-in، والكود، والتسجيل، والاسترجاع، والخروج (نفس حقول الـ DTOs بالظبط) |
| `lib/features/player/watermark_overlay.dart` | الـ watermark بنفس قواعد الويب: label بيتحرك كل 20–45 ثانية بـ dim 350ms، وtile ‎−24° 280×160 بيتحرك كل 90 ثانية، ومش بياخد لمس، ومخفي عن قارئ الشاشة، وبيحترم reduce motion |
| `lib/features/player/youtube_embed_html.dart` | الـ embed على `youtube-nocookie.com`، و`fs=0` و`playsinline=1`، وorigin الأكاديمية، وقائمة navigation مسموحة (مفيش خروج لـ youtube.com) |
| `lib/features/player/playback_session.dart` | الـ lease والـ heartbeat والـ release والإبلاغ عن العبث (`learning/watermarks/tamper`) |
| `lib/features/player/youtube_lesson_player.dart` | WebView + overlay + إيقاف في الخلفية + حماية الشاشة |
| `lib/core/platform/screen_protection.dart` + `MainActivity.kt` + `ScreenProtectionPlugin.swift` | Android `FLAG_SECURE`. iOS كشف التسجيل والـ mirroring والـ screenshot (iOS مايقدرش يمنع التسجيل) |
| `lib/spike/spike_app.dart` | **شاشة تجربة بس** (هتتشال في المرحلة 2) |
| `.github/workflows/ci.yml` | format + analyze + test + APK على Linux، و`flutter build ios --no-codesign` على macOS |
| `tool/local_stack/force_otp_code.mjs` | للنسخة المحلية بس: بيحط كود معروف للاختبارات، وبيرفض أي داتابيز مش على 127.0.0.1 |

## اللي لسه محتاج موبايل حقيقي

مقدرش أجرّبهم هنا (Linux من غير emulator):

1. **YouTube جوه WebView** بـ base URL الأكاديمية: الفيديو بيشتغل؟ ولا YouTube بيرفض الـ embed
   (error 152/153)؟
2. **الـ watermark فوق الفيديو** في الوضع العادي.
3. **FLAG_SECURE**: screenshot أو تسجيل الشاشة على Android لازم يطلع أسود.
4. **iOS**: لما تسجيل الشاشة يبدأ، الفيديو يقف ويتغطّى.
5. **الـ cookies على production** (`__Host-atlas_session` مع `Secure`) من Dio.

**إزاي:** نزّل `app-arm64-v8a-release.apk` من CI (أو من الملف اللي هبعته) على أي موبايل
Android، وادخل على `ziadd.atlass.dpdns.org` بحساب طالب، وافتح درس YouTube. iOS هيستنى الماك أو
TestFlight في المرحلة 9.

## ملاحظات للمراحل الجاية

- بيئة الـ sandbox: Maven Central بيرد 429، فاتعمل mirror على مستوى البيئة بس
  (`~/.gradle/init.d`)، مش في الريبو. CI على GitHub مش محتاجه.
- `deriveDeviceLabel` بيطلّع "iOS" أو "Android". B7 هيخليها "Atlas app on iPhone".
- الـ heartbeat بيقف على 403/409. محتاجين نتأكد من الـ status الحقيقي لما جهاز تاني ياخد الجلسة
  (takeover) في المرحلة 3.
- كلام الشاشات في `spike_app.dart` و`youtube_lesson_player.dart` إنجليزي مؤقت، وهيتحوّل
  لـ l10n عربي وإنجليزي في المرحلة 2.
