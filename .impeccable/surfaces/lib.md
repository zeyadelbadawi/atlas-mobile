---
version: 1
slug: "lib"
primary_target: "lib"
related_targets: []
---

## Scope

The Atlas learner app: the design system (tokens, components) and the phase-2 screens (academy picker, sign-in, emailed code, register with consents, Sign in with Apple, legal, About), plus the Home sample that shows how the system holds a working screen. Built in Figma first for owner approval, then in Flutter. Mode: Operate (native iOS + Android, adaptive).

## Audience and job

Students of one academy on the platform, half school-age (13–18), half university/professional. Their job: get back into the lesson they stopped, see what is due, read results and announcements. Phone first, iPad supported. Arabic RTL is the primary case; English LTR follows the phone language.

## Constraints

Academy identity in full inside an academy; Atlas only on picker, first run and About. Academy colours are arbitrary HSL and must be contrast-corrected. No purchasing. Native controls only (HIG on iOS, Material 3 on Android). Dynamic Type, dark mode, reduce motion.

## Direction contract

THESIS: The app is the academy's ملزمة, the teacher's (or the university's) printed handout: a cover band in the academy's own colour, clean pages inside, every lesson known by its number. It refuses the category default of a white shell with image cards and a tint on buttons.

OWN-WORLD: Academy colour as a full-bleed cover band behind the large title on top-level screens and as the generated cover of any course without an image; ground is near-white paper tinted 2% toward the academy hue (dark: deep ink tinted the same way); ink near-black. Readex Pro for display, numerals and titles (Arabic + Latin), platform system face for body and controls. Lesson numbers set large in tabular figures. Hairline rules, not boxes; no shadows beyond platform sheets.

STORY: The student opens the app, sees their academy's cover with their name, and directly under it the bookmark on the lesson they stopped at; one tap resumes. Below: what is due, ordered by date. They trust it because it looks like their academy and asks nothing of them.

FIRST VIEWPORT: Home. Cover band (academy colour, ~30% of the viewport) with academy logo + name at the leading top, greeting as large title. Overlapping the band's lower edge, the Continue panel: bookmark ribbon hanging from its top at the leading side, "الدرس ١٢" in display numerals, lesson and course name, a progress line whose segments are sized by lesson duration, time left, and the primary Resume button. Then "Due soon" rows (day, time, item) on hairlines. Native tab bar (iOS) / navigation bar (Android): Home, My courses, Notifications, Account.

FORM: The ملزمة (teacher's printed handout), candidate 4 of 7 on the grounded list, assigned by the roll. seed:c49e23ac73239983

RAISES (from declined challengers):
- Airport wayfinding: one message per band. Home's cover band carries one thing (the academy and greeting); the next action has its own panel, never mixed.
- Labanotation: length is exact duration. Progress lines are segmented by each lesson's real duration, not equal ticks.
- Boarding pass and gate board: a change holds its mark until seen. New grades, rescheduled deadlines and unread announcements keep the academy-colour dot until opened.
- Saville catalogue: every artifact has its sequence number. Lessons, quizzes and assignments always show their number as the headline element.
- Variable-font specimen: hierarchy by scale contrast alone. Groups separate by type size and space, not by cards.

SIGNATURE MOVE: The bookmark ribbon. A ribbon in the academy colour (with a notched tail) marks "where you stopped" on Home, on the course syllabus row and at the top of the player; when a lesson completes, the ribbon slides to the next lesson (one authored motion, crossfade under reduce motion).

FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

## Unresolved

- Exact Arabic display face weight range on very long academy names (Break-UI pass).
- Figma Starter plan limits on variable modes; light/dark may be two collections.
