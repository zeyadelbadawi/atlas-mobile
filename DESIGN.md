# Design

Atlas learner app design system. Direction: **the handout (الملزمة)**. Product context is in
`PRODUCT.md`, and the full direction contract is in `.impeccable/surfaces/lib.md`. The original visuals are
in Figma (`EcFLLpTQHgyZXZIHKpA0RX`). The code in `lib/design/` is now the source of truth.

## World

- **Cover band.** Each academy has a cover band in its own colour, placed full-bleed under the status bar.
  - Home: logo + academy name, with the greeting as the large title.
  - Sign-in: a larger logo + the academy host.
  - It carries one message only.
- **Pages.** Below the band are clean pages: paper tinted 3.5% toward the academy hue (7% in dark mode),
  with near-black ink.
- **Numbers lead.** Lessons, quizzes and assignments show their number set large in Readex Pro with
  tabular figures.
- **Structure.** Hairlines and type scale separate groups, not cards. The only raised surfaces are the
  Continue panel and the inset groups.
- **Signature: the bookmark ribbon.** It is drawn in the academy accent and hangs from the top edge at the
  leading side. It marks where the student stopped. When a lesson completes it slides to the next lesson
  (280 ms, `easeInOut`; crossfade under Reduce Motion).
- **Duration-weighted progress.** There is one segment per lesson, and each segment's width follows that
  lesson's real duration.

## Colour

All colours come from `AcademyPalette.derive(primaryColor)` in `lib/design/tokens/academy_palette.dart`.
The input is the academy's web `primaryColor`, an HSL string.

| Role | Rule |
|---|---|
| cover | The academy colour. Its lightness is nudged only when neither black nor white text reaches 4.5:1 on it. |
| onCover | Black (`#121213`) or white, whichever has the higher contrast. |
| accent | The hue, darkened (light mode) or lightened (dark mode) until it reaches 4.5:1 on paper. Used for links, icons, the bookmark and active tabs. |
| button / onButton | The cover colour and its readable label. |
| tonal | Paper mixed with 14% of the cover (24% in dark mode). Used for secondary buttons and the selected tab. |
| neutrals | Fixed: raised, sunken, ink, ink secondary, ink tertiary, rule, rule strong, danger, success, warning (light and dark). |

`test/design/academy_palette_test.dart` checks 2,000 random colours against AA.

Never use the raw cover colour as text. Text actions use `accent`; the theme's `TextButton` is set up for
this.

Atlas's own palette (`AcademyPalette.atlas`, a deep ink blue) is used only on the picker and the
first-run screens.

## Type

| Role | Face | Size / line height (ar · en) |
|---|---|---|
| numeral | Readex Pro 600, tabular | 44 / 52 · 48 |
| largeTitle | Readex Pro 700 | 34 / 46 · 41 |
| title1–3 | Readex Pro 600/600/500 | 28, 22, 20 |
| headline, body, callout, subhead, footnote, caption | Platform face | 17, 17, 16, 15, 13, 12 (Arabic lines are taller) |
| button | Platform face 600 | 17 |

- Readex Pro is bundled (`assets/fonts`, OFL).
- Body text uses SF / SF Arabic on iOS and Roboto / Noto on Android, so system text scaling stays native.

### Arabic copy rules

- Do not use the middle dot `·` as a separator: in Arabic it reads as the digit zero (`٠`). Use `،`.
- Numbers shown to the reader use Arabic-Indic digits in Arabic (`context.digits`).
- Codes, emails, phone numbers and hosts stay left to right.
- Arabic copy is Modern Standard Arabic, consistent with the web and its error catalogue.

## Space, shape, motion

- **Spacing:** 2, 4, 8, 12, 16, 20, 24, 32, 40, 48. Gutter 20. Reading width 560 (iPad).
- **Radius:** sm 6, md 10 (fields), lg 14 (buttons, groups), xl 22 (Continue panel).
- **Sizes:** touch target 44; button and field height 52.
- **Motion** (Emil Kowalski):
  - press: scale 0.97, 120 ms, `Cubic(0.23, 1, 0.32, 1)`;
  - state changes: 180–240 ms;
  - no ripple;
  - Reduce Motion swaps scale for an opacity dip.

## Components (`lib/design/widgets`)

| Component | Notes |
|---|---|
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
