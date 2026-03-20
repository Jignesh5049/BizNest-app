# BizNest Mobile

<div align="center">

**A comprehensive business management platform for small and home-based businesses**

Built with Flutter � Powered by Node.js & MongoDB

</div>

---

## ?? Overview

BizNest is a full-featured mobile application that empowers small businesses to manage their operations efficiently. From inventory and orders to customer relationships and analytics, BizNest provides an all-in-one solution for modern entrepreneurs.

## ? Features

### ?? Business Management
- **Dashboard Analytics** - Real-time revenue tracking, order metrics, profit analysis, and business health scores
- **Product Management** - Complete inventory control with pricing, stock levels, categories, and image uploads
- **Order Processing** - Streamlined order management with status tracking, payment monitoring, and invoice generation
- **Customer CRM** - Comprehensive customer profiles with order history and relationship tracking
- **Expense Tracking** - Detailed expense recording with category-based analytics and reporting

### ??? Customer Portal
- **Business Discovery** - Browse and explore multiple businesses and their offerings
- **Product Catalog** - Rich product listings with images, descriptions, and pricing
- **Shopping Cart & Checkout** - Seamless purchasing experience with order confirmation
- **Order Tracking** - Real-time order status updates with reorder functionality
- **Reviews & Ratings** - 5-star rating system with verified purchase reviews
- **Customer Support** - Integrated support ticket system with admin response tracking

### ?? Security & Access Control
- JWT-based authentication with secure token management
- Role-based access control (RBAC) for business owners and customers
- Secure data storage using Flutter Secure Storage
- Supabase integration for enhanced authentication options

## ??? Tech Stack

### Mobile Application
| Technology | Purpose |
|-----------|---------|
| **Flutter & Dart** | Cross-platform mobile development |
| **flutter_bloc** | State management with BLoC pattern |
| **go_router** | Declarative routing and navigation |
| **dio** | HTTP client for API communication |
| **fl_chart** | Interactive charts and data visualization |
| **supabase_flutter** | Authentication and backend services |
| **google_fonts** | Typography and custom fonts |
| **image_picker** | Camera and gallery access for uploads |
| **flutter_secure_storage** | Encrypted local data storage |

### Backend API
| Technology | Purpose |
|-----------|---------|
| **Node.js & Express.js** | RESTful API server |
| **MongoDB & Mongoose** | Database and ODM |
| **JWT** | Authentication and authorization |
| **Multer** | File upload handling |
| **bcryptjs** | Password hashing and security |

## ?? Design System

### Visual Identity
- **Color Palette** - Nature-inspired green theme with emerald and forest tones for trust and growth
- **Typography** - Google Fonts integration with medium-heavy emphasis for clarity and hierarchy
- **Layout** - Rounded corners (16-24px), soft shadows, and elevated surfaces for modern depth

### UI/UX Patterns
- Custom reusable widgets for consistency across the application
- Responsive grid and list views with smooth transitions
- Bottom navigation with intuitive iconography
- Pull-to-refresh and infinite scroll for data-heavy screens
- Loading states with shimmer effects and progress indicators

## ?? Project Structure

