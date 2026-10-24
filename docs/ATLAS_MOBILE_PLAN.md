# Atlas Mobile — خطة التطبيق (مسودة للمراجعة)

> تاريخ: 24 أكتوبر 2026 — مبنية على قراءة `atlas` (frontend) و`atlas-backend` حتى
> آخر commit في 24 أكتوبر (Founding Academies / CMS phase 4).
> **القيد الأساسي: صفر تعديل على `atlas-backend`.** كل حاجة هنا بتستخدم الـ API
> الموجود زي ما هو. أي حاجة محتاجة الباك اند متعلّمة صراحة إنها "مؤجلة / محتاجة موافقة".

---

## 1. الخلاصة

1. **نبدأ بتطبيق الطلاب بس (Learner app).** هو اللي عليه الطلب الحقيقي، وكل الـ
   endpoints بتاعته موجودة وشغالة على الويب في `/my/*`.
2. **تطبيق واحد اسمه Atlas لكل الأكاديميات** (الطالب يختار أكاديميته)، مش تطبيق
   لكل أكاديمية. White-label لكل أكاديمية ييجي بعدين كـ add-on مدفوع من نفس الكود.
3. **الإدارة (Management) مش تطبيق كامل.** المرحلة التانية تبقى "وضع صاحب
   الأكاديمية" صغير جوه نفس الكود: مراجعة إثباتات الدفع، موافقة الطلاب، الإشعارات،
   الإعلانات. بناء الكورسات والموقع يفضل على الويب.
4. **التقنية المقترحة: Expo (React Native) + TypeScript.** نفس لغة الريبوهين،
   وبنعيد استخدام الـ types وملفات الترجمة EN/AR وأسلوب TanStack Query اللي
   في الفرونت.
5. **الشراء جوه التطبيق على iOS فيه مشكلة سياسات** (تحت في §6). الـ MVP يعرض
   الكورسات المسجّل فيها الطالب والمجانية، والشراء يكون على موقع الأكاديمية — لحد
   ما نقرر في موضوع Apple.

---

## 2. اللي فهمته من المشروع (الأجزاء اللي تهم الموبايل)

