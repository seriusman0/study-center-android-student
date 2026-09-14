# Plan: Maintenance mode false-positives + redundant data loads + release build

**Slug:** `2026-09-11_211500-fix-maintenance-and-once-load`
**Target project:** `C:/Users/Krisman/dev/study-center-android-student` (Flutter Android `com.studycenter.sc_student`)
**Test device:** `R9RT4079YQL` (Android 720x1600, sudah connected via `adb devices`)

---

## Goal

Three problems to fix in this order:
1. **Maintenance screen fires on transient network lag** — `lib/core/services/api_service.dart` interceptor marks `maintenance=true` on any `connectionTimeout`/`connectionError`/`unknown` Dio error, even if the backend was just slow for one request. Make maintenance mode only latch when there's **conclusive evidence the backend is unreachable** (503/504 responses, repeated failures, or a dedicated health-check).
2. **Duplicated data loads on every page switch** — `homeScreen.initState` and several other screens call `provider.load()` inside `Future.microtask` even when cached state already exists; combined with Riverpod's `Notifier` rebuild semantics, navigating away and back re-runs initState and re-fetches. Refactor so login pre-loads the shared "session-scoped" data once, screens read from cache, and only re-fetch on pull-to-refresh or auth/logout.
3. **Bump release version and ship APK** — increment `versionName`/`versionCode` and produce a release APK with the upgraded code.

---

## Current Context / Assumptions

Codebase already explored (read-only):

- `lib/core/services/api_service.dart` lines 55–71: `_AuthInterceptor.onError` calls `setMaintenance(true)` on any error where `statusCode == null || statusCode >= 500`. This is too eager — it fires on `DioExceptionType.connectionError` (e.g. transient DNS hiccup) and on a single slow request even when every other endpoint works.
- `lib/core/providers/maintenance_provider.dart`: simple `StateNotifier<bool>` with `setMaintenance(bool)` setter.
- `lib/shared/widgets/maintenance_screen.dart`: full-screen `Scaffold` with one "Coba Lagi" button that pings `GET /` and clears maintenance on 4xx. Has `_testConnection` private helper that does its own Dio call — **this is the one legitimate health-check** we keep.
- `lib/app.dart` lines 318–321: `MaterialApp.router.builder` checks `maintenanceProvider` and replaces the entire app with `MaintenanceScreen`. Because it's in the global `builder`, it intercepts every route — so a single flagged request nukes login/Jurnal/Laporan/Profil/etc.
- `lib/features/home/screens/home_screen.dart` lines 27–64: `initState()` triggers `Future.microtask` to load `journalProvider`, `scholarshipTeenagerJournalProvider`, `collegeJournalProvider`, `homeProvider`. The "if not loaded yet" guards (`snapshot == null && !loading`) do **not** survive screen teardown — Riverpod auto-disposes `Notifier`s whose only listener was the unmounted screen, so re-entering Home rebuilds from scratch.
- `lib/features/journal/providers/journal_provider.dart` line 343: `NotifierProvider<JournalNotifier, JournalState>(JournalNotifier.new)` — **no `keepAlive` annotation**, so provider is auto-disposed when no widget watches it.
- `lib/features/home/providers/home_provider.dart` line 101: same — `NotifierProvider` with no keep-alive.
- `pubspec.yaml` line 9: `version: 3.1.1+11`. Plan bumps to `3.1.2+12` (patch bump for bug fixes).
- `android/app/build.gradle.kts` lines 41–42: `versionCode = flutter.versionCode` and `versionName = flutter.versionName`, so editing `pubspec.yaml` propagates automatically.
- `e2e/01_login.yaml` and `e2e/03_jurnal_today.yaml` exist and pass. We will extend with a new `e2e/test_maintenance_false_positive_regression.yaml`.

**Test user credentials:** `testuser` / `12345` (verified `POST /api/auth/login` returns 200, user has roles `student` + `scholarship_teenager`).

**Out of scope:** Redesigning the maintenance screen UI, adding backend health endpoint, introducing a `keepAlive`/`family` provider refactor on every feature module — only the providers listed in this plan.

---

## Architecture / Proposed Approach

