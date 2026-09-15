# Anaad Flutter: UX and Reliability Implementation Plan

## 1. Objective

Make the Anaad customer app feel calm, fast, clear, and dependable from launch through post-purchase support. The work must preserve existing business rules and API contracts while making every important user journey usable on small phones, large text settings, slow networks, and intermittent connectivity.

The customer app remains a consumer-facing application. Sutra is the source of truth for product, order, analytics, notification, and support data. Admin and customer-care staff use the Sutra frontend to inspect event logs and send notifications; Flutter receives and presents those customer notifications only. Do not create a separate Flutter-owned data store for those records.

## 2. Product Principles

1. **Clarity before decoration.** A user must always know what screen they are on, what data is loading, and what action will happen next.
2. **No dead ends.** Empty, error, unauthenticated, offline, and expired-session states must explain the situation and offer a safe recovery action.
3. **Trust around money and delivery.** Cart, checkout, payment, subscription, order, and cancellation states must prevent duplicate actions and state the current outcome precisely.
4. **Fast by default.** Avoid unnecessary startup requests, expensive blur effects, oversized images, and long animations.
5. **Accessible is usable.** Every core flow must work with screen readers, large text, keyboard navigation where applicable, sufficient contrast, and reduced-motion settings.
6. **One visual language.** Shared tokens and components are preferred over one-off styling in individual screens.

## 3. Scope and Non-Goals

### In scope

- Customer-facing Flutter screens, widgets, navigation, loading/error/empty states, and UI-level reliability.
- REST/WebSocket/push integration required for Sutra-originated notifications.
- Instrumentation required to measure crashes, performance, UI failures, and user-flow completion.
- Android, iOS, and supported desktop/web layouts already targeted by the application.

### Out of scope

- Building the Sutra admin/customer-care dashboard in Flutter.
- Changing commercial rules, pricing logic, order lifecycle rules, payment-gateway contracts, or backend data ownership without an approved backend task.
- A wholesale rebrand that discards the existing Anaad green/parchment/amber identity.

## 4. Delivery Rules for Every Agent

- Work in small, independently testable pull requests. Do not mix visual refactors with unrelated API or database changes.
- Reuse `AppTheme`, `AppColors`, `AppSpacing`, and shared widgets before adding local colors, sizes, shadows, loaders, or buttons.
- New asynchronous UI must explicitly handle: initial loading, refresh/loading-more, success, empty, recoverable error, terminal error, and submitting/disabled action state.
- Treat backend payloads as untrusted: validate required values, use safe fallbacks for absent images/text, and never crash on an optional field.
- Never place network requests directly in `build`; use Cubits/use cases and lifecycle-safe calls.
- Avoid unbounded rebuilds: use `BlocSelector`, `buildWhen`, const widgets, keyed lists, and cached image widgets where appropriate.
- Do not introduce a new state-management or routing library. The app already uses `flutter_bloc`, `get_it`, and `go_router`.
- Preserve existing routes, deep-link behavior, analytics event names, and API request shapes unless a separately approved migration changes them.

## 5. Implementation Phases

### Phase 0 — Baseline and safety rails

**Goal:** know the current quality level before changing behavior.

Tasks:

1. Run and record `flutter pub get`, `dart format --output=none lib test`, `flutter analyze`, and existing widget/unit tests.
2. Create a screen inventory: owner, route, core user journey, current state handling, data source, and priority.
3. Capture reference screenshots for light/dark mode, 360 px width, tablet width, and 200% text scale for core journeys.
4. Audit the current app for duplicate button, skeleton, image, empty-state, error-state, currency-formatting, and animation implementations.
5. Add CI quality gates: formatting, analyzer, unit/widget tests, and a release build for Android at minimum.

Exit criteria:

- Baseline failures are documented and assigned.
- CI blocks new analyzer errors and formatting violations.
- The prioritized screen inventory is available to the team.

### Phase 1 — UI foundation and shared primitives

**Goal:** make new and existing screens consistent without a redesign per screen.

Tasks:

1. Consolidate design tokens in `lib/core/theme/`:
   - semantic colors for surface, text, success, warning, error, disabled, and focus;
   - spacing, radius, elevation, type scale, and standard control heights;
   - light and dark theme parity;
   - platform-appropriate page transitions and scroll behavior.
2. Establish/finish shared widgets in `lib/common_widgets/`:
   - primary, secondary, destructive, and loading buttons;
   - section headers and app bars;
   - network image with loading, error, alt text, and crop behavior;
   - skeleton loading layouts;
   - empty and error states with retry actions;
   - confirmation dialog and snackbar/toast conventions.
3. Support user preferences:
   - respect `MediaQuery.disableAnimationsOf(context)`;
   - permit text scaling to 2.0 without clipping;
   - provide semantic labels/tooltips for icon-only controls;
   - ensure touch targets are at least 48x48 logical pixels.
4. Replace repeated raw `CircularProgressIndicator`, `CachedNetworkImage`, `ElevatedButton`, color literals, and one-off shadows in priority screens with the shared primitives.

