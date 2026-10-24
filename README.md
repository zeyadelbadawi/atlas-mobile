# Atlas Mobile

The Atlas learner app (Flutter, iOS + Android). Plan: `docs/ATLAS_MOBILE_PLAN.md`.
User flows: `docs/USER_FLOWS.html`. Latest report: `docs/PHASE_0_REPORT.md`.

## Setup

- Flutter **3.47.7** (stable). CI pins the same version.
- `flutter pub get`, then `flutter analyze` and `flutter test`.

## Integration tests (local backend only)

`test/integration/*` run against the disposable local stack from `atlas-backend`
(`scripts/e2e-local-stack.sh up`, then start the API) and skip themselves when
their `ATLAS_SPIKE_*` variables are not set. See each file's header. They never
target production.

## Layout

```
lib/core/api       HTTP client, cookies, errors
lib/core/auth      sign-in / code / register / restore
lib/core/platform  screen-capture protection (Android FLAG_SECURE, iOS capture detection)
lib/features/...   feature code
lib/spike          phase 0 test harness (removed in phase 2)
.claude/skills     design skills (Impeccable, Emil Kowalski)
```