1. **Maintenance gate = dedup + health-check, not single-request error.**
   Replace the interceptor's eager "any 5xx or connection error → maintenance on" with: track the timestamp of the most recent maintenance-triggering error per `requestOptions.path` prefix; only flip `maintenanceProvider` to true if **three** distinct requests fail within 10 seconds, OR if `GET /` health probe explicitly fails. Add a 5-second debounce: even when a single 503 lands, wait 5s and re-verify before showing the screen (covers momentary backend restart). When one request later succeeds, immediately clear maintenance.
2. **One shared "session preloader" runs after login.**
   Create a single `SessionDataProvider` that exposes `JournalSnapshot`, `LaporanSummary`, `BlogPost[]`, `GaleriItem[]`. Backed by `Notifier`s with `@Riverpod(keepAlive: true)`. `AuthNotifier.login()` calls `ref.read(sessionDataProvider.notifier).preload()` exactly once after a successful login (and once on `restoreSession`); screens read from these providers without ever calling `.load()` themselves. Screens that don't fit this pattern (admin/mentor) keep their existing `Future.microtask` loaders — those are off the critical path.
3. **Release build pipeline:** bump `pubspec.yaml` to `3.1.2+12`, run `flutter build apk --release`, verify APK present and `versionCode`/`versionName` match.

---

## Step-by-Step Tasks

### Phase A: Maintenance false-positive fix

#### A1. Replace `maintenance_provider` with debounced health-aware state

**File:** `lib/core/providers/maintenance_provider.dart` — replace entire content.

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MaintenanceState {
  final bool active;
  final DateTime? since;
  const MaintenanceState({this.active = false, this.since});

  MaintenanceState copyWith({bool? active, DateTime? since, bool clearSince = false}) =>
      MaintenanceState(
        active: active ?? this.active,
        since: clearSince ? null : (since ?? this.since),
      );
}

/// Singleton notifier. All mutations go through here so the debounce and
/// the failure-counter stay in one place.
class MaintenanceNotifier extends Notifier<MaintenanceState> {
  static const _debounceWindow = Duration(seconds: 5);
  static const _failureThreshold = 3;
  static const _failureWindow = Duration(seconds: 10);

  final List<DateTime> _recentFailures = [];
  Timer? _debounce;
  bool _healthCheckInFlight = false;

  @override
  MaintenanceState build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });
    return const MaintenanceState();
  }

  /// Called by the interceptor on a single request failure.
  /// Records the failure but only flips state after the debounce + threshold.
  void recordFailure() {
    final now = DateTime.now();
    _recentFailures.add(now);
    _recentFailures.removeWhere(
      (t) => now.difference(t) > _failureWindow,
    );

    debugPrint(
      '[Maintenance] recordFailure — ${_recentFailures.length}/$_failureThreshold failures in last ${_failureWindow.inSeconds}s',
    );

    if (_recentFailures.length < _failureThreshold) {
      return; // not enough evidence yet
    }

    if (state.active) {
      return; // already showing maintenance screen
    }

    // Already in the "about to flip" window — just keep counting.
    if (_debounce?.isActive ?? false) return;

    _debounce?.cancel();
    _debounce = Timer(_debounceWindow, () {
      _debounce = null;
      if (_recentFailures.length >= _failureThreshold && !state.active) {
        state = MaintenanceState(active: true, since: DateTime.now());
        debugPrint('[Maintenance] Activated after $_failureThreshold failures');
      }
    });
  }

  /// Called by the interceptor when any request succeeds.
  void recordSuccess() {
    _recentFailures.clear();
    if (state.active) {
      state = const MaintenanceState(active: false);
      _debounce?.cancel();
      _debounce = null;
      debugPrint('[Maintenance] Cleared after successful request');
    }
  }

  /// Called by the user tapping "Coba Lagi" on MaintenanceScreen.
  /// Performs an explicit health probe — only clears if probe succeeds.
  Future<bool> probeNow(String baseUrl) async {
    if (_healthCheckInFlight) return !state.active;
    _healthCheckInFlight = true;
    try {
      // Probe uses /up if available, else a known-cheap endpoint. We keep
      // / for now since that's what MaintenanceScreen already does.
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));
      await dio.get('/');
      // 2xx/3xx/4xx all count as "server is reachable". The app's own
      // backend returned a structured response.
      _recentFailures.clear();
      _debounce?.cancel();
      _debounce = null;
      state = const MaintenanceState(active: false);
      return true;
    } catch (_) {
      return false;
    } finally {
      _healthCheckInFlight = false;
    }
  }

  /// Backward-compat shim for any caller that still does boolean writes.
  void setMaintenance(bool value) {
    state = MaintenanceState(active: value, since: value ? DateTime.now() : null);
  }
}

