# BizNest Business App

Business operations module for BizNest, built with Flutter. This README is intentionally scoped to the business-side app experience only.

## At A Glance

| Area | Details |
| --- | --- |
| Scope | Business dashboard and management workflows |
| Platform | Flutter (Android, iOS, Web, Windows) |
| State | flutter_bloc + equatable |
| Routing | go_router |
| API | Dio-powered ApiService |
| Auth/session | JWT + Supabase session support |
| Charts/UI | fl_chart, flutter_svg, google_fonts |

## Business Modules

Primary modules under lib/features/business:

- Dashboard
- Products
- Orders
- Customers
- Expenses
- Analytics
- Invoices
- Support inbox
- Pricing
- Learn
- Profile and settings

## Engineering Architecture

### 1) Presentation Layer

- Business screens are feature-oriented and organized by module.
- Shared visual building blocks and theme primitives are centralized in lib/core.
- Responsive behavior is implemented for narrow and wide layouts.

### 2) State and Flow Control

- BLoC is used where state transitions need explicit event/state modeling.
- Screen-level state is kept local when lifecycle scope is limited.
- Async UI updates follow mounted-safe patterns.

### 3) Navigation Model

- go_router manages route declarations and shell composition.
- Business shell controls drawer/top-nav/bottom-nav behavior.
- Module routes are designed to remain stable for deep links and internal navigation.

### 4) Data and API Contracts

- All network operations are funneled through ApiService.
- Feature screens map backend payloads into UI-facing structures.
- Contract mismatches should be fixed at boundary points, not scattered across widgets.

## Business-Side Directory Guide

- lib/features/business: all business modules
- lib/features/business/widgets: shell and feature-level reusable widgets
- lib/core/navigation: route setup and shell bindings
- lib/core/services: ApiService, token/session utilities
- lib/core/utils: formatters and shared helper logic

## Local Development

### Prerequisites

- Flutter SDK compatible with pubspec constraints
- Dart SDK (bundled with Flutter)
- VS Code or Android Studio with Flutter tooling
- Running backend API in ../server

### Run

```bash
flutter pub get
flutter run
```

### Recommended Checks

```bash
flutter analyze lib/features/business
flutter test
```

## Senior Dev Workflow Notes

- Keep changes module-scoped (for example, orders changes stay inside orders feature unless truly shared).
- Preserve API field names expected by backend models.
- Avoid duplicating request logic across screens; reuse service functions.
- Prefer small composable widgets over long build methods.
- Validate both UX states: loading/empty/error/success.

## Troubleshooting

### Data not loading in business screens

- Ensure ../server is running.
- Verify API base URL and auth token validity.
- Check request payload keys against backend model expectations.

### Analyzer warnings in touched files

- Run scoped analysis first:

```bash
flutter analyze lib/features/business
```

- Fix new warnings introduced by your change before opening a PR.

## Quality Bar Before PR

1. Business flow works end-to-end with backend.
2. flutter analyze for touched business files is clean.
3. Edge states verified (empty state, API failure state).
4. Mobile layout sanity checked.
5. No hardcoded secrets or environment keys.

## License

This project is for educational and demonstration purposes only.
