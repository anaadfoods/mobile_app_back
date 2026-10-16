# AGENT.md — Anaad Foods Flutter Development Rules

## 1. Purpose

This file defines the permanent development rules for AI coding agents working on the Anaad Foods Flutter application.

**The Clean Architecture migration is already complete. Do not initiate, repeat, or plan another migration unless user explicitly requests it.**

Your responsibility is to maintain the established architecture, implement requested features, fix bugs, write tests, and preserve existing application behavior.

Treat this file as the project's authoritative development instruction. Follow it for every task.

## 2. Mandatory Rules

1. Understand the existing implementation before editing code.
2. Follow the established Clean Architecture structure.
3. Preserve Cubit (`flutter_bloc`) as the state-management solution.
4. Keep business logic out of widgets.
5. Use existing domain use cases and repository interfaces instead of bypassing the architecture.
6. Generate new feature structures using the existing Mason brick.
7. Write and run relevant tests.
8. Preserve existing UI and business behavior unless a change is explicitly requested.
9. Keep changes limited to the requested task.
10. Verify the final implementation using actual command results.
11. Never claim a feature, test, or build succeeded without evidence.
12. Ask User when an important requirement is ambiguous or a decision would change an established contract.

These rules apply to new features, bug fixes, refactoring, and maintenance.

## 3. Established Technology Stack

Use the technologies already present in the repository.

- **Framework:** Flutter
- **Language:** Dart
- **State management:** `flutter_bloc` Cubit
- **Architecture:** Feature-based Clean Architecture
- **Dependency injection:** Existing GetIt configuration, where applicable
- **Testing:** Flutter test framework, `bloc_test`, and `mocktail` where appropriate
- **Feature scaffolding:** Existing Mason brick at `bricks/feature_brick/`

Before introducing a library, inspect `pubspec.yaml` and `pubspec.lock`.

Do not introduce Riverpod, Provider, another state-management framework, or a replacement dependency injection framework without explicit approval.

Do not upgrade dependencies or change the framework version unless the task requires it and the change is approved.

## 4. Architecture Rules

The application follows this dependency direction:

`Presentation → Domain ← Data`

Dependencies point inward. The domain layer must remain independent of infrastructure and presentation.

### 4.1 Presentation layer

Location:

`lib/features/<feature_name>/presentation/`

Contains:
- Cubits and Cubit states.
- Screens.
- Reusable feature widgets.
- Presentation-specific models where necessary.

Rules:

- Cubits receive UI events, invoke domain use cases, and emit states.
- Widgets render state and dispatch user interactions.
- Widgets must not call GetIt, service singletons, data sources, or repositories directly.
- Widgets must not contain business rules, pricing calculations, payment orchestration, authentication logic, or direct API calls.
- Keep Cubits focused on coordinating presentation state.
- Reuse existing state models and conventions where practical.
- Handle loading, success, empty, and failure states consistently with the feature's existing behavior.

Do not move business logic into a Cubit simply because it is easier than creating or using a domain use case.

### 4.2 Domain layer

Location:

`lib/features/<feature_name>/domain/`

Contains:
- Entities.
- Abstract repository interfaces.
- Use cases.
- Domain-specific business rules and failures.

Rules:

- Pure Dart only.
- No `package:flutter` imports.
- No imports from `data/` or `presentation/`.
- No GetIt, Dio, payment SDK, database SDK, or other infrastructure dependencies.
- Use cases must have clear responsibilities and explicit dependencies.
- Repository interfaces belong in the domain layer.
- Business rules must be testable without a widget test harness.

Do not create unnecessary abstractions, duplicate use cases, or empty architectural layers.

### 4.3 Data layer

Location:

`lib/features/<feature_name>/data/`

Contains:
- Data sources.
- DTOs and serialization models.
- Repository implementations.
- External API and SDK integrations.

Rules:

- Repository implementations must satisfy the corresponding domain interfaces.
- Reuse existing network clients, authentication mechanisms, and infrastructure.
- Map external response models into appropriate domain entities.
- Keep API-specific parsing and SDK-specific logic out of the domain.
- Handle expected failures consistently with existing application conventions.
- Avoid duplicate network requests, redundant models, and competing implementations.

### 4.4 Shared infrastructure

Location:

`lib/core/`

Use existing shared modules for concerns such as networking, errors, logging, and other genuinely cross-feature infrastructure.

Before adding a shared abstraction, check whether one already exists.

Do not move feature-specific business logic into `core/` merely to make it accessible globally.

## 5. Required Feature Structure

Follow the existing feature structure:

```text
lib/features/<feature_name>/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── cubit/
    ├── screens/
    └── widgets/
```

Create only the directories and files that the feature actually needs.

**Every new feature must be scaffolded using `bricks/feature_brick/`.**

Before generating a feature:
1. Inspect the Mason brick and its available variables.
2. Follow the repository's existing Mason command and conventions.
3. Generate the feature structure.
4. Verify the output.
5. Implement the feature inside the generated structure.

