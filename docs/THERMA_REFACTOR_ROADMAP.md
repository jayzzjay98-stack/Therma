# Therma Refactor Roadmap

## Goal

Stabilize Therma's core behavior before doing more visual iteration. The priorities are:

1. Restore a trustworthy test suite.
2. Reduce unnecessary refresh work and background activity.
3. Lower the maintenance cost of the Settings code.
4. Harden the updater so releases are safer.

## Current Problems

### 1. Test coverage is not trustworthy

- `swift build` passes.
- `swift test` fails because old tests still reference removed power telemetry code.
- Result: the project can ship while the automated safety net is already broken.

### 2. Refresh work is duplicated

- Status bar refreshes every `0.5s`.
- System metrics, RAM, CPU, and alerts each run their own timers.
- Process scanning also happens on a repeating loop.
- Result: more wakeups, more redraws, and more battery cost than necessary for a menu bar utility.

### 3. Settings code is too large

- `SettingsView.swift` is large and mixes multiple screens.
- `SettingsViewComponents.swift` is even larger and carries too many responsibilities.
- Result: UI changes are slower, riskier, and easier to regress.

### 4. Update install flow is brittle

- The app downloads a zip, unpacks it, ad-hoc signs it, replaces the installed bundle with a shell script, then relaunches.
- Result: this works, but it is the highest-risk operational path in the app.

## Refactor Plan

### Phase 1: Restore Safety

**Goal:** make the codebase safe to change again.

**Scope**

- Remove or rewrite stale tests that still reference deleted power telemetry features.
- Keep tests only for behavior that exists in the current app.
- Add focused tests for:
  - throughput formatting
  - menu bar visibility rules
  - battery cycle formatting
  - version comparison logic in updater

**Definition of done**

- `swift test` passes.
- The tests cover current product behavior, not removed features.

## Phase 2: Reduce Background Cost

**Goal:** cut duplicated timer work and unnecessary refreshes.

**Scope**

- Introduce one refresh coordination strategy instead of several independent polling loops.
- Let status bar UI update when source values change, not on its own `0.5s` loop.
- Slow or gate process scanning when the related UI is not visible.
- Keep fast refresh only for data that truly benefits from it.

**Expected result**

- Lower CPU wakeups.
- Lower idle battery impact.
- Cleaner data flow between monitors and UI.

## Phase 3: Decompose Settings

**Goal:** make the UI code easier to maintain.

**Scope**

- Split Settings into per-screen files:
  - Dashboard
  - Menu Bar
  - General
  - Alerts
  - About
- Move reusable cards, controls, and section shells into focused component files.
- Keep visual behavior unchanged during the split unless a bug fix is required.

**Expected result**

- Smaller files.
- Safer UI edits.
- Faster iteration on individual screens.

## Phase 4: Harden Updates

**Goal:** reduce release and install risk.

**Scope**

- Clean up the download, unzip, validation, replacement, and relaunch steps.
- Add stronger validation around the downloaded bundle before replacement.
- Reduce dependence on fragile shell-script replacement logic where possible.
- Add tests around version comparison and release asset selection.

**Expected result**

- Fewer update failures.
- Safer release workflow.
- Easier debugging when installs fail.

## Suggested Order

1. Phase 1: Restore Safety
2. Phase 2: Reduce Background Cost
3. Phase 3: Decompose Settings
4. Phase 4: Harden Updates

## Why This Order

- Phase 1 makes all later work safer.
- Phase 2 improves real runtime behavior for users immediately.
- Phase 3 lowers development cost after the core behavior is stable.
- Phase 4 is important, but safer to touch once tests and structure are in better shape.

## Recommended First Execution Batch

If we start implementation next, the best first batch is:

1. Fix the failing test target.
2. Remove the `0.5s` status bar polling loop.
3. Centralize refresh cadence for CPU, RAM, network, and alerts.

That batch gives the best return first: safer changes and better runtime efficiency.