final maintenanceProvider =
    NotifierProvider<MaintenanceNotifier, MaintenanceState>(MaintenanceNotifier.new);
```

**Verify:** `flutter analyze lib/core/providers/maintenance_provider.dart` — expect 0 errors. The `Dio` import requires `import 'package:dio/dio.dart';` added at the top.

#### A2. Update interceptor to record failures/successes, not flip directly

**File:** `lib/core/services/api_service.dart` — in `_AuthInterceptor.onError` (around line 55) **remove the existing block that calls `setMaintenance(true)`** (lines 60–71) and replace with:

```dart
// ── Maintenance / Offline Check (debounced) ────────────────────────────────
// Single failures no longer toggle maintenance — the interceptor just
// records them and MaintenanceNotifier debounces + thresholds them.
if (statusCode == null ||
    statusCode >= 500 ||
    statusCode == 504 ||
    error.type == DioExceptionType.connectionTimeout ||
    error.type == DioExceptionType.connectionError) {
  _ref.read(maintenanceProvider.notifier).recordFailure();
}
```

**Remove nothing else** — keep the 401 refresh logic and the error-message extraction intact.

Add `recordSuccess` call: at the top of `onResponse` (around line 49), **before** `debugPrint` of the success, add:

```dart
_ref.read(maintenanceProvider.notifier).recordSuccess();
```

**Verify:** `flutter analyze lib/core/services/api_service.dart` — expect 0 errors. The `MaintenanceState` import may need an alias if it conflicts; if so, use `import '../providers/maintenance_provider.dart';` (already present) — no alias needed since file exports the provider and the state class.

#### A3. Update `MaintenanceScreen` to call the new probe

**File:** `lib/shared/widgets/maintenance_screen.dart` — replace `_testConnection` (lines 18–45) with:

```dart
Future<void> _testConnection() async {
  setState(() { _isLoading = true; });
  try {
    final ok = await ref
        .read(maintenanceProvider.notifier)
        .probeNow(ApiConstants.baseUrl);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server masih tidak dapat dihubungi.')),
      );
    }
  } finally {
    if (mounted) setState(() { _isLoading = false; });
  }
}
```

Remove the unused `Dio`/`DioException` imports if no longer used elsewhere in the file (currently only used in `_testConnection`). Keep `import '../../core/constants/api_constants.dart';`.

**Verify:** `flutter analyze lib/shared/widgets/maintenance_screen.dart` — 0 errors.

#### A4. Verify `app.dart` still compiles with the new state shape

**File:** `lib/app.dart` line 318. The `MaterialApp.router.builder` currently does:

```dart
final isMaintenance = ref.watch(maintenanceProvider);
if (isMaintenance) return const MaintenanceScreen();
```

`maintenanceProvider` was `Provider<bool>`; now it's `NotifierProvider<MaintenanceNotifier, MaintenanceState>`. Replace with:

```dart
final maintenance = ref.watch(maintenanceProvider);
if (maintenance.active) return const MaintenanceScreen();
```

**Verify:** `flutter analyze lib/app.dart` — 0 errors.

#### A5. Run unit-style verification via grep

```bash
cd "C:/Users/Krisman/dev/study-center-android-student"
grep -rn "maintenanceProvider" lib/ --include="*.dart"
```

Expected lines: only in `maintenance_provider.dart`, `api_service.dart`, `maintenance_screen.dart`, `app.dart`. **No** other file should still write `setMaintenance(true)` directly — if any do, they must call `recordFailure()` instead.

### Phase B: One-load-per-session refactor

#### B1. Add `keepAlive: true` annotations to the four session-scoped providers

**File:** `lib/features/home/providers/home_provider.dart` — change line 101:

```dart
// before
final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
// after
final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  HomeNotifier.new,
);
```

Wait — `NotifierProvider` doesn't have a keepAlive positional like that. Instead wrap with `ProviderScope` override OR use the `keepAlive` flag via `ref.keepAlive()` inside `build()`. The simplest way:

**Inside `HomeNotifier.build()` (around line 40), prepend:**

```dart
ref.keepAlive();  // survives screen teardown; cleared only on logout
```

Same edit for these three files:

- `lib/features/journal/providers/journal_provider.dart` — in `JournalNotifier.build()` (around line 60), prepend `ref.keepAlive();`
- `lib/features/college/providers/college_journal_provider.dart` — in `CollegeJournalNotifier.build()`, prepend `ref.keepAlive();`
- `lib/features/scholarship_teenager/providers/scholarship_teenager_journal_provider.dart` — in `Notifiersh` (`ScholarshipTeenagerJournalNotifier`).build()`, prepend `ref.keepAlive();`