| الموضوع | الحالة في الكود | أثره على الموبايل |
|---|---|---|
| Multi-tenant | Organization → Academies. كل أكاديمية ليها subdomain `{slug}.atlass.dpdns.org` أو custom domain | الطالب لازم يختار أكاديمية، والتطبيق يكلّم الـ API على **host الأكاديمية نفسه** |
| تحديد الأكاديمية | الباك اند بيحدد الأكاديمية من `request.hostname` (`hostAcademyId`, `assertSessionServesHostAcademy`) | الـ base URL في التطبيق = `https://<academy-host>/api/v1` لكل أكاديمية |
| Resolve | `GET /public/websites/resolve?hostname=` + `/:academyId/identity`, `/logo`, `/favicon` | شاشة "ادخل رابط أكاديميتك" + الهوية (لوجو/ألوان) من غير backend جديد |
| Sessions | Access token 15 دقيقة في الـ body. Refresh token **بس** في cookie `__Host-atlas_session` (HttpOnly, Secure, SameSite=Strict). الـ interceptor بيشيله من الـ body دايماً | التطبيق لازم يستخدم **cookie jar** native ويحتفظ بالـ cookie (HttpOnly بيمنع JavaScript في المتصفح بس، الـ HTTP client الـ native شايفه عادي) |
| CSRF | `/auth/refresh` و`/auth/sign-out` بيطلبوا `Origin` = نفس scheme/host الطلب | التطبيق يبعت `Origin: https://<academy-host>` في الطلبين دول. ده مش ثغرة: الشرط موجود عشان المتصفحات، والكود نفسه بيقول إن non-browser client بيحط الـ header زي ما هو عايز |
| Refresh rotation | Reuse detection + `SupersededRefreshTokenException` | لازم refresh واحد بس في نفس الوقت (single-flight mutex) وإلا السيشن يتقفل |
| Sign-in أكاديمية | `POST /auth/sign-in` بـ `surface: 'academy'` + `academyId` (بيتشيك على الـ host). Email OTP على الأجهزة الجديدة (`/auth/otp/verify`)، `atlas_trust` cookie للأجهزة الموثوقة | شاشات: login → OTP → app. الـ cookies كلها في نفس الـ jar |
| Device limit | `atlas_device` cookie = جهاز. `/learning/devices`، `/learning/session/takeover`، `DELETE /learning/devices/:id` | التطبيق = جهاز واحد (طالما الـ jar محفوظ). محتاجين شاشة Device limit زي `DeviceLimitDialog` |
| Device label | الباك اند بيستنتج الاسم من الـ User-Agent (`deriveDeviceLabel`) | نبعت UA فيه `Android` أو `iPhone` عشان يظهر صح في صفحة الأجهزة |
| الفيديو في production | **YouTube embeds** (الـ hosted video tiers مبنية بس مش مفعّلة، والـ FAQ بيقول "no video file uploads") | Player = YouTube iframe جوه WebView + overlay الـ watermark فوقه |
| Forensic watermark | كل grant فيه كود لكل مشاهد، fail-closed (503). الـ overlay بيترسم في الـ player (label بيتحرك كل 20–45 ثانية + tile خفيف + watchdog) | **لازم** نعيد بناء الـ overlay native بنفس القواعد. على الموبايل نزوّد `FLAG_SECURE` على Android وكشف تسجيل الشاشة على iOS |
| Hosted video (مستقبلاً) | Stream/R2 بـ allowed origins على الـ edge (`academy-origins.service.ts`) | لما يتفعّل: الـ player الـ native لازم يبعت `Origin`/`Referer` بتاع الأكاديمية — يتجرّب في spike |
| Playback heartbeat / lease | `POST learning/courses/:id/playback`, `/playback/release`, `/lessons/:lessonId/playback/refresh` | نفس منطق `playback-heartbeat` في الويب؛ release لما التطبيق يروح background |
| Quizzes integrity | events: `visibility_hidden/visible`, `blur/focus`, `fullscreen_*`, `copy/paste`... | نربط AppState (background/foreground) بـ `visibility_*`، والشاشة full-screen طبيعي على الموبايل (ميزة عن iPhone Safari اللي مفيهوش fullscreen) |
| Payments | يدوي بس: تحويل بنكي، محفظة (Vodafone Cash)، InstaPay + رفع إثبات. Course orders → payments → proof | ممكن تقنياً بالكامل (كاميرا لرفع الإثبات) — بس شوف §6 |
| Notifications | قنوات `email` و`in_app` بس. **مفيش push** (لا جدول device tokens ولا FCM/APNs) | الـ MVP: polling على `/notifications/summary` عند فتح التطبيق + background fetch. Push حقيقي = تعديل backend (§8) |
| Offline | سياسة الويب: ممنوع تخزين media/grants/quiz sessions/grades | نلتزم بنفس الـ allowlist. **مفيش تحميل فيديوهات offline** (والـ YouTube ToS بيمنعه كمان) |
| اللغة | EN/AR + RTL كامل، ملفات `src/localization/resources/{en,ar}/*.json` | ننسخ namespaces الطالب (learning, auth, course, notifications, payments, certificates, errors...) |
| Errors | `NormalizedApiError` + `messageKey` (زي `errors.auth.phoneTaken`) | نفس الـ mapping من `errors.json` |
| Validation | `forbidNonWhitelisted` — أي field زيادة في الـ body = 400 | الـ DTOs في التطبيق لازم تطابق الويب بالظبط |

تواريخ مهمة: الـ handover الرسمي آخر تحديث 10 أكتوبر (`ATLAS_FULL_PROJECT_HANDOVER_2026-10-10.md`).
بعده: help center وfact-check (20 أكتوبر)، dashboard subdomain DL-63 (21 أكتوبر)،
`POST /auth/refresh` بيرجّع الـ user (22 أكتوبر — بيوفّر round trip في التطبيق)،
CMS phases 2–4 (22–23 أكتوبر)، Founding Academies (24 أكتوبر).
ملاحظة: الـ Vision doc كان قايل "مش هنعمل Mobile App في السنة الأولى"، والـ help center
والماركتنج بيقولوا حالياً "No mobile app" — **لازم يتحدّثوا لما التطبيق ينزل**
(`content/docs/en/faq/general.md`, `reference/browsers-and-devices.md`,
`marketing/launch-kits/*`).

---

## 3. قرار: طلاب بس ولا طلاب + إدارة؟

