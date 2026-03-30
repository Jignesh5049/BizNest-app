# BizNest Mobile

<div align="center">

**A comprehensive business management platform for small and home-based businesses**

Built with Flutter | Powered by Node.js and MongoDB

</div>

---

## Overview

BizNest is a full-featured mobile platform that helps small businesses run daily operations and enables customers to discover, shop, and track orders in one ecosystem.

The project includes:
- A Flutter business app for management workflows
- A Flutter customer app for storefront and ordering
- A Node.js + Express backend with MongoDB persistence

---

## Features

### Business Management
- Dashboard analytics with revenue, order, and performance visibility
- Product and inventory management with image support
- Order lifecycle management with payment and status tracking
- Customer relationship records and history
- Expense tracking with categorized summaries

### Customer Experience
- Browse businesses and products
- Search and explore product catalogs
- Cart and checkout flow
- Order history, tracking, and reorder
- Ratings, reviews, and support ticket flows

### Security and Access
- JWT-based authentication
- Role-based access for business and customer journeys
- Secure local storage for sensitive tokens
- Supabase session compatibility in Flutter clients

---

## Tech Stack

### Mobile Clients
| Technology | Purpose |
| --- | --- |
| Flutter and Dart | Cross-platform application development |
| flutter_bloc and equatable | Predictable state management |
| go_router | Declarative routing and navigation |
| dio | HTTP client and request handling |
| supabase_flutter | Session and authentication support |
| google_fonts and flutter_svg | Brand typography and visual assets |
| flutter_secure_storage | Encrypted token storage |
| image_picker and cached_network_image | Media input and optimized image rendering |

### Backend
| Technology | Purpose |
| --- | --- |
| Node.js and Express.js | REST backend and middleware pipeline |
| MongoDB and Mongoose | Data storage and schema modeling |
| JWT | Auth token issuing and verification |
| Multer | Upload processing |
| bcryptjs | Password hashing |

---

## Design and UX Notes

- Nature-inspired brand palette focused on clarity and trust
- Rounded surfaces and soft depth for approachable UI
- Feature-based module organization in Flutter apps
- Reusable components and shared primitives to keep UI consistent

---

## Project Structure

```text
BizNest_App/
|-- biznest_app/                  # Business app (Flutter)
|   |-- lib/
|   |   |-- main.dart
|   |   |-- core/
|   |   |-- features/
|   |       |-- auth/
|   |       |-- business/
|   |       |-- customer/
|   |-- android/
|   |-- assets/
|   |-- pubspec.yaml
|   |-- README.md
|
|-- biznest_shop/                 # Customer app (Flutter)
|   |-- lib/
|   |   |-- main.dart
|   |   |-- core/
|   |   |-- features/
|   |       |-- auth/
|   |       |-- customer/
|   |-- android/
|   |-- assets/
|   |-- pubspec.yaml
|   |-- README.md
|
|-- biznest_core/                 # Shared Flutter package
|   |-- lib/
|   |-- pubspec.yaml
|
|-- server/                       # Backend (Node.js + Express)
|   |-- models/
|   |-- routes/
|   |-- middleware/
|   |-- config/
|   |-- scripts/
|   |-- uploads/
|   |-- server.js
|   |-- package.json
|
|-- README.md
```

---

## Getting Started

### Prerequisites

- Flutter SDK compatible with project constraints
- Dart SDK (bundled with Flutter)
- Node.js 16 or newer
- MongoDB local instance or MongoDB Atlas
- Android Studio or VS Code with Flutter extensions

### Backend Setup

```bash
cd server
npm install
```

Create a `.env` file in `server/` and configure your values.

Example:

```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/biznest
JWT_SECRET=your_secure_jwt_secret
SUPABASE_JWT_SECRET=your_supabase_jwt_secret_if_used
NODE_ENV=development
```

Optional seed:

```bash
npm run seed
```

Run backend:

```bash
npm start
```

### Business App Setup

```bash
cd biznest_app
flutter pub get
flutter run
```

### Customer App Setup

```bash
cd biznest_shop
flutter pub get
flutter run
```

Optional runtime variables:

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

---

## Configuration Notes

- For Android emulator backend access, use: `http://10.0.2.2:5000/api`
- For physical devices, use your machine LAN IP in the app API base URL
- Verify backend is reachable from device network before testing auth/order flows

---

## Build and Release

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

---

## Troubleshooting

### MongoDB connection issues
- Confirm MongoDB is running
- Verify `MONGODB_URI` and credentials
- Check if local ports are available

### Flutter build issues
- Run `flutter clean`
- Run `flutter pub get`
- Run `flutter doctor -v`

### Device cannot reach backend
- Validate base URL and port
- Ensure firewall rules allow inbound requests
- Confirm device and server are on same network

### Upload-related issues
- Ensure `server/uploads/` exists
- Verify read/write permissions
- Keep files within configured size limits

---

## Contributing

1. Create a feature branch
2. Keep changes scoped and documented
3. Run analyze and tests before PR
4. Open a pull request with a clear summary

Development expectations:
- Follow Flutter and Dart style guidelines
- Avoid hardcoded secrets
- Add focused comments only where logic is non-obvious
- Update docs when behavior changes

---

## License

This project is for educational and demonstration purposes.

---

<div align="center">

Built for modern small business operations

</div>