Exit criteria:

- The shared component catalog is documented with usage examples.
- New screens do not introduce duplicate loading/error/image/button patterns.
- Light/dark and large-text visual checks pass for the shared primitives.

### Phase 2 — Discovery and product browsing

**Priority screens:** splash/session restore, dashboard shell, home, search, category, product list, product detail, favorites.

Tasks:

1. Keep app startup light: restore authentication first; defer feature data fetches until the owning screen becomes active.
2. Make the dashboard navigation clear and persistent. Preserve cart badge, selected state, labels, and accessible semantics.
3. Use content-shaped skeletons for home, product grids, categories, and lists. Do not show a blank page or a centered spinner for collection loading.
4. Make search resilient: debounced requests, cancellation/last-request-wins behavior, clear empty result state, retry on error, keyboard `search` action, and no request for blank queries.
5. Use consistent product cards: image fallback, product name, price, unit, stock state, discount clarity, favorite state, and a single predictable add-to-cart interaction.
6. Support slow networks with pull-to-refresh, last visible content retained during refresh, and errors that do not erase already loaded results.

Exit criteria:

- A user can browse, search, favorite, and add a product to cart with loading and failure states that remain understandable.
- No product screen crashes on missing image, price, category, or optional metadata.

### Phase 3 — Cart, address, checkout, payment, and subscriptions

**Goal:** remove uncertainty in the highest-risk transactions.

Tasks:

1. Cart:
   - make quantity changes optimistic only when safely reversible;
   - prevent repeat taps while a line-item mutation is pending;
   - show an undo affordance for removal where supported;
   - make total, savings, item count, and checkout CTA continuously visible and accurate.
2. Address and delivery:
   - validate each required field inline and on submit;
   - preserve in-progress form data through recoverable errors;
   - clearly explain unavailable delivery locations/dates.
3. Checkout:
   - use structured skeleton loading rather than a blank spinner;
   - make address, order summary, delivery charge, payment method, and total visually scannable;
   - lock the submit action while it is processing and show a meaningful status such as “Securing order…”;
   - block back navigation only while it would create an ambiguous payment state;
   - after payment returns, verify server-side status before showing success.
4. Idempotency and recovery:
   - every create-order/create-subscription/payment verification request must carry or receive an idempotency reference from the backend contract;
   - after interruption, reopen the latest backend-confirmed order/subscription state instead of guessing;
   - show a pending-payment state if confirmation is delayed, with refresh and support actions.
5. Subscriptions:
   - distinguish one-time cost, installment, due-now amount, renewal cadence, pause/cancel impact, and next delivery;
   - require confirmation for irreversible actions;
   - show action progress inline and refresh the backend-confirmed result.

Exit criteria:

- Rapid repeated taps cannot create duplicate local submissions.
- Payment success/failure/pending states are mutually exclusive, server-confirmed, and recoverable after relaunch.
- Cart and checkout remain usable at large text scale without clipped totals or hidden CTAs.

### Phase 4 — Post-purchase, account, and support

**Priority screens:** orders, order detail/tracking, account, profile, address book, help, notification settings, notifications.

Tasks:

1. Standardize order states: loading, no orders, active order, delivered, cancelled, failed, and retryable network error.
2. Show order lifecycle clearly with human-readable statuses, timestamps, delivery window, payment state, products, support route, and safe cancellation eligibility.
3. Preserve account/profile data when refresh fails; use skeletons only for first load and compact refresh indicators thereafter.
4. Ensure support actions (call, email, WhatsApp, help form) display the selected order reference and report launcher failures gracefully.
5. Make notification settings explicit: channels, consent choices, quiet hours if supported by Sutra, and privacy explanation.

Exit criteria:

- Users can understand order status and reach support from every post-purchase state.
- Profile, address, and support forms preserve entered data on recoverable failure.

### Phase 5 — Sutra notification delivery in Flutter

**Goal:** reliably surface messages sent by Sutra admins/customer-care staff without duplicating ownership in Flutter.

Contract requirements with Sutra backend:

- An authenticated notifications endpoint returning paginated notification records owned by the authenticated user.
- Stable notification fields: `id`, `title`, `body`, `type`, `created_at`, `is_read`, optional `deep_link`, optional order/subscription reference, and optional action payload.
- Idempotent upsert key (`id` or server event ID) so push and REST synchronization cannot duplicate a message.
- Read/dismiss endpoints that are idempotent and return the latest state.
- Firebase push payload includes the stable notification ID and a safe deep link; Flutter fetches the canonical record before acting on sensitive data.

Flutter tasks:

1. On app start and app resume, sync notifications after authentication; do not block first meaningful content on this request.
2. Store only a local cache for offline presentation. Sutra remains canonical; reconcile after reconnecting.
3. Support foreground, background, and terminated push handling. Route using `go_router` only after auth/session state is resolved.
4. Notification list behavior:
   - skeleton on first load, pull-to-refresh thereafter;
   - unread visual treatment and accessible unread announcement;
   - mark read on opening/tapping;
   - confirm “clear all”; allow individual dismiss; never assume deletion means a backend event was erased;
   - graceful fallback when a deep-linked order/product no longer exists.
