# BizNest App

BizNest is a full-featured business management solution built with Flutter, designed for modern businesses to manage their operations efficiently. This document provides all technical and architectural details for software engineers, so you can understand the project without browsing the codebase.

---

## Overview

BizNest consists of a Flutter frontend and a Node.js/Express backend (see `../server`). The app enables:

- User authentication (JWT & Supabase)
- Business and customer management
- Product, order, and expense tracking
- Analytics and reporting
- Customer-facing store and order portal
- Secure data storage and media uploads

---

## Architecture & Key Modules

### Frontend (Flutter)

- **State Management:** Uses `flutter_bloc` and `equatable` for predictable state and event handling.
- **Navigation:** Managed by `go_router` for declarative, deep-linkable routing.
- **API Integration:** All backend communication is abstracted in a central `ApiService` using `dio`.
- **Authentication:** Supports both JWT and Supabase session tokens for secure access.
- **UI/UX:** Custom widgets, charts (`fl_chart`), SVGs, Google Fonts, and image caching for a modern experience.
- **Persistence:** Uses `shared_preferences` and `flutter_secure_storage` for local and secure storage.
- **Media:** Image uploads via `image_picker`.
- **Internationalization:** Enabled with `intl`.

### Backend (Node.js/Express)

- RESTful API for all business logic (see `../server`)
- Handles authentication, business data, analytics, orders, products, reviews, support, and more
- Designed to be started separately; see its README for setup

---

## Main Features

- **Authentication:** Login, signup, onboarding, secure session management
- **Business Management:** Dashboard, analytics, product, order, expense, customer, review, support, settings, pricing, invoice, and learning modules
- **Customer Portal:** Home, business discovery, store, cart, checkout, order tracking, profile, favorites, and product details

---

## Directory Structure (Frontend)

- `lib/features/auth` — Authentication flows
- `lib/features/business` — Business management screens
- `lib/features/customer` — Customer-facing screens
- `lib/core/services` — API, token, and platform services
- `lib/core/utils` — Helper functions
- `lib/core/widgets` — Shared widgets
- `assets/` — Images and static files

---

## Dependencies (Frontend)

- `flutter_bloc`, `equatable` — State management
- `go_router` — Navigation
- `supabase_flutter`, `dio` — Backend/database
- `google_fonts`, `fl_chart`, `flutter_svg`, `cached_network_image` — UI/UX
- `shared_preferences`, `flutter_secure_storage` — Storage
- `image_picker` — Media
- `intl` — Internationalization
- `url_launcher` — External links

---

## Running the Project

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```
2. **Run the Flutter app:**
   ```bash
   flutter run
   ```
3. **Start the backend server:**
   - Go to the `server` directory and follow its README for setup and running instructions.

---

## Notes

- The app is cross-platform (Android, iOS, Web, Windows).
- All API endpoints and business logic are handled by the backend server (`../server`).
- For full functionality, both the Flutter app and backend server must be running.

---

## License

This project is for educational and demonstration purposes only.
