# ملاحظات المراجعة للستور (مسودة)

## App Review Notes (Apple) — للصق في App Store Connect

Atlas is the learning app of academies hosted on the Atlas platform
(operated by CoreMind). A learner signs in to their own academy and
studies the courses they are enrolled in, plus free courses. The app
sells nothing: there are no purchases, prices or payment links in it.

Demo account (demo academy, sample courses):
- Academy: type `<DEMO_ACADEMY>` on the first screen, then "Open academy".
- Email: `<REVIEW_EMAIL>` / Password: `<REVIEW_PASSWORD>`
  (the account skips the emailed sign-in code).

To see the main features:
1. Home → "Resume lesson": a lesson; "Mark as done".
2. My courses → a course → its outline; a quiz (Start quiz) and an
   assignment (attach a photo).
3. Account → My results, My certificates (Open PDF), My notes.
4. Account → Privacy and data → "Delete my account" (in-app deletion).
5. Course reviews: each has "…" → Report (email to our support) / Hide.

Permissions, asked only when used: camera (QR code of an academy, a
photo for an assignment or profile), photos (the same), calendar (add a
due date, on request), Face ID (optional app lock), notifications.

During a monitored quiz the app blocks screenshots where the system
allows it and records leaving the app; learners are told this before
they start.

## Google Play — App access
نفس حساب الديمو والخطوات. Data safety: الاسم، الإيميل، رقم الموبايل، معرّف
المستخدم، معرّف الجهاز (للإشعارات)، الصور والملفات (الواجبات والصورة
الشخصية)، التفاعل مع التطبيق (Analytics). مفيش إعلانات ولا تتبّع.

## Google Play (تقرير play-policy-insights في docs/PLAY_POLICY_REPORT.md)
- targetSdk بقى 36 (Android 16): شرط Play للتطبيقات الجديدة من ٣١ أغسطس ٢٠٢٦.
- App access: حساب الديمو. Data safety: زي القايمة فوق.
- رابط ويب لحذف الحساب (مطلوب في نموذج Data safety).
- توقيع الإصدار: لسه بمفتاح debug؛ لازم upload key قبل الرفع (المرحلة ٩).

## قبل الإرسال (عليك)
- حساب ديمو حقيقي على أكاديمية الديمو، مفيش عليه كود دخول بالإيميل.
- في Apple Developer: تفعيل Push Notifications وSign in with Apple
  وApp Groups على الـ App ID (موجودين في `Runner.entitlements`).
- Associated Domains (`applinks:*.atlass.dpdns.org`) بعد ما يتحدد الـ Team ID.
- خانات الخصوصية في App Store Connect لازم تطابق `ios/Runner/PrivacyInfo.xcprivacy`
  (اتضاف رقم الموبايل).
- الالتزام بمراجعة بلاغات التقييمات خلال ٢٤ ساعة (التطبيق بيقول كده).

- توقيع أندرويد: مفتاح الرفع متظبط في `build.gradle.kts` (من `android/key.properties` أو أسرار CI). اعمل المفتاح بـ `tool/make_upload_key.sh`، والخطوات في `docs/RELEASE_SIGNING.md`. من غير المفتاح البناء بيرجع لمفتاح الديبَج (مش صالح للرفع).
- Firebase: التطبيق بيستخدم الإشعارات والتحليلات بس (مفيش Firestore/Storage/DB من العميل)، فمفيش قواعد أمان على جهة الموبايل. مفتاح الـ FCM للإرسال لازم يفضل على السيرفر. يُنصح بتفعيل App Check من Console (التفاصيل في `docs/RELEASE_SIGNING.md`).