**التوصية: طلاب الأول، والإدارة كمرحلة تانية صغيرة.**

- الطالب بيستخدم الموبايل أغلب الوقت (مصر، فيديو، كويزات). صاحب الأكاديمية بيبني
  الكورسات والموقع من الكمبيوتر.
- الإدارة على الويب ضخمة جداً (CMS، visual editor، billing، onboarding...) — نسخها
  كلها على الموبايل مضيعة وقت.
- اللي صاحب الأكاديمية محتاجه فعلاً على الموبايل حاجات سريعة:
  1. مراجعة إثبات الدفع والموافقة/الرفض (`academies/:id/course-payments/*`) — **دي أهم واحدة**،
     لأن الدفع كله يدوي والطالب مستني.
  2. موافقة/رفض/حظر الطلاب (`academies/:id/students/:userId/approve|reject|block`).
  3. الإشعارات، رسائل الموقع (`contact-submissions`)، نشر إعلان.
  4. أرقام سريعة (`academies/:id/stats`).
- الإدارة تحتاج session `management` على `dashboard.atlass.dpdns.org` + 2FA (Org Owner
  عليه second factor على كل جهاز جديد). ده متاح في الـ API بس محتاج شغل auth منفصل.

**الشكل:** نفس الـ codebase (monorepo فيه `apps/learner` و`apps/manager` + `packages/core`)،
تطبيقين منفصلين في الستور. السبب: الطالب ميشوفش أي حاجة إدارية، والـ review بتاع الستور
أسهل لما كل تطبيق ليه هدف واحد.

---

## 4. قرار: تطبيق واحد ولا تطبيق لكل أكاديمية؟

| | تطبيق Atlas واحد (picker) | White-label لكل أكاديمية |
|---|---|---|
| الإطلاق | تطبيق واحد في كل ستور | تطبيق لكل عميل |
| Apple 4.2.6 | الـ "picker model" مقبول من Apple لتطبيقات المنصات | لازم الأكاديمية تنشره من developer account بتاعها (99$/سنة) |
| الهوية | لوجو وألوان الأكاديمية بتتحمّل بعد الاختيار | اسم وأيقونة الأكاديمية في الستور |
| الصيانة | build واحد | builds كتير (EAS بيسهّلها) |

**التوصية:** تطبيق واحد دلوقتي. الطالب يدخل رابط الأكاديمية أو يعمل scan لـ QR أو
يفتح deep link من الإيميل/الموقع. بعد كده الـ white-label يبقى add-on مدفوع "تطبيق باسم
أكاديميتك" (فيه بالفعل نظام add-ons بـ `catalog_status`).

---

## 5. التقنية

**Expo (React Native) + TypeScript** — أسبابي:
- الريبوهين TypeScript. نقدر ننسخ/نشارك `src/types/*.types.ts`، ملفات الترجمة، الـ
  error keys، وطريقة TanStack Query + react-hook-form + zod.
- EAS Build/Submit/Update للـ builds والـ OTA updates.
- RTL مدعوم (`I18nManager`)، `expo-screen-capture` للحماية، `expo-secure-store`.

Flutter بديل كويس جداً (أداء وRTL ممتازين)، بس هيبقى كود Dart منفصل تماماً عن الـ
types والترجمة اللي عندك، وأي تغيير في الـ API هيتعمل مرتين.

**مكتبات (تتحدد نسخها وقت الـ scaffold على آخر stable):**
expo-router، @tanstack/react-query، i18next/react-i18next، react-hook-form + zod،
react-native-webview (YouTube)، expo-screen-capture، expo-secure-store،
expo-image-picker/document-picker (إثبات الدفع والواجبات)، Sentry (الباك اند بيستخدمه أصلاً).

**الـ HTTP client والـ cookies — أهم نقطة تقنية، تتجرّب أول حاجة:**
- jar منفصل لكل host أكاديمية (`__Host-` cookie مربوط بالـ host).
- `atlas_session`, `atlas_device`, `atlas_trust` وknown-device cookie لازم يتحفظوا
  بعد قفل التطبيق.
- `Origin` header يدوي على refresh/sign-out.
- refresh single-flight + retry مرة واحدة على 401.
- لو native cookie store بتاع RN مطلعش مضمون (Origin على iOS، persistence)، نعمل
  cookie handling يدوي: نقرأ `Set-Cookie` ونخزنه في SecureStore ونبعته في `Cookie`.

