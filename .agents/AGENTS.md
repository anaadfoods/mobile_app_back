# Flutter Clean Architecture Migration — Agent Instructions

## Context
This is the Anaad Foods Flutter app (278 Dart files, ~111,741 LOC, 0 tests).
A pre-migration codebase analysis has been run. Read that analysis alongside
this file before starting any work — it contains exact file names, line
counts, and coupling details this document only summarizes.

**Corrected facts from the analysis (supersede earlier assumptions):**
- State management is **Cubit (flutter_bloc)**, not Provider. There is zero
  Provider usage. 10 Cubits already exist and are reasonably well-separated
  from widgets.
- The three security issues from the original audit (SSL bypass, plaintext
  JWT, HTTP payment bridge) are **already fixed**. Do not re-fix them. Do not
  spend migration budget on them.
- Zero test files exist despite `bloc_test` and `mocktail` being in
  `pubspec.yaml`. Testing is a first-class part of this migration, not an
  afterthought.

## Target Architecture
**Clean Architecture, keeping Cubit as the presentation-layer state holder.**
Do NOT rewrite Cubits to Riverpod or Bloc. The existing Cubits are not the
problem — fat screens with embedded business logic and god-objects are. A
full state-management rewrite across 278 files is high-risk and fixes none
of the actual pain points (feature isolation, testability, the TokenService
god-object). Riverpod is not in scope for this migration.

Cubits move from directly calling services/`GetIt` singletons to instead
calling **use cases** in a new domain layer. The Cubit's job becomes: receive
UI events, call a use case, emit a state. All business logic that currently
lives in Cubits or screens moves into the domain layer beneath them.

## UI Preservation Rule — Read This Before Touching Any Screen
**This migration changes architecture and state management. It does not
change UI.** Every screen must look and behave visually identical after
migration — same layout, same spacing, same colors, same animations, same
copy. This applies to every feature, not just the ones with big screens.

What this means in practice:
- When decomposing a monolith screen to hit the line-count budget, this is
  a **mechanical extraction**, not a redesign. Copy the existing widget
  tree/styling into the new sub-widget files verbatim. Do not "clean up,"
  restyle, re-space, or improve anything visually while you're in there,
  even if you notice something you'd do differently.
