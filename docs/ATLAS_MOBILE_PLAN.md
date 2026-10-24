# Atlas Mobile — خطة تطبيق الطلاب (النسخة 2)

> آخر تحديث: 24 أكتوبر 2026.
> مبنية على قراءة `atlas` (الفرونت) و`atlas-backend` لحد آخر commit في 24 أكتوبر.
> النسخة 1 كانت مسودة. النسخة دي بعد قراراتك.

---

## 0. القرارات اللي اتاخدت

| القرار | الاختيار |
|---|---|
| مين الأول | **تطبيق الطلاب** كامل. تطبيق الإدارة بعده، في خطة لوحده |
| شكل التطبيق | **تطبيق Atlas واحد** لكل الأكاديميات. الطالب يختار أكاديميته |
| الشراء | **مفيش شراء في التطبيق.** بيعرض الكورسات اللي الطالب مسجّل فيها، والكورسات المجانية اللي يقدر يسجّل فيها |
| Push notifications | **لازم.** هتتعمل في الباك اند كإضافة |
| Sign in with Apple | **لازم** على iOS |
| تعديل الباك اند | مسموح، بشرط إنه **إضافة بس** ومايأثرش على الويب (§4) |
| حسابات Apple / Google Play | **آخر مرحلة خالص**، بعد ما التطبيق يخلص (§10، المرحلة 9) |
| التقنية | **Flutter** (السبب في §2) |
| الديزاين | اسكيلز Impeccable وEmil Kowalski، متسطّبة في الريبو (§8) |

---

## 1. الخلاصة

تطبيق Flutter واحد لـ iOS وAndroid (وiPad). الطالب يختار أكاديميته برابط أو QR أو deep link.
يقدر يعمل كل اللي بيعمله في صفحة `/my` على الويب، ما عدا الشراء: الدروس، والكويزات،
والواجبات، والنتائج، والشهادات، والإشعارات، والإعلانات، والمنتدى، والبروفايل، والأجهزة،
وحذف الحساب.

الباك اند هيتضاف له 7 حاجات. كلها جداول وendpoints جديدة، وورا feature flags مقفولة
افتراضياً. مفيش endpoint موجود هيتغيّر شكل الـ response بتاعه، ومفيش سلوك للويب هيتغيّر.

أكبر مخاطرتين:
1. **سياسة Apple** إن التطبيق يفتح كورسات اتشرت برّه (§6).
2. **الماك Intel** بتاعك ممكن مايشغّلش نسخة Xcode اللي Apple بتطلبها للرفع (§2.2). الحل
   build على macOS في CI.

---

## 2. التقنية: Flutter

### 2.1 ليه Flutter

- **انت فاهم فيه**، وانت اللي هتصون التطبيق بعد كده. ده أهم سبب.
- كود واحد لـ iOS وAndroid وiPad. الـ RTL والعربي فيه ممتازين.
- **أهم نقطة تقنية بتكسب فيها Flutter:** الـ session في Atlas معتمدة على cookies (§3).
  في Dart عندنا تحكّم كامل في الـ HTTP عن طريق `dio` + `cookie_jar`: نقرأ الـ `Set-Cookie`
  بنفسنا، نخزّنها مشفّرة، ونبعت `Origin` header. في React Native الـ cookie store native
  ومقفول، وإرسال `Origin` على iOS مش مضمون.
- الخسارة الوحيدة: مش هنقدر ننسخ الـ TypeScript types من الفرونت. الحل: نولّد الـ models
  من OpenAPI بتاع الباك اند (`/api/docs` في غير production) لما يكون ممكن، ونكتب الباقي
  بإيدينا. وعندنا contract tests بتجرّب التطبيق على backend محلي حقيقي (§11).

### 2.2 بيئة الشغل — تصحيح مهم

- **أنا مش على ماك، ومعنديش iOS simulator.** السيشن دي Linux x86 في السحابة، ومن غير
  KVM، فمفيش Android emulator كمان. اللي أقدر أعمله هنا:
  - `flutter analyze` وunit/widget/golden tests (عربي وإنجليزي، light/dark، خط مكبّر،
    مقاسات iPhone وiPad).
  - integration tests لطبقة الـ API على نسخة محلية من الباك اند
    (`scripts/e2e-local-stack.sh`).
  - build لـ Android APK/AAB.
  - تشغيل التطبيق كـ Flutter web وأخد screenshots للـ layout.
  - كل شغل الباك اند والتستات بتاعته.
- **iOS لازم يتبني ويتجرّب على ماك:** يا الماك بتاعك، يا macOS runners في GitHub Actions
  (أو Codemagic).
- **الماك Intel:** من 28 أبريل 2026 Apple مش بتقبل غير apps متبنية بـ Xcode 26 وiOS 26
  SDK. حسب مصادر غير رسمية: Xcode 26.0 محتاج macOS 15.6، وXcode 26.4 وأعلى محتاج macOS
  Tahoe 26.2، وTahoe هو آخر macOS بيدعم Intel، ولموديلات قليلة بس. **محتاج أعرف موديل
  الماك ونسخة الـ macOS.** لو مش هينفع، الـ builds والرفع على TestFlight يتعملوا من CI على
  macOS، والماك بتاعك للتجربة بس.