```
BizNest_App/
�
+-- biznest_app/                    # Flutter Mobile Application
�   +-- lib/
�   �   +-- main.dart              # Application entry point
�   �   +-- core/                  # Core functionality
�   �   �   +-- services/          # API, authentication, storage services
�   �   �   +-- utils/             # Helper functions and utilities
�   �   �   +-- widgets/           # Shared UI components
�   �   +-- features/              # Feature-based modules
�   �       +-- auth/              # Authentication & onboarding
�   �       +-- business/          # Business management features
�   �       +-- customer/          # Customer-facing features
�   +-- android/                   # Android-specific configuration
�   +-- assets/                    # Images and static resources
�   �   +-- images/                # Application images
�   +-- pubspec.yaml               # Flutter dependencies
�   +-- README.md                  # Mobile app documentation
�
+-- server/                        # Node.js Backend API
�   +-- models/                    # MongoDB data schemas
�   �   +-- User.js               # User authentication model
�   �   +-- Business.js           # Business profile model
�   �   +-- Product.js            # Product catalog model
�   �   +-- Order.js              # Order management model
�   �   +-- Customer.js           # Customer data model
�   �   +-- Expense.js            # Expense tracking model
�   �   +-- Review.js             # Product reviews model
�   �   +-- SupportTicket.js      # Support system model
�   +-- routes/                    # API route handlers
�   �   +-- auth.js               # Authentication endpoints
�   �   +-- business.js           # Business management APIs
�   �   +-- products.js           # Product CRUD operations
�   �   +-- orders.js             # Order processing APIs
�   �   +-- customers.js          # Customer management APIs
�   �   +-- expenses.js           # Expense tracking APIs
�   �   +-- analytics.js          # Analytics & reporting APIs
�   �   +-- customerPortal.js     # Customer storefront APIs
�   �   +-- support.js            # Support ticket APIs
�   �   +-- reviews.js            # Review management APIs
�   �   +-- uploads.js            # File upload handlers
�   +-- middleware/                # Express middleware
�   �   +-- auth.js               # JWT authentication middleware
�   +-- config/                    # Configuration files
�   �   +-- db.js                 # MongoDB connection setup
�   +-- scripts/                   # Utility scripts
�   +-- uploads/                   # File storage directory
�   +-- server.js                 # Express server entry point
�   +-- seed.js                   # Database seeding script
�   +-- package.json              # Node.js dependencies
�
+-- .env.example                   # Environment variables template
+-- .gitignore                     # Git ignore rules
+-- README.md                      # Project documentation (this file)
```

---

## ?? Getting Started

### Prerequisites

Before running this project, ensure you have the following installed:

- **Flutter SDK** (3.0.0 or higher) - [Installation Guide](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (included with Flutter)
- **Android Studio** or **Xcode** (for mobile development)
- **Node.js** (v16 or higher) - [Download](https://nodejs.org/)
- **MongoDB** (local installation or [MongoDB Atlas](https://www.mongodb.com/cloud/atlas))
- **Git** - [Download](https://git-scm.com/downloads)

### Installation

#### 1?? Clone the Repository

```bash
git clone https://github.com/yourusername/biznest-app.git
cd biznest-app
```

#### 2?? Backend Setup

Navigate to the server directory and install dependencies:

```bash
cd server
npm install
```

Create a `.env` file in the `server/` directory (you can copy `server/.env.example`):

```env
PORT=5000
MONGODB_URI=mongodb://localhost:27017/biznest
JWT_SECRET=your_secure_jwt_secret_key_here
SUPABASE_JWT_SECRET=your_supabase_jwt_secret_if_used
NODE_ENV=development
```

**(Optional)** Seed the database with sample data:

```bash
npm run seed
```

Start the backend server:

```bash
npm start
```

The API server will run on `http://localhost:5000`

#### 3?? Mobile App Setup

Navigate to the Flutter app directory:

```bash
cd ../biznest_app
```

Install Flutter dependencies:

```bash
flutter pub get
```

Configure required Flutter runtime env values using `--dart-define`:

```bash
flutter run \
   --dart-define=SUPABASE_URL=https://your-project.supabase.co \
   --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key
```

**Run the Application:**

```bash
# For Android emulator/device
flutter run

# For specific device
flutter devices
flutter run -d <device-id>
```

### ?? Configuration

#### Environment Variables

**Backend (server/.env):**

| Variable | Description | Example |
|----------|-------------|---------|
| `PORT` | Server port number | `5000` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://localhost:27017/biznest` |
| `JWT_SECRET` | Secret key for JWT signing | `your_secure_secret` |
| `SUPABASE_JWT_SECRET` | Supabase JWT secret for token verification (optional) | `your_supabase_jwt_secret` |
| `NODE_ENV` | Environment mode | `development` or `production` |

#### API Configuration

For **Android physical devices**, update the base URL in the Flutter app:
- Emulator: `http://10.0.2.2:5000/api`
- Physical Device: `http://<YOUR_IP>:5000/api`

The API service automatically detects the platform and adjusts the URL accordingly.

---

## ?? Running the Application

### Development Mode

1. **Start MongoDB** (if running locally):
   ```bash
   # Windows
   net start MongoDB
   
   # macOS/Linux
   sudo systemctl start mongod
   ```

2. **Start the Backend API**:
   ```bash
   cd server
   npm start
   ```

3. **Launch the Mobile App**:
   ```bash
   cd biznest_app
   flutter run
   ```

4. **Access the Application**:
   - Create an account or login
   - Explore business management or customer portal features

### Building for Production

#### Android APK

```bash
cd biznest_app
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

#### Android App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## ?? API Documentation

### Base URL
```
http://localhost:5000/api
```

### Authentication

Include JWT token in request headers:
```
Authorization: Bearer <your_jwt_token>
```

### Core Endpoints

#### Authentication
```http
POST   /api/auth/signup           # Register new user
POST   /api/auth/login            # User login
GET    /api/auth/me               # Get current user profile
```

#### Business Management
```http
GET    /api/business              # Get business profile
POST   /api/business              # Create business
PUT    /api/business              # Update business
```

#### Products
```http
GET    /api/products              # List all products
POST   /api/products              # Create product
GET    /api/products/:id          # Get product details
PUT    /api/products/:id          # Update product
DELETE /api/products/:id          # Delete product
POST   /api/uploads/product-image # Upload product image
```

#### Orders
```http
GET    /api/orders                # List orders
POST   /api/orders                # Create order
GET    /api/orders/:id            # Get order details
PUT    /api/orders/:id/status     # Update order status
PUT    /api/orders/:id/payment    # Update payment status
```

#### Customers
```http
GET    /api/customers             # List customers
POST   /api/customers             # Create customer
GET    /api/customers/:id         # Get customer details
PUT    /api/customers/:id         # Update customer
DELETE /api/customers/:id         # Delete customer
```

#### Expenses
```http
GET    /api/expenses              # List expenses
POST   /api/expenses              # Create expense
GET    /api/expenses/summary      # Get expense summary
```

#### Analytics
```http
GET    /api/analytics/dashboard      # Dashboard metrics
GET    /api/analytics/revenue-chart  # Revenue data
GET    /api/analytics/health-score   # Business health score
```

#### Customer Portal
```http
GET    /api/store/businesses           # Browse businesses
GET    /api/store/businesses/:id       # Business details
GET    /api/store/all-products         # All products
GET    /api/store/products/:id         # Product details
GET    /api/store/products/:id/reviews # Product reviews
POST   /api/store/products/:id/reviews # Submit review
POST   /api/store/orders               # Create order
GET    /api/store/orders               # Customer orders
GET    /api/store/orders/:id           # Order details
PUT    /api/store/orders/:id/cancel    # Cancel order
POST   /api/store/orders/:id/reorder   # Reorder
```

#### Support System
```http
POST   /api/store/support         # Submit support ticket
GET    /api/store/support         # Get customer tickets
GET    /api/support               # List all tickets (admin)
PUT    /api/support/:id/reply     # Reply to ticket (admin)
```

### File Uploads

Product images are stored in `server/uploads/` and served from:
```
http://localhost:5000/uploads/<filename>
```

**Supported Formats:** JPEG, PNG, WebP  
**Maximum Size:** 5MB

---

## ??? Troubleshooting

### Common Issues

**MongoDB Connection Error**
- Ensure MongoDB is running: `mongod --version`
- Verify `MONGODB_URI` in `.env` file
- Check if port 27017 is available

**CORS Errors**
- Verify backend URL in Flutter app matches server address
- Check CORS configuration in `server/server.js`

**Port Already in Use**
- Change `PORT` value in `server/.env`
- Kill process using the port:
  ```bash
  # Windows
  netstat -ano | findstr :5000
  taskkill /PID <PID> /F
  
  # macOS/Linux
  lsof -ti:5000 | xargs kill -9
  ```

**Flutter Build Errors**
- Clean build cache: `flutter clean && flutter pub get`
- Update Flutter: `flutter upgrade`
- Check Flutter doctor: `flutter doctor -v`

**Image Upload Issues**
- Verify `server/uploads/` directory exists
- Check folder permissions (read/write access)
- Ensure file size is under 5MB

---

## ?? Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow Flutter and Dart style guidelines
- Write meaningful commit messages
- Add comments for complex logic
- Test features thoroughly before submitting PR
- Update documentation for new features

---

## ?? License

This project is licensed for educational and demonstration purposes.

---

## ?? Authors

**Your Name** - Initial work

---

## ?? Acknowledgments

- Flutter team for the amazing framework
- MongoDB and Express.js communities
- All contributors and testers

---

<div align="center">

**Made with ?? for small businesses**

</div>