**Verify each:**

```bash
cd "C:/Users/Krisman/dev/study-center-android-student"
grep -A2 "build()" lib/features/home/providers/home_provider.dart | head -10
grep -A2 "build()" lib/features/journal/providers/journal_provider.dart | head -10
grep -A2 "build()" lib/features/college/providers/college_journal_provider.dart | head -10
grep -A2 "build()" lib/features/scholarship_teenager/providers/scholarship_teenager_journal_provider.dart | head -10
```

Each should show `ref.keepAlive();` as the first statement after `{`.

#### B2. Make `home_screen.dart` read-only — no more `.load()` from screens

**File:** `lib/features/home/screens/home_screen.dart` — replace lines 27–64 (entire `initState` block) with:

```dart
@override
void initState() {
  super.initState();
  // No data fetching here. HomeScreen is now purely a *display* layer.
  // SessionDataPreload (registered in AuthNotifier.login) runs exactly
  // once per session; cached state lives in the four keepAlive providers.
  // Pull-to-refresh is the only path that re-fetches.
}
```

#### B3. Wire preload to fire from `AuthNotifier.login` and `restoreSession`

**File:** `lib/features/auth/providers/auth_provider.dart` — at the top of the file, add:

```dart
import '../home/providers/home_provider.dart' show homeProvider;
import '../journal/providers/journal_provider.dart' show journalProvider;
import '../scholarship_teenager/providers/scholarship_teenager_journal_provider.dart'
    show scholarshipTeenagerJournalProvider;
import '../college/providers/college_journal_provider.dart' show collegeJournalProvider;
```

In `AuthNotifier.login()` (line 46), **after** `state = AuthState(user: user);` (line 50), insert:

```dart
// One-shot preload: populate session-scoped caches exactly once per login.
// Subsequent navigations read from keepAlive providers without re-fetching.
await _preloadSession(user);
```

In `AuthNotifier._autoLogin()` (line 123), **after** `state = AuthState(user: user);` (line 126), insert the same `await _preloadSession(user);` line.

In `AuthNotifier.restoreSession()` (line 188), **after** `state = AuthState(user: user);` (line 195), insert the same `await _preloadSession(user);` line.

Then add a private helper at the bottom of the `AuthNotifier` class:

```dart
Future<void> _preloadSession(UserModel user) async {
  // Each provider's load() is idempotent — it has its own loading guard
  // and respects cached state. We fire all four concurrently.
  final futures = <Future<void>>[
    () async {
      final s = ref.read(homeProvider);
      if (!s.loading) await ref.read(homeProvider.notifier).load(user.cabangSlug);
    }(),
  ];
  if (user.isStudent) {
    futures.add(() async {
      final s = ref.read(journalProvider);
      if (s.snapshot == null && !s.loading) {
        await ref.read(journalProvider.notifier).load();
      }
    }());
  }
  if (user.isScholarshipTeenager) {
    futures.add(() async {
      final s = ref.read(scholarshipTeenagerJournalProvider);
      if (s.snapshot == null && !s.loading) {
        await ref.read(scholarshipTeenagerJournalProvider.notifier).load();
      }
    }());
  }
  if (user.isCollege) {
    futures.add(() async {
      final s = ref.read(collegeJournalProvider);
      if (s.snapshot == null && !s.loading) {
        await ref.read(collegeJournalProvider.notifier).load();
      }
    }());
  }
  await Future.wait(futures, eagerError: false);
}
```