### 2.3 المكتبات (النسخ تتحدد وقت الـ scaffold على آخر stable)

| الغرض | المكتبة |
|---|---|
| State / DI | `flutter_riverpod` |
| Routing + deep links | `go_router`, `app_links` |
| HTTP + cookies | `dio`, `cookie_jar`, `dio_cookie_manager` (مع storage مشفّر) |
| تخزين آمن | `flutter_secure_storage` |
| Models | `freezed`, `json_serializable` |
| ترجمة | `flutter_localizations` + ARB (نحوّل ملفات `en/ar` الموجودة في الفرونت بـ script) |
| Push | `firebase_messaging` (FCM لـ Android، وAPNs عن طريق FCM لـ iOS)، `flutter_local_notifications` |
| Sign in with Apple | `sign_in_with_apple` |
| Google (لو مفعّل) | `google_sign_in` |
| YouTube | `webview_flutter` (iframe على `youtube-nocookie.com` زي الويب بالظبط) |
| حماية الشاشة | platform channel صغير: `FLAG_SECURE` على Android، و`UIScreen.isCaptured` + إشعار screenshot على iOS |
| ملفات | `image_picker`, `file_picker`, عارض PDF للشهادات |
| QR | `mobile_scanner` |
| Crash reporting | `sentry_flutter` (الباك اند بيستخدم Sentry أصلاً) — بموافقة المستخدم |
| شبكة / نسخة | `connectivity_plus`, `package_info_plus` |

---

## 3. اللي فهمته من المشروع (الأجزاء اللي تهم الموبايل)

| الموضوع | الحالة في الكود | أثره على التطبيق |
|---|---|---|
| Multi-tenant | Organization ← Academies. كل أكاديمية ليها `{slug}.atlass.dpdns.org` أو custom domain | الـ base URL لكل أكاديمية = `https://<host>/api/v1` |
| تحديد الأكاديمية | من `request.hostname` (`hostAcademyId`, `assertSessionServesHostAcademy`) | مفيش backend جديد، بنكلّم host الأكاديمية |
| Resolve | `GET /public/websites/resolve?hostname=` + `/:academyId/identity`, `/logo` | شاشة اختيار الأكاديمية والهوية (اللوجو والألوان) |
| Sessions | Access token مدته 15 دقيقة في الـ body. الـ refresh token في cookie `__Host-atlas_session` **بس** (HttpOnly, Secure, SameSite=Strict) | cookie jar لكل host، متخزّن مشفّر |
| CSRF | `/auth/refresh` و`/auth/sign-out` بيطلبوا `Origin` = نفس الـ host | التطبيق يبعت `Origin: https://<host>`. الشرط ده معمول عشان المتصفح، والكود نفسه بيقول إن أي client غير المتصفح بيبعت اللي هو عايزه |
| Rotation | Reuse detection + `SupersededRefreshTokenException` | refresh واحد بس في نفس الوقت (mutex) |
| Refresh | من 22 أكتوبر `POST /auth/refresh` بيرجّع الـ user | round trip أقل عند فتح التطبيق |
| Sign-in | `surface: 'academy'` + `academyId`. Email OTP حسب `FLAG_AUTH_EMAIL_OTP_MODE_ACADEMY` (الافتراضي `off`، وقيمته في production مش باينة لي). `atlas_trust` cookie للأجهزة الموثوقة | شاشات login وOTP. **وحساب الديمو بتاع Apple محتاج حل (§4، B3)** |
| Google | `FLAG_AUTH_GOOGLE_MODE` (الافتراضي `off`)، flow بـ redirect على الويب | لو مفعّل في production: محتاجين Google native ← وده بيخلّي Sign in with Apple إجباري (Guideline 4.8) |
| الأجهزة | `atlas_device` cookie = جهاز. `/learning/devices`، `/learning/session/takeover` | التطبيق = جهاز واحد، وشاشة device limit |
| الفيديو | **YouTube** على `youtube-nocookie.com`. الـ hosted tiers مبنية بس مش متفعّلة | WebView + watermark فوقه |
| Watermark | كود لكل مشاهد، fail-closed (503). label بيتحرك كل 20–45 ثانية، وtile خفيف، وwatchdog | نبنيه native بنفس القواعد بالظبط |
| Playback | `POST learning/courses/:id/playback`, `/release`, `/lessons/:id/playback/refresh` | heartbeat، وrelease لما التطبيق يروح background |
| Quiz integrity | events `visibility_*`, `blur/focus`, `fullscreen_*`, `copy/paste` | AppState ← `visibility_*`. والـ full-screen طبيعي على الموبايل |
| Notifications | قنوات `email` و`in_app` بس. **مفيش push** | B1 |
| Unsubscribe | الـ campaigns فيها `List-Unsubscribe` + one-click. التفضيلات في `notifications/preferences` | شاشة تفضيلات في التطبيق + نتأكد من رابط التفضيلات في كل إيميل غير ضروري |
| حذف الحساب | `users/me/deletion-plan`, `/delete/request`, `/delete` | موجود ✔ |
| طلبات الخصوصية | `privacy-requests` (code، create، mine، export) | تصدير البيانات من التطبيق ✔ |
| القانوني على الويب | `/privacy-policy` و`/terms` (EN/AR) + cookie banner + preferences | مفيش refund policy ولا cookie policy منفصلين ← §5 |
| Errors | `NormalizedApiError` + `messageKey` | نفس ملف `errors.json` |
| Validation | `forbidNonWhitelisted` | الـ requests لازم تطابق الـ DTOs بالظبط |