Never manually invent a parallel feature structure.

If the Mason brick is missing or broken, report the problem and request approval before modifying the shared template or bypassing it.

For existing features, follow their established structure rather than reorganizing them unnecessarily.

## 6. UI and UX Preservation

The existing application UI is intentional and must not be modified as a side effect of unrelated work.

Preserve:
- Layout and widget hierarchy.
- Padding, margins, sizing, and alignment.
- Colors, typography, borders, and shapes.
- Animations and transitions.
- Images, icons, and assets.
- Labels, copy, and error messages.
- Navigation and back-button behavior.
- Loading, success, empty, and error states.
- Existing interactions and accessibility behavior.

When modifying an existing screen, make the smallest necessary change.

Do not redesign, restyle, re-space, rename visible text, replace components, or introduce a new visual pattern unless requested.

When extracting a widget, preserve the existing widget tree and styling as closely as possible.

If an architecture fix or bug fix would change visible behavior, explain the change and ask for approval before implementing it.

Do not treat a passing compilation as proof that the UI is unchanged. Use appropriate widget tests, golden tests, screenshots, or manual verification when available.

## 7. State Management Rules

Cubit remains the presentation state holder.

When implementing a feature:

1. Identify the existing Cubit and state classes.
2. Inspect how the feature currently handles events and state transitions.
3. Reuse existing use cases where possible.
4. Create new use cases only for new or missing domain operations.
5. Inject dependencies through the existing dependency injection setup.
6. Emit consistent loading, success, and failure states.
7. Avoid duplicated or racing state updates.
8. Handle asynchronous operations and errors explicitly.
9. Avoid unnecessary emissions and repeated network requests.
10. Test important state transitions.

Do not replace an existing Cubit with another state-management mechanism.

Do not duplicate business logic across screens, Cubits, and use cases.

Do not change public Cubit state contracts unnecessarily because existing screens or other consumers may depend on them.

## 8. Dependency Injection and Imports

Use the existing GetIt registration conventions where applicable.

- Register dependencies in the appropriate existing configuration.
- Avoid duplicate registrations.
- Avoid circular dependencies.
- Respect initialization order and object lifecycles.
- Do not instantiate infrastructure dependencies directly inside widgets.
- Prefer constructor injection for use cases, Cubits, and repository implementations.

Use explicit imports for feature dependencies.

Avoid adding new dependencies to `global_import.dart`. If the project is eliminating feature exports from this file, follow that convention.

Before removing or changing an export, search for its consumers and update only the necessary imports.

Do not remove existing public symbols or change shared APIs without verifying their consumers.

## 9. Business Logic and Data Integrity

Business rules must have one authoritative implementation wherever practical.

Examples include:
- Authentication and authorization.
- Product and inventory operations.
- Cart calculations.
- Order creation.
- Coupon validation and discount calculations.
- Payment initiation and verification.
- Subscription lifecycle rules.
- Delivery scheduling and status transitions.
- Panchang calculations and related domain rules.

Place these rules in the appropriate domain use cases or domain services according to the existing architecture.

Never duplicate a calculation in the UI if the authoritative rule already exists elsewhere.

Preserve backend contracts, request and response formats, identifiers, currency handling, rounding rules, and transaction semantics.

Do not silently change a business rule to make an implementation easier.

For ambiguous requirements, inspect the existing code and relevant documentation. If the intended behavior remains unclear, ask User.

## 10. Authentication and Payment Security

Existing security fixes must remain intact.

Never:
- Disable TLS certificate verification.
- Store authentication tokens or secrets in plaintext storage.
- Log passwords, access tokens, refresh tokens, payment credentials, or sensitive responses.
- Hard-code secrets in source code.
- Bypass authentication or authorization checks.
- Introduce insecure HTTP payment flows.
- Bypass payment verification.
- Remove idempotency or duplicate-submission protections where implemented.
- Trust client-side payment amounts or payment-success flags without the established server-side verification process.

Use the existing secure storage, network configuration, authentication flow, and payment integrations.

If a task appears to require weakening a security control, stop and explain why the requested approach is unsafe.

## 11. Testing Requirements

Testing is part of implementation, not an optional cleanup step.

For each task, select tests appropriate to the change.

### Domain tests
Test:
- Business rules.
- Input validation.
- Calculations.
- Success and failure outcomes.
- Relevant boundary conditions.

### Data tests
Test:
- Response parsing and mapping.
- Repository behavior.
- Expected error conversion.
- Relevant API and persistence interactions using mocks or fakes.

### Cubit tests
Test:
- Initial state.
- Loading transitions.
- Success states.
- Failure states.
- Important edge cases.
- Duplicate actions or asynchronous behavior when relevant.

### Widget tests
Test:
- Important UI states.
- User interactions.
- Rendering and navigation where appropriate.
- Existing behavior affected by the change.

