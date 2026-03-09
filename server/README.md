# BizNest Server

This is the backend server for the BizNest App, built with Node.js and Express. It provides all RESTful APIs, authentication, business logic, and data storage for the BizNest platform.

---

## Overview

The server powers the following features for the BizNest App:

- User authentication (JWT)
- Business and customer management
- Product, order, and expense tracking
- Analytics and reporting
- Customer-facing store and order portal
- Secure data storage and media uploads

---

## Architecture & Key Modules

- **Framework:** Node.js with Express
- **Authentication:** JWT-based authentication
- **Database:** MongoDB (see `config/db.js`)
- **API Routes:**
  - `auth` — User authentication
  - `business` — Business management
  - `customers` — Customer management
  - `products` — Product management
  - `orders` — Order management
  - `expenses` — Expense tracking
  - `reviews` — Product reviews
  - `support` — Support tickets
  - `uploads` — Media uploads
  - `analytics` — Analytics and reporting
- **Middleware:** Auth, error handling, file uploads

---

## Main Features

- **Authentication:** Login, signup, JWT session management
- **Business Management:** CRUD for businesses, products, orders, expenses, customers, reviews, support, and analytics
- **Customer Portal:** APIs for business discovery, store, cart, checkout, order tracking, and profile

---

## Directory Structure (Backend)

- `models/` — Mongoose models for all entities
- `routes/` — Express route handlers for each API module
- `middleware/` — Authentication, error handling, and file upload middleware
- `config/` — Database and environment configuration
- `uploads/` — Uploaded media files
- `scripts/` — Utility scripts
- `server.js` — Main entry point

---

## Dependencies (Backend)

- `express` — Web framework
- `mongoose` — MongoDB ODM
- `jsonwebtoken` — JWT authentication
- `bcryptjs` — Password hashing
- `multer` — File uploads
- `dotenv` — Environment variables
- `cors` — Cross-origin requests
- `morgan` — Logging

---

## Running the Server

1. **Install dependencies:**
   ```bash
   npm install
   ```
2. **Set up environment variables:**
   - Copy `.env.example` to `.env` and fill in required values (MongoDB URI, JWT secret, etc.)
3. **Start the server:**
   ```bash
   npm start
   ```

---

## Notes

- The server must be running for the BizNest App frontend to function fully.
- All API endpoints are documented in the route files and can be tested with Postman or similar tools.

---

## License

This project is for educational and demonstration purposes only.