ملاحظة: الـ help center والماركتنج بيقولوا حالياً "مفيش mobile app" (`content/docs/en/faq/general.md`,
`reference/browsers-and-devices.md`, `marketing/launch-kits/*`، وفيه اختبارات
compliance على كلام الماركتنج). لازم يتحدّثوا **وقت الإطلاق**، مش قبله.

---

## 4. تعديلات الباك اند (إضافة بس)

### 4.0 قواعد ماتتكسرش

1. **مفيش تغيير في شكل أي response موجود** إلا حقول إضافية اختيارية، وبعد ما نتأكد إن
   الفرونت مش بيستخدم strict parsing على الـ response ده.
2. كل حاجة جديدة **ورا flag مقفول افتراضياً**. والـ env vars الجديدة اختيارية: الباك اند
   يقوم عادي من غيرها.
3. الـ migrations **إضافة بس**: جداول جديدة، أو قيمة enum جديدة (`ADD VALUE`)، أو أعمدة
   nullable. مفيش rename ولا drop. وكل جدول جديد عليه **FORCE RLS** وself-only، وأي قراءة
   بين الـ scopes تكون definer function بـ `REVOKE`/`GRANT` (handover §3).
4. أي route جديد يتسجّل في **public-route inventory** و**subscription-scope inventory**.
5. e2e لكل route: مين يقدر ومين مايقدرش (طالب أكاديمية تانية، session على surface غلط...).
6. ترتيب الإطلاق اللي في الـ handover: merge الباك اند ← dispatch `Deploy` بـ
   `apply_migrations=true` **بموافقتك** على `production-migrations` ← بعدين أي حاجة في الفرونت.
7. lint وtypecheck وunit وe2e المتأثرة كلهم يعدّوا قبل أي push. ومفيش push على `main`،
   كله على branch + PR.

### 4.1 الإضافات

| # | الإضافة | التفاصيل | Migration | Flag |
|---|---|---|---|---|
| **B1** | **Push notifications** | جدول `push_devices` (user, platform, token unique, app_version, locale, academy_id, session_id, last_seen, revoked_at)، FORCE RLS self-only. `PUT /users/me/push-devices` تسجيل/تحديث مربوط بالـ session الحالي والأكاديمية. `DELETE /users/me/push-devices/current`. الـ token يتلغي تلقائي مع sign-out، وإلغاء السيشن، وحذف الحساب، وعند رد FCM بـ `UNREGISTERED`. **الإرسال:** بعد ما صف الـ in-app notification يتكتب ويحصل commit، job في BullMQ يبعت عن طريق FCM HTTP v1، **لأجهزة الطالب اللي على نفس أكاديمية الإشعار بس** (عزل الإشعارات ADR-5 زي ما هو). الـ payload فيه العنوان والنص المترجم من نفس الـ catalog + `notificationId` + deep link، ومفيش أي بيانات حساسة. بيحترم تفضيلات الطالب، ويتضاف تفضيل push لكل category (حقل إضافي بس) | جدول جديد | `FLAG_PUSH_MODE=off` + `FCM_*` اختيارية |
| **B2** | **Sign in with Apple** | `AuthIdentityProvider` + `apple`. `POST /auth/apple/native { identityToken, authorizationCode, nonce, fullName? }` على host الأكاديمية. التحقق من الـ token بـ Apple JWKS (iss, aud = bundle id, nonce, exp). وبعدها **نفس pipeline بتاع Google** (`continueSignIn`): link_required / create_account / OTP / session. حفظ الـ Apple refresh token مشفّر، و**revoke عند حذف الحساب** (Apple بتطلبه). email الـ private relay مقبول، ومحتاجين نسجّل دومين الإرسال (Brevo/Resend) عند Apple عشان الإيميلات توصل | قيمة enum + جدول/أعمدة للـ token | `FLAG_AUTH_APPLE_MODE=off` |
| **B2b** | Google native (لو Google مفعّل في production) | `POST /auth/google/native { idToken }` بـ aud = mobile client IDs، ونفس الـ pipeline | — | تحت `FLAG_AUTH_GOOGLE_MODE` |
| **B3** | **دخول App Review (حساب الديمو)** | لو الـ OTP مفعّل، المراجع هيقف عند كود إيميل مش هيوصله. الحل: env `APP_REVIEW_ACCOUNTS` (فاضي افتراضياً) فيها emails بعينها، والـ OTP يتخطّى ليهم **على surface `academy` وفي أكاديمية الديمو بس**. حسابات ملهاش أي صلاحيات ولا فلوس، وكل استخدام بيتسجّل في الـ audit log | — | env فاضي = مقفول |
| **B4** | **سجل الموافقات (السن والشروط)** | جدول `user_consents` (user, kind: terms / privacy / age_confirmation / guardian_consent, version, source: web/ios/android, at). حقل `consents` **اختياري** في `POST /auth/register` (الويب مش بيبعته فمش هيتأثر)، و`POST /users/me/consents` للحسابات الموجودة | جدول جديد | — |
| **B5** | **إعدادات التطبيق والتحديث الإجباري** | `GET /public/mobile/config` ← أقل نسخة مدعومة، آخر نسخة، روابط الستور، رسالة صيانة. لما نسخة قديمة تكسر، الطالب يشوف شاشة "حدّث التطبيق" بدل ما التطبيق يبوظ | — | — (public route مسجّل) |
| **B6** | **الإبلاغ والحظر في المنتدى** (Apple 1.2 لأي محتوى من المستخدمين) | `POST courses/:id/forum/threads/:threadId/report`، و`.../replies/:replyId/report`. حظر مستخدم من عندك (`user_blocks` self-only) فمحتواه يختفي عندك. البلاغات بتوصل لستاف الأكاديمية كإشعار in-app. ومحتاجين صفحة بلاغات للإدارة **على الويب** (إضافة) | جدولين جدد | `FLAG_FORUM_REPORTS=off` |
| **B7** | اسم الجهاز | `deriveDeviceLabel` يتعرّف على `AtlasApp/` في الـ UA ← "Atlas app on iPhone". إضافة صغيرة | — | — |