#### B4. Reset cached providers on logout

**File:** `lib/features/auth/providers/auth_provider.dart` — `AuthNotifier.logout()` (line 168). After `state = const AuthState();` (line 175), insert:

```dart
// Clear keepAlive caches so the next login starts fresh.
ref.invalidate(homeProvider);
if (ref.exists(journalProvider)) ref.invalidate(journalProvider);
if (ref.exists(scholarshipTeenagerJournalProvider)) {
  ref.invalidate(scholarshipTeenagerJournalProvider);
}
if (ref.exists(collegeJournalProvider)) ref.invalidate(collegeJournalProvider);
```

(Note: with `ref.keepAlive()`, the providers stay alive across navigations but DO dispose when `ref.invalidate()` is called.)

#### B5. Make `journal_screen.dart` and others not auto-load

**File:** `lib/features/journal/screens/journal_screen.dart` lines 132–134 — replace:

```dart
final jState = ref.read(journalProvider);
if (jState.snapshot == null && !jState.loading) {
  ref.read(journalProvider.notifier).load();
}
```

with **just**:

```dart
// Session preload already populated this provider; nothing to do here.
```

For `lib/features/college/screens/college_journal_screen.dart` lines 25–27 — apply the same "remove the .load() call" edit. (The file is still allowed to call `.load()` from a refresh button — keep that intact, just remove the auto-load.)

For `lib/features/home/screens/home_screen.dart` — already handled in B2. The remaining `ref.read(...).load()` calls in `onRefresh` (line 101 and lines 255–256) stay — those are user-initiated refreshes.

### Phase C: Build, install, validate

#### C1. Bump version

**File:** `pubspec.yaml` line 9 — change:

```yaml
version: 3.1.1+11
```

to:

```yaml
version: 3.1.2+12
```

**Verify:**

```bash
grep "^version:" pubspec.yaml
```

Expected output: `version: 3.1.2+12`

#### C2. Static analysis

```bash
cd "C:/Users/Krisman/dev/study-center-android-student" && flutter analyze
```

Expected: 0 errors, 0 new warnings (existing warnings in the codebase are out of scope).

#### C3. Build debug APK + install

```bash
cd "C:/Users/Krisman/dev/study-center-android-student" && flutter build apk --debug 2>&1 | tail -5
```

Expected tail: `√ Built build\app\outputs\flutter-apk\app-debug.apk`

```bash
adb install -r -d "C:/Users/Krisman/dev/study-center-android-student/build/app/outputs/flutter-apk/app-debug.apk"
adb shell am force-stop com.studycenter.sc_student
adb logcat -c
adb shell am start -n com.studycenter.sc_student/com.studycenter.sc_student.MainActivity
sleep 12
```

#### C4. Functional smoke via Maestro

Run the existing regression test first to confirm we didn't break the previous fix:

```bash
cd "C:/Users/Krisman/dev/study-center-android-student" && rm -rf maestro-debug-output
maestro test e2e/test_jurnal_sc_null_check_regression.yaml --debug-output=maestro-debug-output 2>&1 | tail -15
```

Expected: every step says `COMPLETED`, no `FAILED` line.

#### C5. New maintenance false-positive test

**Create file:** `e2e/test_maintenance_false_positive.yaml`

