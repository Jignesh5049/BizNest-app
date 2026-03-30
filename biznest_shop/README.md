# BizNest Customer App

Customer shopping and order-tracking module for BizNest, built with Flutter. This README is intentionally scoped to the customer-side app experience only.

## At A Glance

| Area | Details |
| --- | --- |
| Scope | Customer storefront and post-purchase workflows |
| Platform | Flutter (Android, iOS, Web, Windows) |
| State | flutter_bloc + equatable |
| Routing | go_router |
| API | Dio-powered ApiService |
| Auth/session | JWT + Supabase session support |
| UI | flutter_svg, google_fonts, cached_network_image |

## Customer Modules

Primary modules under lib/features/customer:

- Storefront home
- Business discovery
- Product browsing
- Cart and checkout
- Orders and reorder flow
- Favorites
- Profile and account settings

## Engineering Architecture

### 1) Presentation Layer

- Customer screens are organized by shopper journeys and app flow.
- Shared theme tokens and reusable widgets are centralized in lib/core.
- Layout behavior supports both compact and wide screens.

### 2) State and Flow Control

- BLoC/Cubit drives predictable state updates for auth, cart, and feature screens.
- Screen-local state remains local unless shared across routes.
- Async UI updates follow mounted-safe patterns.

### 3) Navigation Model

- go_router manages auth redirects and customer shell routes.
- Core customer tabs are synchronized between navigation state and gestures.
- Route definitions are kept stable for deep links and internal navigation.

### 4) Data and API Contracts

- Network calls are routed through shared ApiService abstractions.
- Backend payloads are normalized at boundaries before UI consumption.
- Contract mismatches should be fixed in mapping layers, not duplicated across screens.

## Customer-Side Directory Guide

- lib/features/customer: customer-facing modules
- lib/features/customer/widgets: shell and reusable customer widgets
- lib/features/auth: login and signup flows
- lib/core/navigation: route setup and shell wiring
- lib/core/utils: shared helpers and formatters

## Local Development

### Prerequisites

- Flutter SDK compatible with pubspec constraints
- Dart SDK (bundled with Flutter)
- VS Code or Android Studio with Flutter tooling
- Running backend API in ../server

### Run

1. flutter pub get
2. flutter run

### Recommended Checks

1. flutter analyze lib/features/customer
2. flutter test

## Senior Dev Workflow Notes

- Keep changes feature-scoped (for example, cart changes stay within cart/customer modules unless truly shared).
- Preserve backend field names expected by API models.
- Reuse existing service and utility functions for request mapping.
- Prefer small composable widgets over long build methods.
- Verify all UI states: loading, empty, error, success.

## Troubleshooting

### Customer data not loading

- Ensure ../server is running.
- Verify API base URL and auth token validity.
- Check payload keys and response mapping at API boundaries.

### Analyzer warnings in touched files

- Run scoped analysis first: flutter analyze lib/features/customer
- Fix new warnings introduced by your change before creating a PR.

## Quality Bar Before PR

1. Customer journey works end-to-end with backend.
2. flutter analyze for touched customer files is clean.
3. Edge states verified (empty state, API failure state).
4. Mobile layout sanity checked.
5. No hardcoded secrets or environment keys.

## License

This project is for educational and demonstration purposes only.