**مش هيتغيّر:** طريقة الـ sessions والـ cookies، والـ CSRF، والـ watermark، والـ grants، والـ
RLS الموجودة، وأي route موجود.

---

## 5. تعديلات الويب (إضافة بس — محتاجة موافقتك)

| الإضافة | ليه |
|---|---|
| `/refund-policy` و`/cookie-policy` (EN/AR) | انت طلبتهم، والستورات بتشوف روابطهم |
| تحديث `/privacy-policy` بقسم للتطبيق | push tokens، وdevice id، وcrash reports بموافقة، وSign in with Apple، وحذف الحساب |
| صفحة ويب لحذف الحساب `/account-deletion` | **Google Play بيطلب رابط ويب** لحذف الحساب، مش من جوه التطبيق بس |
| `/.well-known/apple-app-site-association` و`assetlinks.json` على hosts الأكاديميات (Caddy) | Universal Links / App Links: روابط الإيميلات تفتح التطبيق |
| صفحة بلاغات المنتدى للإدارة | B6 |
| الـ help center والـ FAQ والماركتنج: "فيه تطبيق" | **وقت الإطلاق بس** |

> **نصوص السياسات:** هكتب مسودات من السياسات الموجودة ومن سلوك الكود الحقيقي. **لازم محامي
> يراجعها** قبل النشر، ومحتاج منك بيانات الشركة (§12).

---

## 6. الشراء والسياسات

- التطبيق **مفيهوش**: أسعار، ولا زرار شراء، ولا "ادفع على الموقع"، ولا روابط دفع.
- بيعرض: كورساتي (سواء اتشرت على الويب أو اتسجلت مجاناً) + كتالوج **الكورسات المجانية بس**
  مع تسجيل مباشر (`POST /enrollments`). الكورسات المدفوعة اللي الطالب مش مسجّل فيها **مش
  بتظهر خالص**.
- **Restore purchases:** مش مطلوب لأن مفيش IAP. ولازم نتأكد إن مفيش أي UI يوحي بشراء.
- **المخاطرة اللي فاضلة:** Apple (3.1.1 / 3.1.3(b)) ممكن تعتبر فتح كورس مدفوع اتشرى برّه
  محتاج IAP. ده نمط شائع في تطبيقات منصات الكورسات، **بس مش مضمون**. هنكتب App Review
  notes واضحة: التطبيق مش بيبيع حاجة، وكل أكاديمية بتتعامل مع طلابها مباشرة. **لو اترفض:**
  البديل IAP، وده تعديل backend كبير وApple بتاخد 15–30%، وقرار تجاري ليك.
- Google Play: نفس الموقف تقريباً، ونراجع سياسة Payments قبل الرفع.

---

## 7. Checklist المراجعة (App Store + Google Play)

كل بند ليه **تنفيذ** و**إزاي نتأكد منه**. ده الـ gate بتاع المرحلة 8.

