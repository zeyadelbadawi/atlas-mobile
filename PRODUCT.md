# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Stack

Flutter (Dart), one codebase for iOS, iPadOS and Android. Decided in `docs/ATLAS_MOBILE_PLAN.md` §2.

## Users

Students enrolled at an academy that runs on Atlas. Two groups in equal measure:

- secondary and preparatory school students (mostly 13–18) at teacher-led tutoring academies;
- university students and professionals taking skills courses.

They open the app to continue a lesson, check what is due (quizzes, assignments), see results and
certificates, and read their academy's announcements. Often on a phone and on mobile data, sometimes on
an iPad. Minimum age is 13; there is no parental-consent flow.

## Product Purpose

The Atlas learner app does on a phone what the web learner area (`/my`) does: lessons, quizzes,
assignments, results, certificates, notifications and announcements, the student's profile, devices and
account. It also adds push notifications. Success means a student opens the app and is back in the
lesson they were watching within a few seconds, and nothing on the web changes because the app exists.

## Positioning

One Atlas app serves every academy on the platform. The student picks their academy (link, QR code,
deep link or a recent academy), and from then on the app wears **that academy's identity in full**:
its name, logo and colours. Atlas itself shows only on the academy picker and on the About screen.

## Operating Context

- Each academy has its own host (`{slug}.atlass.dpdns.org` or a custom domain), and the app talks to that
  host's API.
- Academy branding comes from `GET /public/websites/:academyId/identity`: `name`, `primaryColor`,
  `secondaryColor`, `accentColor` as HSL strings, plus a logo. The colours can be anything the academy
  chose, including ones with poor contrast. For example, the demo academy Ziadd has a primary of
  `40 95% 54%` (amber).
- Lessons are YouTube embeds with a moving per-viewer watermark. Screens are protected from capture
  where the OS allows it.
- Sign-in uses email and password, an emailed code on new devices, and Sign in with Apple on iOS.
  Each academy limits how many devices a student can use.

## Capabilities and Constraints

- **No purchasing in the app.** It lists courses the student is enrolled in, plus free courses they can
  join. There are no prices, payment links or "buy on the web" prompts.
- **Language:** follows the phone's language (Arabic or English), and the student can change it in
  settings. Full RTL. Arabic is the primary design case.
- **App Store and Google Play requirements are part of the product.** This means:
  - privacy policy, terms, refund and cookie policies, and a consent step;
  - in-app account deletion and data export;
  - a working demo login and Sign in with Apple;
  - a working iPad layout;
  - business details on the About screen;
  - no "coming soon" or outdated screens, no dark patterns, no hidden features;
  - accessible contrast, Dynamic Type and screen-reader labels.
- **Not in the first version:** the forum, live sessions, hosted video and course reviews.
- **The management app** comes later, as a separate plan.

## Brand Commitments

- Inside an academy, the academy's identity leads. The app shell has no Atlas colours of its own there.
- On the academy picker, the first-run screens and About, Atlas appears under its own name. The legal
  name is "Atlas", the address is 6 October (Egypt), the email is info@atlas.com, and the phone is
  01000510491. Before release we still need to confirm the email domain and get a fuller address.
- The web themes (`modern-education`, `manara`, `riwaq` and others in
  `atlas/src/features/website/themes`) are the academies' public faces. The app follows iOS and Android
  patterns; it is not a copy of the website.

## Evidence on Hand

- Real academy: Ziadd (`https://ziadd.atlass.dpdns.org/`, theme `manara`), with real identity colours.
- Web fonts already licensed and shipped by Atlas: Readex Pro, Rubik, JetBrains Mono
  (`atlas/src/styles/fonts.css`).
- No app-store screenshots, testimonials, ratings or download numbers exist. None may be invented.

## Product Principles

1. **Back to the lesson fast.** The most common job is continuing where the student stopped. Nothing
   stands between opening the app and that.
2. **The academy's app, not ours.** Every screen inside an academy should feel like it belongs to that
   academy, while still behaving the same across academies.
3. **Honest and calm.** No purchase nudges, fake urgency or hidden options. What the student sees is
   what the academy published.
4. **Native first.** Platform gestures, navigation and type sizes behave the way each OS expects.
5. **Nothing on the web breaks.** The app only adds; it never changes what the web relies on.

## Accessibility & Inclusion

- WCAG AA contrast for text and controls in light and dark modes, whatever colours an academy chooses.
  Academy colours are adjusted automatically when they fail.
- Dynamic Type / font scaling up to the largest accessibility sizes without clipping, in Arabic and
  English.
- Screen-reader labels on every control, and alt text for academy logos and course images.
- Reduced motion is respected. The moving watermark keeps working, but without animation flourishes.
