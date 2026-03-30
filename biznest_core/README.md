# BizNest Core

Shared Flutter package used by BizNest apps for common auth, API, theme,
utility, and reusable widget logic.

## At A Glance

| Area | Details |
| --- | --- |
| Package | `biznest_core` |
| Purpose | Shared foundation for `biznest_app` and `biznest_shop` |
| SDK | Dart `^3.10.7`, Flutter `>=1.17.0` |
| Main entry | `lib/biznest_core.dart` |
| Primary domains | auth, services, theme, utils, widgets |

## What This Package Contains

Core modules available under `lib/src`:

- `auth/bloc/auth_bloc.dart`
- `services/api_service.dart`
- `services/token_service.dart`
- `theme/app_colors.dart`
- `theme/app_theme.dart`
- `utils/helpers.dart`
- `widgets/app_gradient_button.dart`
- `widgets/app_skeleton_loader.dart`

Package barrel exports in `lib/biznest_core.dart`:

- Theme: `AppColors`, `AppTheme`
- Widgets: `AppGradientButton`, `AppSkeletonLoader`
- Utils: shared helper functions
- Services: API and token management
- Auth: `AuthBloc` and auth state/event models

## Package Responsibilities

### 1) Shared Theming

- Defines consistent color tokens and typography settings.
- Exposes app-level light theme for consuming apps.

### 2) Authentication Foundation

- Central auth flow with BLoC event/state management.
- Supports JWT-based auth and Supabase session compatibility.

### 3) API and Session Services

- Unified Dio API layer for server communication.
- Token service for secure JWT and refresh token handling.

### 4) Reusable UI and Helpers

- Reusable gradient button for consistent CTA styling.
- Shared skeleton loader component for loading states.
- Helper utilities for common formatting and data handling.

## How To Use In Apps

Reference the local package in app `pubspec.yaml`:

```yaml
dependencies:
  biznest_core:
    path: ../biznest_core
```

Import from the barrel file:

```dart
import 'package:biznest_core/biznest_core.dart';
```

Example usage:

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  home: Scaffold(
    body: Center(
      child: AppGradientButton(
        text: 'Continue',
        onPressed: () {},
      ),
    ),
  ),
);
```

## Development Notes

- Keep this package app-agnostic and reusable.
- Avoid feature-specific business/customer UI in `biznest_core`.
- Prefer extending existing services/widgets over duplicating logic in apps.
- Maintain backward compatibility for exported APIs when possible.

## Local Validation

Run inside `biznest_core`:

```bash
flutter pub get
flutter analyze
flutter test
```

## Folder Guide

- `lib/biznest_core.dart`: package export surface
- `lib/src/auth`: shared auth BLoC and auth models
- `lib/src/services`: API and secure token services
- `lib/src/theme`: colors and app theme definitions
- `lib/src/utils`: shared helper functions
- `lib/src/widgets`: reusable UI components

## License

This package is part of the BizNest project and is intended for educational
and demonstration purposes.