| البند | التنفيذ | التحقق |
|---|---|---|
| Privacy Policy | شاشة في التطبيق + رابط في الستور + رابط في التسجيل | الرابط شغال EN/AR |
| Terms of Service | نفس الكلام + موافقة صريحة عند التسجيل (B4) | الموافقة متسجّلة بالنسخة |
| Refund / Return Policy | صفحة + لينك في الإعدادات (توضّح إن الاسترداد بيتم مع الأكاديمية، وده موجود في `course-orders/:id/refund`) | — |
| Cookie Policy | صفحة + لينك | — |
| Consent banner / شاشة الموافقة | أول تشغيل: شاشة خصوصية. **الضروري** (السيشن والجهاز) موضّح ومش محتاج موافقة. **الاختياري** (crash reports) مقفول افتراضياً، وزرار "رفض" بنفس حجم "موافقة". ومفيش tracking عبر التطبيقات، فمفيش ATT | مفيش SDK بيبعت أي حاجة قبل الموافقة |
| No unnecessary data | مفيش location ولا contacts ولا IDFA. الكاميرا والصور وقت رفع ملف بس، والإشعارات بعد شرح | permission strings واضحة EN/AR، وPrivacy manifest، وData safety |
| Dark patterns | مفيش countdowns ولا urgency ولا checkboxes متعلّمة مسبقاً، والإلغاء والرفض واضحين، وحذف الحساب سهل يتلاقي | مراجعة كل شاشة بالـ checklist |
| Hidden features | مفيش debug menus ولا features بتتفتح بعد الـ review. الـ flags بتاعة الأكاديمية محتوى مش features | build الـ release مفيهوش dev tools |
| Fake reviews | مفيش ratings ولا تقييمات متألّفة في التطبيق ولا الـ screenshots، وأي تقييم بيظهر جاي من الباك اند حقيقي | — |
| Color contrast | tokens بـ 4.5:1 للنص و3:1 للعناصر، light وdark، **ومع ألوان الأكاديمية** (لو اللون ضعيف نعدّل الدرجة تلقائي) | test على كل token + أسوأ ألوان أكاديميات |
| Accessibility | VoiceOver/TalkBack labels، وDynamic Type لحد 200%، ولمس 44pt/48dp، وreduce motion، وترتيب focus، وRTL | golden tests بـ text scale 2.0 + جرد يدوي |
| Alt text | كل صورة ليها `semanticLabel` (غلاف الكورس = اسمه، اللوجو = اسم الأكاديمية)، والزخرفية `excludeFromSemantics` | — |
| Business details | شاشة "عن التطبيق": الشركة والعنوان والإيميل والموقع، + بيانات تواصل الأكاديمية. ومعلومات الـ trader في الستور (EU DSA) | — |
| Age / بيانات الأطفال | التسجيل فيه تأكيد سن: "عندي 13 سنة أو أكتر، أو عندي موافقة ولي أمري" + سجل (B4). مش في Kids category. وage rating بالـ questionnaire الجديد | محتاج قرارك في سياسة السن (§12) |
| Unsubscribe في الإيميلات | الـ campaigns فيها one-click. نتأكد إن كل إيميل غير ضروري فيه رابط التفضيلات، والإيميلات الأمنية (OTP، reset) بتفضل | جرد لـ `COMMUNICATIONS_EMAIL_NOTIFICATION_CATALOG.md` |
| Data deletion request | طلب تصدير/حذف (`privacy-requests`) من التطبيق + صفحة ويب | — |
| Delete account | من الإعدادات ← خطوتين ← تأكيد. مع Apple token revoke (B2) | e2e |
| **Sign in with Apple** | B2 + زرار بتصميم Apple الرسمي، فوق أو بنفس مستوى أي login تاني | — |
| **iPad** | layouts حقيقية: sidebar + master/detail، وplayer أفقي، وكل الـ orientations، وSplit View وSlide Over | goldens على iPad mini و11" و13" + تجربة على ماك/CI |
| **Demo login** | أكاديمية "Atlas Demo Academy" ببيانات تجريبية حقيقية (كورسات YouTube، كويز، واجب، شهادة، إعلانات، منتدى) + حساب طالب بـ B3 + رابط وQR في الـ review notes | نجرّب الدخول من جهاز جديد خالص قبل كل submission |
| **Restore purchases** | مش مطلوب (مفيش IAP)، ومفيش أي UI شراء | — |
| **Coming soon screens** | **ممنوعة** (Apple 2.1 بترفض placeholders). أي feature مش جاهزة مابتظهرش خالص، زي live sessions لما الـ add-on مقفول | بحث في الكود عن "coming soon" والشاشات الفاضية |
| **Outdated screens** | مفيش screens بكلام قديم أو "beta" أو test. الـ screenshots في الستور من آخر build، وشاشة تحديث إجباري (B5) | — |
| الحماية والـ watermark | Watermark زي الويب + `FLAG_SECURE` + كشف التسجيل | — |
| شغال من غير نت | رسائل واضحة، ومفيش crash. مفيش تحميل فيديو | — |
| IPv6 / شبكات ضعيفة | Apple بتراجع على IPv6. timeouts وretry | — |