Use `bloc_test` and `mocktail` where they fit the existing setup.

Tests must be deterministic and must not require real payment transactions, production credentials, or unintended external side effects.

Never weaken tests simply to make them pass.

If a test exposes a real defect, investigate and fix it within the authorized scope. If the correct behavior is ambiguous, ask rather than guessing.

## 12. Architecture and Code Quality Checks

Inspect and use the existing architecture guard:

`dart tool/check_architecture.dart`

Run it after relevant architectural changes and before declaring a task complete.

It should enforce the repository's actual rules, including:
- No Flutter imports in the domain layer.
- No data or presentation imports in the domain layer.
- No direct data-layer imports from presentation.
- Compliance with the configured file-size budget.

Do not change the guard or raise its line-count threshold merely to hide violations.

For relevant changes, run:

```bash
dart format <changed_dart_files>
flutter analyze
dart tool/check_architecture.dart
flutter test
```

Adapt commands to the actual repository and available tooling. Run targeted tests during development and the relevant broader suite before completion.

If a command is unavailable or the existing project has failures, report the exact limitation. Do not claim success without running the command.

Do not reformat unrelated files.

## 13. File Size and Maintainability

Follow the line-count budget enforced by the architecture checker.

When a file becomes too large:
- Identify coherent responsibilities.
- Extract reusable widgets into `presentation/widgets/`.
- Extract domain operations into appropriate use cases.
- Move data access into data sources and repositories.
- Preserve behavior and public contracts.

Do not split files arbitrarily merely to meet a numerical limit.

Do not create excessive one-line wrappers, unnecessary interfaces, or abstractions without meaningful responsibility.

Keep each class and file focused, readable, and testable.

## 14. Scope Control

Only modify what is necessary to complete the requested task.

Before editing:
1. Inspect Git status.
2. Identify the relevant feature and dependencies.
3. Read the relevant implementation.
4. Understand the intended behavior.
5. Identify likely regressions.
6. Determine which tests and checks are required.

During implementation:
- Avoid unrelated refactoring.
- Avoid renaming unrelated symbols.
- Avoid changing unrelated APIs.
- Avoid modifying unrelated features.
- Avoid dependency upgrades unless required and approved.
- Preserve existing user changes.

After implementation:
- Review the complete diff.
- Remove accidental changes and unused imports.
- Check for duplicate implementations and dead code introduced by the task.
- Confirm that all modifications belong to the requested scope.

Never overwrite user changes or run destructive Git commands.

Do not commit, push, or change branches unless explicitly instructed.

## 15. Error Handling and Logging

Follow existing application conventions for exceptions, domain failures, and error messages.

- Do not silently swallow unexpected exceptions.
- Avoid broad exception handling that hides failures.
- Translate infrastructure errors at the appropriate boundary.
- Keep internal stack traces and sensitive data out of user-facing messages.
- Use existing logging infrastructure where available.
- Do not introduce noisy debug logging into production paths.
- Preserve existing error messages and recovery behavior unless a change is requested.

## 16. When to Ask for Approval

Ask User before proceeding if:
- Requirements are ambiguous.
- A public API or shared contract must change incompatibly.
- A change affects multiple unrelated features.
- A visual change is necessary but not requested.
- A security control would need to change.
- A database migration could affect existing data.
- A dependency or framework upgrade is required.
- The Mason brick or architecture guard must be modified.
- A requested fix requires a product decision.
- Existing user changes conflict with the requested implementation.
- The available tests cannot establish the intended behavior reliably.

Do not ask unnecessary questions when the existing code and requirements clearly establish the answer.

When asking, state the problem, relevant files, observed evidence, proposed solution, and the decision required.

## 17. Required Completion Report

After every substantial task, report:

### Summary
Describe what was implemented or fixed.

### Files changed
List the important files and their responsibilities.

### Architecture
Explain how the change follows the existing feature structure and dependency direction.

### Tests
List the tests added or modified and their results.

### Verification
Report the exact status of:
- Formatting.
- Static analysis.
- Architecture guard.
- Relevant tests.
- Build or compilation checks, where applicable.

Use `PASS`, `FAIL`, `BLOCKED`, or `NOT RUN` accurately.

### Remaining issues
Identify incomplete work, known limitations, and any unverified behavior.

### UI impact
State whether visible behavior changed. If it did, explain whether the change was explicitly requested and approved.

Never report a check as passing based on assumptions or code inspection alone.

## 18. Final Operating Principle

**Maintain the architecture. Do not migrate it again.**

Implement the requested change with the smallest reliable set of modifications.

Prefer existing abstractions over duplicate implementations. Prefer tested business logic over logic embedded in widgets. Prefer evidence over assumptions.

Preserve working behavior, protect existing security controls, verify your changes, and ask when a decision belongs to User.

These rules apply to every future development task in the Anaad Foods Flutter repository.