---

## 6. الشراء والسياسات (لازم قرار منك)

- **Apple:** الكورسات المسجّلة digital content. القواعد (3.1.1) بتطلب In-App Purchase لو
  التطبيق بيبيعها أو بيفتحها بعد شراء من بره، إلا في حالات (multiplatform 3.1.3(b) اللي
  برضه بتشترط IAP يكون متاح، وروابط الدفع الخارجي مسموحة في US storefront بس). الدفع
  بـ Vodafone Cash/InstaPay جوه تطبيق iOS **غالباً هيترفض**.
- **Google Play:** نفس الفكرة تقريباً (Play Billing للمحتوى الرقمي)، مع برامج alternative
  billing في بعض البلاد — محتاج نتأكد من وضع مصر.
- **المقترح للـ MVP:** التطبيق مفيهوش زرار شراء ولا أسعار ولا "ادفع على الموقع".
  بيعرض الكورسات المسجّل فيها + المجانية (`POST /enrollments` للمجاني). ده نمط
  شائع (Teachable وغيره) بس **مش مضمون مع Apple**، لازم نراجع نص الـ guidelines الحالي
  قبل الـ submission.
- على Android ممكن نعرض طلبات الشراء اللي اتعملت على الويب ونسمح برفع الإثبات
  لطلب موجود — ده كمان محتاج مراجعة لسياسة Play.
- IAP حقيقي = Apple/Google بياخدوا 15–30% + backend لاستقبال الـ receipts → خارج نطاق
  "مفيش تعديل backend".

---

## 7. نطاق MVP — تطبيق الطالب

| # | الشاشة | Endpoints |
|---|---|---|
| 1 | اختيار الأكاديمية (رابط / QR / deep link / آخر أكاديميات) | `public/websites/resolve`, `:academyId/identity`, `/logo` |
| 2 | Login + OTP + نسيت الباسورد + تسجيل جديد (مع الموبايل الإجباري) | `auth/sign-in`, `auth/otp/*`, `auth/register`, `auth/academy-join`, `auth/password-reset/*` |
| 3 | الرئيسية (overview، استكمال آخر درس) | `learning/overview` |
| 4 | كورساتي + تفاصيل الكورس والتقدّم | `enrollments`, `courses/:id`, `courses/:id/progress`, `learning/courses/:id/sequence` |
| 5 | الـ Player (YouTube + watermark + heartbeat + اكتمال الدرس) | `learning/courses/:id/lessons/:lessonId/content`, `.../playback*`, `courses/:id/progress/complete-lesson` |
| 6 | دروس نصية + ملفات | نفس الـ content grant (روابط HMAC قصيرة) |
| 7 | الكويزات والامتحانات (full-screen + integrity events) | `courses/:id/quizzes/*`, `learning/quizzes` |
| 8 | الواجبات (draft + رفع ملف) | `courses/:id/assignments/*`, `learning/assignments` |
| 9 | النتائج والشهادات (عرض/تحميل PDF) | `learning/results`, `learning/certificates/*` |
| 10 | الإشعارات + الإعلانات | `notifications*`, `announcements` |
| 11 | المنتدى (قراءة + كتابة) | `courses/:id/forum/*` |
| 12 | الكتالوج والكورسات المجانية | `courses`, `public/websites/:academyId/courses*` |
| 13 | البروفايل، الموبايل، الباسورد، الأجهزة، الجلسات، حذف الحساب | `users/me*`, `auth/sessions*`, `learning/devices*`, `users/me/delete*` |

**حذف الحساب** موجود في الـ API — ومطلوب إجبارياً من Apple وGoogle لأي تطبيق فيه تسجيل.

**مؤجل بعد MVP:** Google sign-in (محتاج OAuth native)، Live sessions (Zoom لسه
`coming_soon`)، مراجعات الكورسات، الشراء (حسب §6)، hosted video.

---

## 8. حاجات محتاجة الباك اند (مش هتتعمل إلا بموافقتك)

كلها **additive** ومش هتأثر على الويب، بس بتخالف قاعدة "صفر تعديل"، فهي مؤجلة:

1. **Push notifications:** جدول `user_push_devices` + channel `push` في communications
   outbox + FCM/APNs. ده أكبر فرق في تجربة الموبايل (تمت الموافقة على الدفع، إعلان جديد،
   واجب اتصحّح).
2. **Universal/App Links:** `/.well-known/apple-app-site-association` و`assetlinks.json`
   على hosts الأكاديميات — دي في Caddy/الفرونت مش الباك اند، بس برضه ريبو شغّال.
3. **IAP receipts** لو قررت تبيع جوه iOS.
4. عدّاد/علامة إن السيشن جاية من التطبيق (للإحصائيات) — اختياري؛ الـ UA كافي مبدئياً.

---

## 9. المراحل

| المرحلة | المحتوى | مخرجها |
|---|---|---|
| **0 — Spike (أسبوع)** | Expo scaffold؛ اختبار cookie jar + `Origin` + refresh rotation + OTP + device cookie على أكاديمية تجريبية؛ اختبار YouTube في WebView + watermark overlay + `FLAG_SECURE`؛ التأكد إن Cloudflare مش بيعمل challenge للـ native UA | قرار نهائي: native cookies ولا يدوي. لو حاجة فشلت نرجعلك قبل ما نكمل |
| **1 — الأساس** | monorepo، `packages/core` (API client، types، errors، i18n EN/AR، RTL)، اختيار الأكاديمية، auth كامل، theming من هوية الأكاديمية | طالب يدخل ويخرج |
| **2 — التعلّم** | الرئيسية، كورساتي، الـ player + watermark + heartbeat، الدروس النصية والملفات، الأجهزة/takeover | طالب يتفرج على كورس للآخر |
| **3 — التقييم** | كويزات + integrity، واجبات، نتائج، شهادات | دورة تعلّم كاملة |
| **4 — المجتمع** | إشعارات (polling)، إعلانات، منتدى، بروفايل، حذف الحساب | جاهز لـ beta |
| **5 — Beta** | TestFlight / Play internal testing مع أكاديمية حقيقية؛ Sentry؛ مراجعة السياسات؛ تحديث الـ help center | submission |
| **6 — Manager app** | management auth + 2FA، مراجعة المدفوعات، الطلاب، الإشعارات، الإعلانات | تطبيق صاحب الأكاديمية |
| **لاحقاً** | push (backend)، white-label add-on، hosted video، live sessions، Google sign-in | |

---

## 10. مخاطر لازم تتجرّب بدري

1. **Cookie/Origin على iOS** في RN fetch — لو اتقفل، cookie handling يدوي.
2. **Cloudflare** (bot protection/WAF) ممكن يرفض طلبات من غير متصفح.
3. **YouTube في WebView:** الـ iframe API محتاج origin مقبول؛ وفيه احتمال الطالب يوصل
   للينك الفيديو (نفس القيد الموجود على الويب ومكتوب في الـ FAQ).
4. **سياسة Apple** للشراء ولـ "تطبيق بيعرض محتوى اشتراه برّه".
5. **Rate limits:** sign-in/register/OTP عليهم guards — الـ IP في مصر غالباً CGNAT على
   شبكات الموبايل؛ نفس وضع الويب، بس نراقبه.
6. **أي تغيير مستقبلي في الـ API** للويب ممكن يكسر التطبيق، والتطبيق مش بيتحدّث فوراً
   زي الويب. محتاجين قاعدة: الباك اند يفضل backward-compatible لنسخ التطبيق القديمة
   (ودي حاجة تتكتب في الـ handover وتتعلّم للـ sessions الجاية).

---

## 11. أسئلة محتاج إجابتها منك

1. موافق على: طلاب الأول + manager app كمرحلة 6؟
2. تطبيق Atlas واحد (picker) ولا عندك عميل عايز تطبيق باسمه دلوقتي؟
3. Expo/React Native ولا تفضّل Flutter؟
4. الشراء: نبدأ من غير شراء في التطبيق (المقترح)؟
5. عندك Apple Developer وGoogle Play Console accounts باسم الشركة؟
6. فيه أكاديمية تجريبية على production (أو staging) نعمل عليها الـ spike بحساب طالب تجريبي؟
7. Push notifications مهمة للـ MVP؟ لو أيوه، ده أول استثناء لقاعدة "مفيش تعديل backend".