---

## 8. الديزاين

- **الاسكيلز متسطّبة** في `atlas-mobile/.claude/skills/` (عشان تفضل في أي session جاية):
  - **Impeccable**: `/impeccable init` (بيكتب `PRODUCT.md`) و`/impeccable polish` و`audit`
    و`critique`. بيغطي شاشات iOS وAndroid native.
  - **Emil Kowalski**: `emil-design-eng`، `apple-design`، `animate`، `review-animations`،
    `break-ui` (بيانات أسوأ حالة: أسماء طويلة، عربي، أرقام كبيرة)، `animation-performance`.
  - تنبيه: معظم اسكيلز Emil مكتوبة لـ web/React Native. هنستخدم المبادئ (المدد، الـ springs،
    إمتى نعمل animation وإمتى لأ)، ونطبّقها بـ Flutter animations.
- **Design system:** tokens للألوان والمسافات والخطوط والـ radius والحركة، ودعم ألوان
  الأكاديمية مع ضبط الـ contrast تلقائي، وخط عربي مناسب، وdark mode، وRTL من الأول.
- ممكن نستلهم من الفرونت (themes `modern-education`، `manara`، `riwaq`)، بس التطبيق بيتبع
  أنماط iOS/Android، مش نسخة من الموقع.
- كل شاشة: `/impeccable polish` + `break-ui` + `review-animations` قبل ما تتقفل.

---

## 9. نطاق تطبيق الطلاب (كامل)

| المجموعة | الشاشات | Endpoints |
|---|---|---|
| البداية | splash، تحديث إجباري (B5)، شاشة الخصوصية أول مرة، اختيار الأكاديمية (رابط، QR، deep link، آخر أكاديميات) | `public/websites/resolve`, `:id/identity`, `/logo`, `public/mobile/config` |
| الدخول | login، Sign in with Apple، Google (لو مفعّل)، OTP، تسجيل جديد (الموبايل إجباري + السن + الشروط)، الانضمام بحساب موجود، نسيت الباسورد، تأكيد الإيميل | `auth/*`, `auth/otp/*`, `auth/apple/native` |
| الرئيسية | overview، استكمال آخر درس، المواعيد (كويزات وواجبات) | `learning/overview`, `learning/quizzes`, `learning/assignments` |
| كورساتي | القائمة، التفاصيل، التقدّم، المنهج | `enrollments`, `courses/:id`, `courses/:id/progress`, `learning/courses/:id/sequence` |
| المجاني | كتالوج الكورسات المجانية + تسجيل | `courses`, `public/websites/:id/courses*`, `POST /enrollments` |
| الـ Player | YouTube + watermark + heartbeat + lease + إكمال الدرس + device limit/takeover، دروس نصية، ملفات | `learning/courses/:id/lessons/:lessonId/content`, `playback*`, `learning/session/takeover` |
| التقييم | كويزات full-screen + integrity، واجبات (draft + رفع)، النتائج | `courses/:id/quizzes/*`, `courses/:id/assignments/*`, `learning/results` |
| الشهادات | قائمة، عرض، تحميل PDF، مشاركة رابط التحقق | `learning/certificates/*` |
| التواصل | الإشعارات + push + التفضيلات، الإعلانات، المنتدى (+ إبلاغ وحظر) | `notifications*`, `announcements`, `courses/:id/forum/*`, B1, B6 |
| الحساب | البروفايل، الموبايل، الباسورد، الأجهزة، السيشنز، اللغة، المظهر، تصدير البيانات، حذف الحساب، تبديل/إضافة أكاديمية | `users/me*`, `auth/sessions*`, `learning/devices*`, `privacy-requests/*` |
| معلومات | عن التطبيق وبيانات الشركة، تواصل مع الأكاديمية، المساعدة، السياسات | — |

**برّه النطاق دلوقتي:** الشراء، وlive sessions (Zoom لسه `coming_soon`، ولما يتفعّل نضيفه)،
وhosted video (لما يتفعّل نجرّب Origin على الـ native player)، وكتابة مراجعات الكورسات،
وتطبيق الإدارة.

---

## 10. المراحل

