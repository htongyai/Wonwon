# App Improvement List

Audit of the rest of the app with actionable improvements, ordered by impact and effort.

---

## 1. Security & configuration

### 1.1 Firebase / API keys in source (High)
- **Where:** `lib/firebase_options.dart` – Firebase `apiKey` and other config are hardcoded.
- **Risk:** Keys can leak via version control or builds.
- **Action:** Use Flutter’s `--dart-define` or a config file that is gitignored (e.g. from CI/env). Keep `firebase_options.dart` as a generated file from FlutterFire CLI with placeholders or env-based values.

### 1.2 Restrict Firebase config to web if needed
- **Where:** `firebase_options.dart` – Only `web` is configured; other platforms throw.
- **Action:** If the app is web-only, document it. If you add mobile later, run FlutterFire CLI for those platforms.

---

## 2. Error handling & logging

### 2.1 Two parallel error-handling systems (Medium)
- **Where:** `lib/utils/error_handler.dart` (generic, string-based) and `lib/services/error_handling_service.dart` (typed `NetworkError` / `AuthError` / `ValidationError`).
- **Action:** Pick one approach: either standardize on `ErrorHandlingService` + typed errors and call it from UI, or use `ErrorHandler.handleError` everywhere and retire the other. Reduces confusion and duplicate SnackBar/dialog logic.

### 2.2 ErrorHandlingService TODOs (Medium)
- **Where:** `lib/services/error_handling_service.dart`
  - `_checkConnectivity()` – always returns `true` (TODO).
  - `_clearAuthData()` – empty (TODO).
  - `_navigateToLogin(context)` – empty (TODO).
  - “Open network settings” – only pops dialog (TODO).
- **Action:** Implement or remove: e.g. use `connectivity_plus` for connectivity, call your auth/logout and then `Navigator` to login, and use `url_launcher` or platform channels for settings.

### 2.3 ErrorLogger TODOs (Low)
- **Where:** `lib/utils/error_logger.dart` – “Implement proper error reporting service integration” and “Implement your error reporting service here”.
- **Action:** Wire to a real service (e.g. Firebase Crashlytics, Sentry) or remove the placeholder and log only locally for now.

### 2.4 Replace `print` with `debugPrint` (Low)
- **Where:** `lib/screens/forum_screen.dart` (lines 274, 277, 477, 480), `lib/screens/main_navigation.dart` (45–46, 63), `lib/widgets/notification_sidebar.dart` (74).
- **Action:** Use `debugPrint(...)` or your `appLog` so production builds don’t print to console and you comply with `avoid_print`.

### 2.5 Catch clauses (Low)
- **Where:** Many `catch (e)` with no type (e.g. `shop_detail_screen`, `home_screen`, `main_navigation`, `notification_sidebar`).
- **Action:** Prefer `catch (e, stackTrace)` and/or `on Object catch (e)` (and log `stackTrace` where useful). Aligns with `avoid_catches_without_on_clauses` if you enable it.

---

## 3. Code quality & consistency

### 3.1 Unused dependencies (Low)
- **Where:** `pubspec.yaml` – `get_it: ^7.6.7` and `flutter_bloc: ^8.1.4` are not imported in `lib/`.
- **Action:** Remove them if you don’t plan to use them soon, or add a single use (e.g. one screen with Bloc or one service registered with GetIt) and document the intended pattern.

### 3.2 Admin / feature TODOs (Medium)
- **Where:**
  - `lib/screens/admin_unapprove_pages_screen.dart` – “Implement getUnapprovedShops”, “Implement approve shop”, “Implement reject shop”.
  - `lib/screens/admin_manage_users_screen.dart` – “Implement delete user functionality”.
  - `lib/screens/forum_topic_detail_screen.dart` – “Add share functionality”.
- **Action:** Either implement these flows or mark them as “not in scope” and hide/disable the UI that depends on them.

