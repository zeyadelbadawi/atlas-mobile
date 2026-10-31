# Design

Atlas learner app design system: **Atlas's brand with the academy as the cover**. Product context is
in `PRODUCT.md`; the redesign plan and stages are in `docs/ATLAS_MOBILE_REDESIGN.md`. The code in
`lib/design/` is the source of truth; the brand comes from the web (`atlas/src/index.css`,
`atlas/public/brand/` → `assets/brand/`).

## World

- **Atlas frame.** Splash (the mark settles, the lettering rises, a gold rule draws), app icon
  (white mark on Navy 600), academy picker (a Navy band with the lockup and the mark drawn large and
  faint at its edge, the form on a raised sheet overlapping it).
- **The academy's cover.** Inside an academy, its colour is the cover band behind the large title
  (Home, sign-in, account), the generated course covers and the progress fill. It carries one message.
- **Pages.** Atlas paper (`#FCFCFD` / `#0E121B`), ink `#141A29` / `#ECEEF3`. Raised surfaces are white
  cards with a hairline and a soft shadow (`shadow` token, 24–28 blur, 8–10 offset).
- **Numbers lead.** Lesson, quiz and assignment numbers in Readex Pro with tabular figures.
- **Signature: the gold ribbon.** It marks where the student stopped and slides to the next lesson.
- **Duration-weighted progress** in the academy's colour.

## Colour

`AtlasColors.of(palette, brightness)` in `lib/design/tokens/atlas_colors.dart`; brand constants in
`AtlasBrand` (Navy 50–900, Gold).

| Role | Light / dark | Use |
|---|---|---|
| accent, button / onButton | Navy 600 `#1B398D` / `#709DFF` on `#07132F` | actions, links, icons, selection |
| tonal | `#E8EDFA` / `#1C2A4F` | secondary buttons, selected tab |
| paper, raised, sunken | `#FCFCFD` `#FFFFFF` `#F1F3F7` / `#0E121B` `#161B27` `#1E2433` | ground, cards, fields |
| ink, inkSecondary, inkTertiary | `#141A29` `#5C657A` `#606A7E` / `#ECEEF3` `#9CA3B4` `#8E95A7` | text |
| gold, goldText, onGold | `#E0A424`, `#8A5A00` / `#F0BF4C`, `#1B1303` | ribbon, badges, pass, certificate |
| cover, onCover | the academy colour, black or white on it | cover band, course covers |
| academy | the academy hue at ≥3:1 on cards | progress fill |
| success, warning, danger, info | Atlas status colours, AA on paper | states |

`test/design/contrast_test.dart` checks every text colour on every surface for 8 academy colours in
both themes; `academy_palette_test.dart` checks 2,000 random academy colours.

## Type

| Role | Face | Size / line height (ar · en) |
|---|---|---|
| numeral | Readex Pro 600, tabular | 44 / 52 · 48 |
| largeTitle | Readex Pro 700 | 34 / 46 · 41 |
| title1–3 | Readex Pro 600/600/500 | 28, 22, 20 |
| headline, body, callout, subhead, footnote, caption | Rubik | 17, 17, 16, 15, 13, 12 (Arabic lines are taller) |
| button | Rubik 600 | 17 |

- Readex Pro and Rubik are bundled (`assets/fonts`, OFL; Rubik as Latin, Arabic and Latin Extended
  subsets chained as fallbacks). Both follow the user's text size.

### Arabic copy rules

- Do not use the middle dot `·` as a separator: in Arabic it reads as the digit zero (`٠`). Use `،`.
- Numbers shown to the reader use Arabic-Indic digits in Arabic (`context.digits`).
- Codes, emails, phone numbers and hosts stay left to right.
- Arabic copy is Modern Standard Arabic, consistent with the web and its error catalogue.

## Space, shape, motion

- **Spacing:** 2, 4, 8, 12, 16, 20, 24, 32, 40, 48. Gutter 20. Content width 560 on phones; on
  tablets pages 960 and forms 600 (`AtlasSize.contentWidth`).
- **Radius:** sm 6, md 10 (fields), lg 14 (buttons, groups), xl 22 (Continue panel, sheets).
- **Sizes:** touch target 48; button and field height 52.
- **Motion** (Emil Kowalski; one authored moment per screen):
  - launch: `SplashOverlay`, ~0.8 s, never longer than the app takes to be ready;
  - entrance: `Entrance` fades and lifts blocks 14 pt, 420 ms, 60 ms stagger (capped at 6);
  - scroll: `ScrollParallax` (cover at half speed, fading to 55%), `CompactTitleBar` (frosted bar with
    the academy's logo and name once the cover has gone);
  - press: scale 0.97, 120 ms, `Cubic(0.23, 1, 0.32, 1)`; state changes 180–240 ms; no ripple;
  - Reduce Motion: no movement anywhere; things appear in place.

## Components (`lib/design/widgets`)

| Component | Notes |
|---|---|
| `AtlasMark`, `AtlasWordmark`, `AtlasLockup` | The brand mark and lettering (`assets/brand`), lettering in the reading language. |
| `Entrance`, `ScrollParallax`, `CompactTitleBar` | Motion building blocks. |
| `AtlasButton` | Primary, tonal, plain, destructive. Disabled when `onPressed` is null. Loading keeps the width. |
| `AtlasTextField` | Label above. Focused or error shows a 2 pt ring; the error message names the fix. `ltrValue` for email, phone and password. |
| `CodeInput` | 6 cells over one hidden field with OTP autofill. Always left to right. |
| `CheckboxRow` | Never pre-checked for consent. Links in the label do not toggle the box. |
| `AtlasBanner` | Info, error or success. Announced to screen readers. |
| `Bookmark`, `SegmentedProgress`, `ContinuePanel` | The signature trio. |
| `CoverBand.home` / `.compact` | Sets the status bar style from the cover's lightness. |
| `DueRow` | `changed` keeps the accent dot until the row is opened. |
| `CourseCover` | Booklet ratio 64×84. Without an image, it shows the cover colour with the unit number. |
| `CourseRow`, `AcademyRow`, `SettingsGroup` / `SettingsRow`, `SectionHeader` | — |
| `AtlasTabBar` | Floating glass bar on iOS, Material 3 navigation bar on Android. |
| `OptionTile`, `FactList`, `StatusPill`, `AnswerField`, `Panel` (`lib/features/quiz/assessment_widgets.dart`) | Quiz choices (52 pt rows, accent ring when picked, green/red verdicts on results), label/value facts, status pills, multi-line answers. |

## Verification

- `test/design/goldens`: home (Ziadd light and dark, Manara on Android, Riwaq in English) and component
  samples.
- `test/app/goldens`: picker, sign-in (Arabic, English dark, iPad), register, code, account, about, home, courses, course, lesson, devices, quiz (intro, running, results Arabic and English dark), assignment, results and certificates.
- Regenerate with `flutter test --tags golden --update-goldens`.
- Goldens render the body text in Noto Sans Arabic (`test/fonts`); on devices it is the platform face.