| # | المرحلة | الشغل | بتخلص لما |
|---|---|---|---|
| **0** | الأساس والتجارب | Flutter scaffold في `atlas-mobile`، وCI (analyze + test + build APK، وjob على macOS لـ iOS من غير توقيع). **تجارب:** cookies + `Origin` + refresh rotation + OTP + device cookie على الباك اند المحلي. YouTube في WebView + watermark. `FLAG_SECURE`. وطلب من native UA على production عشان نتأكد إن Cloudflare مابيعملش challenge | كل تجربة نجحت أو رجعتلك ببديل |
| **1** | الباك اند | B1–B7 في `atlas-backend` على branch، كل حاجة ورا flag، e2e + inventories. Release بالترتيب اللي في الـ handover، **والـ migration بموافقتك** | deploy على production والـ flags مقفولة، والويب زي ما هو |
| **2** | أساس التطبيق | design system، والـ API client، والترجمة EN/AR + RTL، واختيار الأكاديمية، والدخول كله، والموافقات، والسياسات | طالب يدخل ويخرج بكل الطرق |
| **3** | التعلّم | الرئيسية، وكورساتي، والـ player الكامل، والدروس النصية، والملفات، والأجهزة | طالب يخلّص كورس |
| **4** | التقييم | الكويزات، والواجبات، والنتائج، والشهادات | دورة تعلّم كاملة |
| **5** | التواصل والحساب | push (التطبيق + B1)، والإعلانات، والمنتدى، والحساب كله | — |
| **6** | المجاني والروابط | كتالوج المجاني، وdeep links، وQR (+ AASA/assetlinks على الويب §5) | — |
| **7** | iPad والإتاحة والتلميع | layouts الـ iPad، وجرد accessibility، و`/impeccable polish` و`audit` على كل شاشة، وanimations | goldens وجرد نضاف |
| **8** | جاهزية المراجعة | Checklist §7 كاملة، وأكاديمية وحساب الديمو، وصفحات الويب القانونية (§5)، ومسودات السياسات للمحامي، وreview notes | كل بنود §7 ✔ |
| **9** | **الحسابات والنشر (الأخيرة)** | الخطوات تحت | التطبيق على الستورين |

### المرحلة 9 — الحسابات والنشر

1. **Apple Developer Program** (99$/سنة). كـ **Organization** أحسن: اسم الشركة يظهر كبائع.
   محتاج **D-U-N-S number**، وده ممكن ياخد أيام أو أسابيع.
2. **Google Play Console** (25$ مرة واحدة). كـ **Organization** برضه. الحسابات الشخصية
   الجديدة لازم تعمل closed testing بـ 12 tester لمدة 14 يوم قبل production.
3. **Firebase project**: FCM، ونرفع APNs key من Apple.
4. Apple: Bundle ID، وتفعيل Sign in with Apple، وService ID + key لـ B2، وتسجيل دومين
   الإيميلات للـ private relay، وAssociated Domains.