- "Fix the state issues" means: eliminate direct service/GetIt calls from
  widgets, remove duplicated or racing state updates, fix any Cubit state
  transitions that are wrong or inconsistent (e.g. a loading state that
  never clears, an optimistic update that doesn't roll back correctly) —
  it does NOT mean changing what the user sees or how a screen is laid out.
- If fixing a genuine state bug requires a visible behavior change (e.g. a
  spinner that currently never shows because of a race condition, and
  showing it correctly means the user now sees a loading spinner they
  didn't before), stop and flag it rather than silently shipping a visual
  change under the banner of "fixing state."
- Characterization tests exist specifically so you can tell the difference
  between "this now behaves correctly" and "this now looks different" —
  if a characterization test fails after a change, that is not automatically
  a bug in the test. Check whether the UI actually changed before assuming
  the test was wrong.
- This rule overrides any instinct toward improvement. Visual/UX polish is
  explicitly out of scope for this migration and should be logged as a
  separate suggestion, not implemented inline.

## Folder Structure (per feature, not per layer globally)
```
lib/
  features/
    <feature_name>/
      data/
        datasources/       # remote/local data sources (e.g. Juspay, Easebuzz clients)
        models/            # DTOs
        repositories/      # implementations of domain repository interfaces
      domain/
        entities/
        repositories/      # abstract interfaces only, no Flutter imports
        usecases/
      presentation/
        cubit/             # existing Cubit + State, now calling use cases
        screens/
        widgets/
  core/
    network/               # dio client, interceptors
    error/                 # Failure/Exception types
```

Rules:
- `domain/` must be pure Dart — no `package:flutter` imports, no third-party
  SDK imports (Dio, GetIt, etc. stay out of domain). This is what makes it
  unit-testable without a widget test harness.
- Each feature is self-contained. Don't create a global `usecases/` or
  `repositories/` folder outside a feature.
- Every feature's folder structure must be generated from the Mason brick
  in `bricks/feature_brick/` (see Structural Consistency Guardrails below) —
  never hand-created. This is non-negotiable.

## Migration Strategy — Strangler Pattern (feature by feature)
Do NOT big-bang rewrite. Migrate one feature end-to-end before starting the
next:

1. **Write characterization tests first.** Before refactoring any existing
   screen or Cubit, write widget/golden tests that lock in current behavior.
   There are zero tests today — this is the safety net that makes everything
   after it safe. Do not skip this step even under time pressure.
2. Define the domain layer: entities, repository interfaces, use cases. Pure
   Dart. Write unit tests against this layer as you build it, not after.
3. Build the data layer: repository implementations, data sources, models.
   Move any logic currently embedded in screens/services into here.
4. Wire the *existing* Cubit to call the new use cases instead of calling
   services/GetIt directly. Leave the widget tree alone at this step.
5. Only once domain + data are solid and tested, extract remaining inline
   business logic out of the screen widget itself, then delete the old
   direct-service-call code path.
6. Remove this feature's exports from `global_import.dart` and switch its
   consumers to explicit imports — this is part of the feature's definition
   of done, not a separate cleanup pass.
7. Do not move to the next feature until the current one is fully migrated,
   tested, and old code for it is deleted (no dead code left behind).

## Migration Order (do not reorder without asking)
1. **Auth** — `TokenService` is a god-object imported by 29 files across the
   entire app. Do NOT rewrite it wholesale. Freeze its current public API as
   a stable facade, then decompose its internals (login / register / token
   refresh / auth-state broadcast) into separate domain use cases behind
   that facade. The 29 external callers should not need to change during
   this step.
2. **Payments** — highest architectural risk: `checkout_screen.dart` is a
   2,373-line monolith with order creation, subscription creation, payment
   method selection, address handling, and coupon logic all inline. No
   security work needed here (already fixed) — this is purely extraction.
3. **Panchang** — 5 existing Cubits, self-contained, no payment coupling.
   Good practice ground for the Cubit-calls-use-case pattern before tackling
   more tangled features.
4. Remaining features in this order, pausing for confirmation before each:
   Cart → Products + Favorites (together, tightly coupled) → Orders →
   Subscriptions → Notifications → Home/Dashboard → Account/Help/Legal/etc.
   Innovations/Games: no backend logic, consider skipping migration
   entirely — flag to Hemant rather than deciding unilaterally.

## Structural Consistency Guardrails
These exist so that feature 11 doesn't end up architecturally different
from feature 2 just because it was built in a different session. All of
these are mandatory, not aspirational.

1. **Scaffold every feature from the same template.** Use the Mason brick at
   `bricks/feature_brick/` to generate the `data/domain/presentation` skeleton
   for any new feature before writing a single line of feature code. Never
   hand-roll the folder structure.
2. **Run `dart tool/check_architecture.dart` before declaring any feature
   done.** It fails the build on:
   - `domain/` files importing `package:flutter` or any `data/`/`presentation/` path
   - `presentation/` files importing `data/` directly (must go through `domain/`)
   - any file in `lib/features/` exceeding the line-count budget
3. **Definition of done, per feature** (all must be true before moving on):
   - [ ] Scaffolded from `feature_brick`, not hand-created
   - [ ] `dart tool/check_architecture.dart` passes with zero violations
   - [ ] Characterization tests exist and pass
   - [ ] Domain layer has unit test coverage for its use cases
   - [ ] No file in the feature exceeds the line-count budget
   - [ ] Feature's symbols removed from `global_import.dart`; consumers use
     explicit imports
   - [ ] Old pre-migration code path for this feature is deleted
   - [ ] UI is visually and behaviorally identical to pre-migration, except
     for explicitly-flagged and approved state-bug fixes (see UI
     Preservation Rule above)

## Working Agreement for the Agent
- Surgical changes only. Don't refactor code outside the feature currently
  being migrated, even if you notice unrelated issues — flag them instead.
- After finishing a feature's migration, stop and summarize what changed
  before starting the next feature.
- If a decision isn't covered by this file (e.g. naming convention conflicts,
  ambiguous feature boundaries, whether to migrate Innovations/Games at all),
  ask rather than assuming.