5. Track delivery/display/open/deep-link-success events using the approved analytics contract, without storing sensitive message text in analytics.

Exit criteria:

- A notification sent from Sutra appears once in Flutter, survives app restart, and opens the correct permitted destination.
- Duplicate push delivery and REST re-sync do not create duplicate rows.
- A signed-out or expired user never sees another user’s cached notification content.

### Phase 6 — Reliability, performance, and observability

Tasks:

1. Network layer:
   - centralize timeouts, auth refresh, request IDs, error mapping, and retry policy in the existing Dio/data-source layer;
   - retry only idempotent reads automatically, with bounded exponential backoff and jitter;
   - never silently retry non-idempotent writes unless the server contract explicitly supports it.
2. Session and security:
   - store tokens only in secure storage;
   - clear user-scoped caches on logout/account change;
   - handle 401 once through controlled refresh/logout flow instead of looping.
3. Performance:
   - profile app launch, home scroll, product list scroll, cart mutation, and checkout on a representative low/mid-range Android device;
   - use image dimensions/cache limits, list virtualization, const widgets, selectors, and repaint boundaries where profiling proves value;
   - remove unnecessary full-screen blur, long continuous animation, and expensive rebuilds.
4. Observability:
   - capture crashes and non-fatal UI/API failures with sanitized context;
   - record screen load time, API latency/error rate, checkout submission/pending/success/failure, and notification lifecycle events;
   - define dashboards and alert thresholds with the backend/product team.

Exit criteria:

- No infinite refresh/retry loops.
- User-scoped cache is cleared on logout.
- Core journey performance and failure metrics are available in the agreed monitoring tool.

## 6. Testing Strategy

### Unit tests

- Cubit transitions for loading/success/empty/error/submitting states.
- Price, delivery charge, subscription cadence, and status mapping calculators.
- Notification deduplication, deep-link parsing, read/dismiss idempotency, and logout cache clearing.
- Repository error mapping, timeout, and retry rules.

### Widget tests

- Shared button disabled/loading/semantic behavior.
- Product image fallback, long product names, missing price, and out-of-stock card states.
- Text scaling at 1.0, 1.3, 1.6, and 2.0.
- Empty/error/skeleton states for products, cart, orders, account, and notifications.
- Checkout submit lock and pending-payment display.

### Integration tests

1. Restore session → browse product → add to cart → address → checkout → confirmed order.
2. Failed/slow network during product loading, cart mutation, and checkout recovery.
3. Push notification while foreground/background/terminated → authenticated deep link.
4. Log out → log in as another account → verify no previous account data or notifications remain.

### Manual release checklist

- Android and iOS physical-device smoke test.
- Light/dark mode and 200% text scale.
- Screen reader pass for navigation, cart, checkout, and notifications.
- Airplane mode / reconnect test.
- Payment cancel, payment failure, payment success, and delayed payment confirmation.

## 7. Priority Order and Suggested Pull Requests

1. **PR 1: Quality baseline and CI** — analyzer/test gates, inventory, screenshot baseline.
2. **PR 2: Shared UI primitives** — theme, buttons, images, loading/empty/error, semantics helpers.
3. **PR 3: App shell and discovery** — startup, dashboard navigation, home/search/product/favorites.
4. **PR 4: Cart and checkout reliability** — cart state, address validation, submit locking, payment recovery.
5. **PR 5: Orders, subscriptions, account, and support** — post-purchase hierarchy and recoverable forms.
6. **PR 6: Sutra notifications** — API contract integration, local cache, FCM lifecycle, deep links, tests.
7. **PR 7: Performance and accessibility hardening** — profiling fixes, device checks, accessibility audit.

Each PR must include before/after screenshots for changed screens, tests appropriate to the change, migration notes if API behavior changes, and a rollback note for risky transaction/push changes.

## 8. Definition of Done

A screen or feature is complete only when:

- it uses established theme tokens and shared primitives;
- loading, empty, error, offline, and submit states are implemented;
- important controls have labels, touch targets, and keyboard/screen-reader behavior;
- it works at 200% text scale without overflow or hidden critical actions;
- success shown to the user represents backend-confirmed state for transactions;
- relevant unit/widget/integration tests pass;
- no new analyzer warnings are introduced;
- screenshots are reviewed in light and dark themes;
- telemetry is added for material failures or conversion steps without exposing personal/sensitive data.

## 9. Success Metrics

- Crash-free sessions: at least 99.5%.
- Core API failure visibility: 100% of failed checkout/order/notification sync operations are observable.
- Checkout duplicate submission rate: 0.
- Notification duplicate display rate: 0.
- Screen-reader and 200% text-scale completion of core shopping flow: 100% in release QA.
- Median home/product-list first meaningful content and scroll frame time: baseline first, then improve against measured target on representative devices.
- Reduced support contacts caused by ambiguous payment/order state, measured through Sutra support categories.