5. Signing: certificates وprovisioning profiles وkeystore Android (متخزنة كـ GitHub secrets).
6. نختبر الحاجات اللي ماتتجرّبش غير بالحسابات: push على iOS وSign in with Apple end-to-end.
7. App Store Connect: privacy labels، وage rating، وtrader info، وscreenshots (iPhone 6.9"
   وiPad 13")، والوصف EN/AR، وreview notes + حساب الديمو. Google Play: Data safety،
   ورابط حذف الحساب، وcontent rating، وtarget audience.
8. TestFlight + Play internal/closed testing مع أكاديمية حقيقية.
9. Submission، وبعد الموافقة تحديث الـ help center والماركتنج.

> نصيحة: إجراءات D-U-N-S وتسجيل الشركة ممكن تبدأها بدري **بالتوازي** من غير ما توقّف أي
> شغل، عشان المرحلة 9 ماتستناش أسابيع.

---

## 11. الاختبارات

- **التطبيق:** unit (الـ API client، الـ refresh mutex، الـ watermark scheduler، mapping
  الـ errors)، وwidget، وgolden (EN/AR × light/dark × text scale 1.0/2.0 × iPhone SE/Pro
  Max/iPad)، وintegration على الباك اند المحلي (login، OTP، refresh، grant، heartbeat،
  quiz attempt، رفع ملف، حذف حساب).
- **الباك اند:** e2e لكل route جديد (المسموح والممنوع)، والـ inventories، والـ suites
  الموجودة كلها تعدّي، وتأكيد إن الـ responses الموجودة شكلها ماتغيّرش.
- **يدوي:** checklist على أجهزة حقيقية في TestFlight/Play testing، وVoiceOver/TalkBack.

---

## 12. أسئلة محتاج إجابتها

1. **الماك:** الموديل ونسخة macOS؟ (عشان Xcode 26، §2.2)
2. **Production flags:** `FLAG_AUTH_GOOGLE_MODE` و`FLAG_AUTH_EMAIL_OTP_MODE_ACADEMY` قيمتهم
   إيه؟ (أنا مش شايف الـ env بتاع production)
3. **بيانات الشركة** للسياسات وشاشة "عن التطبيق": الاسم القانوني، والعنوان، وإيميل الدعم،
   والتليفون.
4. **سياسة السن:** فيه طلاب أقل من 13 سنة؟ لو أيوه، نحتاج موافقة ولي أمر حقيقية، وده أكبر
   من checkbox.
5. **موافقة على تعديلات الويب** في §5 (صفحات وAASA وصفحة بلاغات المنتدى)؟
6. **المنتدى في النسخة الأولى** بالإبلاغ والحظر (B6)؟ ولا نأجّله ونقلّل الباك اند؟
7. فيه **أكاديمية حقيقية** تجرّب الـ beta معانا؟

---

## 13. المصادر الخارجية

- Apple 3.1.1 / 3.1.3(b): <https://developer.apple.com/forums/thread/748871>, <https://developer.apple.com/forums/thread/740710>
- Apple 4.2.6 (picker model): <https://goodbarber.com/blog/apple-app-store-guideline-4-2-6-a862>
- Apple 4.8 (Sign in with Apple): <https://developer.apple.com/forums/thread/765145>
- متطلبات Xcode 26 / iOS 26 SDK: <https://developer.apple.com/news/upcoming-requirements/>, <https://capgo.app/blog/xcode-26-requirement-for-capacitor-apps/>
- لازم نراجع النص الحالي على <https://developer.apple.com/app-store/review/guidelines/> وسياسات Google Play قبل المرحلة 9.

---

## 14. إجابات 24 أكتوبر (بتغيّر اللي فوق)

| السؤال | الإجابة | الأثر |
|---|---|---|
| الماك | macOS 13.7.8 (Ventura)، Intel | Xcode 26 محتاج macOS 15.6 على الأقل، فالماك مش هيقدر يبني للستور. **iOS builds وTestFlight من GitHub Actions على macOS**. الماك للتجربة بس، لو Xcode/Flutter المتاحين على Ventura اشتغلوا |
| Google في production | `GET /auth/options` على `ziadd.atlass.dpdns.org` ← `{"google":false}` | B2b مش محتاجينه دلوقتي. Sign in with Apple فاضل لأنك طلبته |
| OTP في production | القيمة في GitHub (مش متاحة لي) | هيبان في المرحلة 0 من أول تسجيل دخول تجريبي |
| Cloudflare | طلب بـ UA بتاع التطبيق رجع 200 | مفيش challenge للـ native client |
| AASA | `/.well-known/apple-app-site-association` بيرجّع صفحة الـ SPA (HTML) | لازم الإضافة في §5 عشان الروابط تفتح التطبيق |
| بيانات الشركة | Atlas · 6 أكتوبر · info@atlas.com · 01000510491 | الإيميل لازم يتأكد (هل الدومين ده بتاعكم؟). والعنوان محتاج تفاصيل أكتر عشان الستور |
| السن | 13 سنة أو أكبر | تأكيد سن عند التسجيل، واللي أصغر من 13 مايقدرش يسجّل. مفيش موافقة ولي أمر |
| المنتدى | **يتأجّل** | **B6 اتشال**، والمنتدى مش في النسخة الأولى، وصفحة بلاغات الويب اتشالت |
| الأكاديمية التجريبية | `https://ziadd.atlass.dpdns.org/` (academyId `7857eec7-…`، theme `manara`) | التجارب وحساب الديمو للمراجعة عليها |

---

## 15. حالة المرحلة 1 (24 أكتوبر)

كل الإضافات على فرع `claude/vigilant-thompson-tniy49` في `atlas-backend`. **مفيش merge ولا
deploy ولا PR.** التفاصيل التقنية في `atlas-backend/docs/mobile/MOBILE_APP_BACKEND.md`.

| # | الإضافة | الحالة | Migration | Flag (افتراضي مقفول) |
|---|---|---|---|---|
| B7 | اسم الجهاز "Atlas app on iOS/Android" | ✅ | — | — |
| B5 | `GET /public/mobile/config` | ✅ | — | env اختيارية |
| B4 | سجل الموافقات (الشروط، الخصوصية، 13+) | ✅ | `20261128000100_user_consents` | — (حقل اختياري) |
| B3 | دخول حساب مراجعة Apple/Google | ✅ | — | `APP_REVIEW_EMAILS` + `APP_REVIEW_ACADEMY_ID` |
| B1 | Push notifications (FCM) | ✅ | `20261128000200_push_devices` | `FLAG_PUSH_MODE` |
| B8 | الطالب يحذف حسابه من التطبيق | ✅ (جديدة، بموافقتك) | — | — |
| B2 | Sign in with Apple | ✅ | `20261128000300_sign_in_with_apple` | `FLAG_AUTH_APPLE_MODE` |
| B6 | الإبلاغ في المنتدى | ⏸ متأجلة مع المنتدى | — | — |

**قرارات اتاخدت أثناء التنفيذ:**
- **نص الـ Push** عام وفيه اسم الأكاديمية بس ("لديك إعلان جديد"). مفيش درجات ولا مبالغ على شاشة
  القفل، والتفاصيل في التطبيق.
- **الـ Push بيتبعت بس** لأجهزة الطالب على نفس الأكاديمية وجلستها لسه شغالة. الخروج أو إلغاء
  الجلسة بيوقفه تلقائياً.
- **حذف الحساب من التطبيق** للطالب اللي ملوش أي دور إداري. صاحب الأكاديمية أو الستاف بيتحوّلوا
  لطلب الحذف العادي.
- **Apple** على نفس قواعد Google: الإيميل الموجود بيتربط بالباسورد بس، مش بمجرد إن الإيميل
  متطابق.