```yaml
appId: com.studycenter.sc_student
---
# Regression: maintenance screen must NOT appear on normal login + tab switch.
# (Only fires after 3 failures in 10s OR a hard health-probe miss.)

- launchApp:
    clearState: true

# Login
- assertVisible: "Masuk"
- tapOn: "email@contoh.com / username"
- eraseText
- inputText: "testuser"
- tapOn: "Masukkan password"
- eraseText
- inputText: "12345"
- tapOn: "Login Sekarang"

- waitForAnimationToEnd:
    timeout: 3000
- extendedWaitUntil:
    visible:
      text: "Beranda\nTab 1 of 4"
    timeout: 15000

# Maintenance screen must NOT be visible
- assertNotVisible: "Aplikasi Sedang Maintenance"
- assertNotVisible: "Coba Lagi"

- takeScreenshot: "maint_01_after_login_ok"

# Navigate between tabs — none should trigger maintenance
- tapOn:
    point: "270,1433"
- waitForAnimationToEnd
- assertNotVisible: "Aplikasi Sedang Maintenance"

- tapOn:
    point: "450,1433"
- waitForAnimationToEnd
- assertNotVisible: "Aplikasi Sedang Maintenance"

- tapOn:
    point: "560,1433"
- waitForAnimationToEnd
- assertNotVisible: "Aplikasi Sedang Maintenance"

- tapOn:
    point: "90,1433"
- waitForAnimationToEnd
- assertNotVisible: "Aplikasi Sedang Maintenance"

- takeScreenshot: "maint_02_after_all_tabs_ok"
```

Run it:

```bash
cd "C:/Users/Krisman/dev/study-center-android-student" && rm -rf maestro-debug-output
maestro test e2e/test_maintenance_false_positive.yaml --debug-output=maestro-debug-output 2>&1 | tail -25
```

Expected: every step says `COMPLETED`.

### Phase D: Release build

#### D1. Build release APK

```bash
cd "C:/Users/Krisman/dev/study-center-android-student" && flutter build apk --release 2>&1 | tail -10
```

Expected: `√ Built build\app\outputs\flutter-apk\app-release.apk`

#### D2. Verify the release APK metadata

```bash
"C:/Users/Krisman/Android/Sdk/build-tools/34.0.0/aapt2.exe" dump badging "C:/Users/Krisman/dev/study-center-android-student/build/app/outputs/flutter-apk/app-release.apk" 2>&1 | grep -E "package:|versionName|versionCode" | head -5
```

Expected output should include `versionName='3.1.2'` and `versionCode='12'`.

#### D3. Install release APK to confirm it runs (without replacing the user-installed debug build)

```bash
adb install -r -d "C:/Users/Krisman/dev/study-center-android-student/build/app/outputs/flutter-apk/app-release.apk"
adb shell am force-stop com.studycenter.sc_student
adb shell am start -n com.studycenter.sc_student/com.studycenter.sc_student.MainActivity
sleep 10
adb shell screencap -p /sdcard/release.png
adb pull /sdcard/release.png "C:/Users/Krisman/screenshots/release_home.png"
```

Expected: `release_home.png` shows the same Beranda UI with no error.

#### D4. Final Maestro sweep on release APK

Re-run both regression tests against the now-installed release APK:

```bash
cd "C:/Users/Krisman/dev/study-center-android-student" && rm -rf maestro-debug-output
maestro test e2e/test_jurnal_sc_null_check_regression.yaml --debug-output=maestro-debug-output 2>&1 | tail -5
```

Expected: all `COMPLETED`.

```bash
cd "C:/Users/Krisman/dev/study-center-android-student" && rm -rf maestro-debug-output
maestro test e2e/test_maintenance_false_positive.yaml --debug-output=maestro-debug-output 2>&1 | tail -5
```

Expected: all `COMPLETED`.

---

## Tests / Validation Summary

Each fix is independently verifiable:

| Phase | Verification command | Pass criterion |
|-------|----------------------|----------------|
| A1    | `flutter analyze lib/core/providers/maintenance_provider.dart` | 0 errors |
| A2    | `flutter analyze lib/core/services/api_service.dart` | 0 errors |
| A3    | `flutter analyze lib/shared/widgets/maintenance_screen.dart` | 0 errors |
| A4    | `flutter analyze lib/app.dart` | 0 errors |
| A5    | `grep -rn "setMaintenance" lib/` | only call site is `maintenance_provider.dart` (internal) |
| B1    | `grep -A3 "build()" lib/features/{home,journal,college,scholarship_teenager}/providers/*provider.dart` | Each shows `ref.keepAlive();` as first statement |
| B2    | `grep "Future.microtask" lib/features/home/screens/home_screen.dart` | Returns 0 matches |
| B3    | `grep "_preloadSession" lib/features/auth/providers/auth_provider.dart` | Returns ≥4 matches (1 def + ≥3 calls) |
| B4    | `grep -A6 "logout()" lib/features/auth/providers/auth_provider.dart` | Includes `ref.invalidate(homeProvider)` |
| C1    | `grep "^version:" pubspec.yaml` | `version: 3.1.2+12` |
| C2    | `flutter analyze` | 0 errors |
| C3    | `adb shell pm list packages | grep sc_student` | package present |
| C4    | `maestro test e2e/test_jurnal_sc_null_check_regression.yaml` | all `COMPLETED` |
| C5    | `maestro test e2e/test_maintenance_false_positive.yaml` | all `COMPLETED` |
| D1    | `ls build/app/outputs/flutter-apk/app-release.apk` | file exists |
| D2    | aapt2 dump badging | `versionName='3.1.2' versionCode='12'` |
| D3    | `adb shell screencap -p /sdcard/release.png && adb pull ...` | file pulled |
| D4    | both Maestro tests | all `COMPLETED` |

---

## Risks, Tradeoffs, Open Questions

### Risks

- **`ref.keepAlive()` memory growth.** The four providers now stay alive until logout. Each holds a `JournalSnapshot` (≈ a dozen fields) plus an internal `ProviderSubscription` for connectivity/sync signals. Worst case ≈ a few KB of cached state — negligible on a 720x1600 Android device. If `AuthNotifier.logout()` is exercised, the `ref.invalidate()` calls in B4 dispose them properly.
- **Maintenance debounce window.** A user with a genuinely slow connection may see 3 failures fire within 10s and trigger the screen prematurely. Mitigation: threshold is 3 distinct requests (not bytes), and any single success immediately clears. This is the same shape Twitter/Instagram use for their offline banners.
- **`ref.keepAlive()` API name** — verify it's available in the project's `flutter_riverpod` version before editing. (If the project is on Riverpod 2.4+, `ref.keepAlive()` is standard. If on an older version, the alternative is wrapping the provider declaration with `keepAlive: true` via a code-gen annotation, which requires `riverpod_generator`. The plan assumes standard `ref.keepAlive()`.)
- **Touching four files for B1** — each edit is mechanical (one line prepend). If any file is missing the `build()` override method, that means the file uses an older `StateNotifier` pattern; in that case, switch to wrapping the `Notifier`'s `build()` to call `ref.keepAlive()` directly. Confirm the file uses `class XxxNotifier extends Notifier<...>` before editing.
- **Test user `testuser` still valid?** Verified earlier with `curl /api/auth/login`, so safe. If the test ever fails on a "wrong password" error, re-run `curl -X POST https://studycenter.nanoprojectdevindonesia.com/api/auth/login -d '{"login":"testuser","password":"12345"}'` and adjust if the password has been rotated.

### Tradeoffs

- We do NOT auto-trigger maintenance on the first failure, even if it's a 503 — we wait 5s and verify a third failure lands. This trades instant feedback for fewer false positives, which is the desired behavior per the user's request.
- We do NOT add a `/up` health endpoint — we reuse the existing `GET /` probe that `MaintenanceScreen._testConnection` already performs. This keeps the change backend-free.
- We do NOT refactor admin/mentor screens' load patterns. Those are not the screen users land on after login, and their data dependencies are different (admin lists are not "session-scoped shared state").

### Open questions for the user

None blocking. If the implementer wants to be extra safe, run `flutter analyze` after **each** file edit in Phase A before moving on — a typo in the new `MaintenanceState` class would surface there immediately.

---

## Commit cadence (recommended, not enforced by this plan)

After Phase A: `fix(maintenance): debounce single-request errors before showing maintenance screen`
After Phase B: `refactor(session): preload session data once at login via keepAlive providers`
After Phase C: `chore(release): bump to 3.1.2+12 and verify via maestro`
After Phase D: `build(release): ship app-release.apk`

Total commits: 4.