### 3.3 Duplicate main entry (Low)
- **Where:** `lib/main.dart` and `lib/main_optimized.dart` both exist.
- **Action:** Use one entry (e.g. `main.dart`) and move any “optimized” differences (e.g. performance or loading) into that flow. Document in README which file to run.

---

## 4. Accessibility

### 4.1 Semantics (Medium)
- **Where:** No `Semantics` or `semanticLabel` / `semanticsLabel` usage found in `lib/`.
- **Action:** Add semantics for key actions (buttons, links, form fields, list items) and for important regions (headers, main content). Improves screen-reader and accessibility testing.

### 4.2 Text scaling (Already noted in UI audit)
- **Where:** `lib/main.dart` – `TextScaler.linear(1.0)` overrides system font size.
- **Action:** Prefer respecting `MediaQuery.textScaleFactorOf(context)` (with a max cap if needed) for accessibility.

---

## 5. Testing

### 5.1 Test coverage (Medium)
- **Where:** Only a few tests under `test/` (e.g. `date_utils_test`, `validation_utils_test`, `responsive_test`, `widget_test`). No integration tests for critical flows.
- **Action:** Add unit tests for services (auth, shop, forum) and key utils; add integration tests for login, navigation, and one main flow (e.g. view shop detail or create topic).

### 5.2 Error and loading states (Low)
- **Action:** Add tests that simulate network/errors and loading states so error handling and loading UIs don’t regress.

---

## 6. Navigation & routing

### 6.1 Imperative navigation only (Low)
- **Where:** Heavy use of `Navigator.push(MaterialPageRoute(...))` and `Navigator.pop`; no single routing table or named routes.
- **Action:** Consider a small routing layer (e.g. named routes + a map, or go_router) for deep links, analytics, and consistent “back” behavior. Optional; only if you need structure or web URLs.

---

## 7. Performance & maintenance (already partially done)

- Responsive layout and breakpoints are standardized; `ResponsiveSize` re-inits on size change.
- Performance monitoring is debug-only; `PerformanceMonitor` has capped storage.
- Web reload is conditional; no `dart:html` on mobile.

### 7.1 Large files (Low)
- **Where:** e.g. `shop_detail_screen.dart`, `admin_manage_shops_screen.dart`, `home_screen.dart` are very long.
- **Action:** Extract widgets and helpers (e.g. “shop header”, “admin row”, “home sections”) into separate files to improve readability and testing.

---

## 8. Localization

### 8.1 Hardcoded strings (Low)
- **Where:** Many screens still use raw English (e.g. “Loading...”, “Retry”, “Dismiss”, “Try Again”) instead of `.tr(context)` or `AppLocalizations`.
- **Action:** Move user-visible strings into localization and use the same mechanism everywhere (e.g. `app_localizations` or your wrapper).

---

## Summary table

| Priority | Area              | Item                          | Effort (rough) |
|----------|-------------------|-------------------------------|----------------|
| High     | Security           | Firebase keys not in repo     | Medium         |
| Medium   | Error handling     | Unify ErrorHandler vs Service | Medium         |
| Medium   | Error handling     | Implement ErrorHandlingService TODOs | Medium  |
| Medium   | Admin/features    | Implement or hide admin TODOs | Medium         |
| Medium   | Accessibility      | Add Semantics                 | Medium         |
| Medium   | Testing            | Unit + integration tests      | High           |
| Low      | Logging            | Replace print with debugPrint | Small          |
| Low      | Dependencies       | Remove or use get_it/bloc     | Small          |
| Low      | Catch clauses      | Use typed catch + stackTrace  | Small          |
| Low      | Entry point        | Single main (main vs main_optimized) | Small   |
| Low      | Files              | Split very large screens      | Medium         |
| Low      | Localization       | Replace hardcoded strings     | Ongoing        |

Use this list to pick the next sprint items (e.g. security first, then error-handling unification, then accessibility and tests).
