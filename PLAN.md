# Cab Services Booking App — Plan

## Overview

A cab booking app with two roles — **Customer** and **Admin**. Customers browse routes, check prices, and create bookings. The admin manages cabs and routes, and manually assigns a cab to each booking. No payment integration. Built with a **Node.js / Express / MongoDB** backend and a native **iOS SwiftUI** app.

---

## Architecture

```
iOS App (SwiftUI)
      │
      │  HTTP / REST (JWT auth)
      ▼
Node.js + Express API
      │
      ▼
MongoDB (Mongoose)
```

---

## Project Structure

```
cab/
├── backend/
│   ├── src/
│   │   ├── config/          # DB connection, env config
│   │   ├── middleware/      # JWT auth, role-guard
│   │   ├── models/          # Mongoose schemas
│   │   ├── routes/          # Express route files
│   │   ├── controllers/     # Business logic
│   │   └── app.js           # Entry point
│   ├── package.json
│   └── .env.example
├── CabBooking/              # Xcode project (SwiftUI)
│   ├── App/                 # App entry, root navigation, auth state
│   ├── Models/              # Codable structs matching API responses
│   ├── Services/            # APIClient, KeychainManager
│   ├── Views/
│   │   ├── Auth/            # Login, Signup
│   │   ├── Customer/        # Routes, Booking, History
│   │   └── Admin/           # Bookings, Cabs, Routes management
│   ├── ViewModels/          # ObservableObject VMs per screen
│   └── Utils/               # Extensions, constants
└── PLAN.md
```

---

## Backend

### Data Models

#### User
| Field | Type | Notes |
|-------|------|-------|
| `name` | String | |
| `email` | String | unique |
| `phone` | String | |
| `passwordHash` | String | bcrypt |
| `role` | String | enum: `customer`, `admin` |
| `createdAt` | Date | |

Admin is **pre-seeded** on server startup from env vars. Customers sign up via the app. Admin cannot sign up via the app.

#### Cab
| Field | Type | Notes |
|-------|------|-------|
| `driverName` | String | |
| `driverPhone` | String | |
| `vehicleModel` | String | e.g. "Maruti Ertiga" |
| `licensePlate` | String | |
| `color` | String | |
| `seaterCapacity` | Number | 4, 6, or 7 |
| `isCNG` | Boolean | |
| `isActive` | Boolean | default true |
| `createdAt` | Date | |

Managed entirely by admin.

#### Route
| Field | Type | Notes |
|-------|------|-------|
| `from` | String | e.g. "Delhi" |
| `to` | String | e.g. "IGI Airport" |
| `routeType` | String | enum: `city_to_airport`, `airport_to_city` |
| `prices` | Array | price matrix (see below) |

Price matrix example:
```json
[
  { "seaterCapacity": 4, "isCNG": false, "price": 850 },
  { "seaterCapacity": 4, "isCNG": true,  "price": 650 },
  { "seaterCapacity": 6, "isCNG": false, "price": 1200 },
  { "seaterCapacity": 6, "isCNG": true,  "price": 950 },
  { "seaterCapacity": 7, "isCNG": false, "price": 1400 }
]
```

#### Booking
| Field | Type | Notes |
|-------|------|-------|
| `customerId` | ObjectId | ref User |
| `routeId` | ObjectId | ref Route |
| `travelDate` | Date | |
| `numberOfPeople` | Number | |
| `preferredSeater` | Number | 4, 6, or 7 |
| `prefersCNG` | Boolean | |
| `status` | String | enum: `pending`, `confirmed`, `completed`, `cancelled` |
| `assignedCabId` | ObjectId | ref Cab, null until admin assigns |
| `totalAmount` | Number | derived from route price matrix |
| `customerNotes` | String | optional |
| `createdAt` | Date | |

---

### API Endpoints

#### Auth

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/auth/signup` | Public | Customer signup (name, email, phone, password) |
| POST | `/api/auth/login` | Public | Login for both roles — returns JWT + role |
| POST | `/api/auth/logout` | Authenticated | Invalidate session |
| DELETE | `/api/auth/account` | Customer | Delete own account |
| GET | `/api/auth/me` | Authenticated | Get current user profile |

#### Routes

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| GET | `/api/routes` | Public | List all routes with full price matrix |
| GET | `/api/routes/:id` | Public | Single route detail |
| POST | `/api/routes` | Admin | Create a route |
| PUT | `/api/routes/:id` | Admin | Update route or prices |
| DELETE | `/api/routes/:id` | Admin | Remove a route |

#### Bookings

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/bookings` | Customer | Create a booking |
| GET | `/api/bookings/my` | Customer | Own booking history |
| GET | `/api/bookings/my/:id` | Customer | Single booking detail (cab info shown if confirmed) |
| GET | `/api/bookings` | Admin | All bookings (filterable by `?status=`) |
| GET | `/api/bookings/:id` | Admin | Single booking with customer details |
| PATCH | `/api/bookings/:id/assign` | Admin | Assign a cab → status becomes `confirmed` |
| PATCH | `/api/bookings/:id/status` | Admin | Update status to `completed` or `cancelled` |

#### Cabs

| Method | Endpoint | Access | Description |
|--------|----------|--------|-------------|
| POST | `/api/cabs` | Admin | Add a new cab |
| GET | `/api/cabs` | Admin | List all cabs |
| PUT | `/api/cabs/:id` | Admin | Edit cab details |
| DELETE | `/api/cabs/:id` | Admin | Remove a cab |

---

### Key Logic

- **JWT Auth**: Token issued on login, attached as `Authorization: Bearer <token>` on every protected request. Role-guard middleware restricts admin-only endpoints.
- **Admin Seed**: On server start, if no admin user exists in DB, one is created from `ADMIN_EMAIL` and `ADMIN_PASSWORD` in `.env`.
- **Price Derivation**: When a customer creates a booking, the backend looks up the price from the route's `prices` array matching the selected `seaterCapacity` and `prefersCNG` values and stores it as `totalAmount` on the booking.
- **Cab Assignment**: Admin calls `/assign` with a `cabId`. Booking status flips to `confirmed`. Customer's booking detail now includes full cab and driver info.
- **Info Visibility**: Cab/driver details are only visible to the customer after status = `confirmed`.

---

## iOS App (SwiftUI)

### Navigation Flow

```
App Launch
│
├─ No token in Keychain ──► Login / Signup screens
│
└─ Token exists ──► Decode role from JWT
                         │
                         ├─ customer ──► Customer TabView
                         │                ├─ Tab 1: Browse Routes
                         │                ├─ Tab 2: My Bookings
                         │                └─ Tab 3: Profile
                         │
                         └─ admin ──► Admin TabView
                                       ├─ Tab 1: All Bookings
                                       ├─ Tab 2: Manage Cabs
                                       ├─ Tab 3: Manage Routes
                                       └─ Tab 4: Profile
```

### Screens

#### Auth
- **LoginView** — email + password field, login button, link to SignupView
- **SignupView** — name, email, phone, password (customer only; no role picker)

#### Customer
- **RouteListView** — cards showing all routes (e.g. "Delhi → IGI Airport"). Tap to book.
- **BookingFormView** — seater picker (4 / 6 / 7), CNG toggle, date picker, number of people field. Price auto-updates based on selection. Confirm to submit booking.
- **MyBookingsView** — list of all customer bookings with colour-coded status badges (pending / confirmed / completed / cancelled).
- **BookingDetailView** — full booking info. If status is `confirmed`, shows a card with: driver name, driver phone, vehicle model, licence plate, colour.

#### Admin
- **AllBookingsView** — full list of all bookings across all customers, filterable by status. Tap a booking to open detail.
- **AdminBookingDetailView** — shows customer name, phone, route, date, preferences. If status is `pending`, shows an "Assign Cab" button.
- **AssignCabSheet** — bottom sheet listing all active cabs. Admin taps one to confirm assignment.
- **CabListView** — list of all cabs with edit/delete actions. "+" button to add.
- **AddEditCabView** — form: driver name, phone, vehicle model, licence plate, colour, seater capacity picker, CNG toggle.
- **AdminRouteListView** — list of all routes with edit/delete. "+" to add.
- **AddEditRouteView** — form: from, to, route type, price matrix editor (per seater + CNG combination).

#### Profile (shared)
- **ProfileView** — displays name, email, phone. Logout button. Delete Account button (only shown for customers).

### Services

- **APIClient** — async/await `URLSession` wrapper. Base URL read from a config constant. Centrally injects the `Authorization` header from Keychain.
- **KeychainManager** — save, retrieve, and delete the JWT token from iOS Keychain.
- **AuthManager** — `ObservableObject` that holds login state and current user role; drives root navigation.

---

## End-to-End Booking Flow

```
Customer                    Backend                     Admin
   │                           │                           │
   │── GET /routes ───────────►│                           │
   │◄─ routes + prices ────────│                           │
   │                           │                           │
   │── POST /bookings ─────────►│  (status: pending)       │
   │◄─ booking created ─────────│                           │
   │                           │                           │
   │                           │◄── GET /bookings?status=pending ──│
   │                           │─── pending bookings list ────────►│
   │                           │                           │
   │                           │◄── GET /cabs ─────────────────────│
   │                           │─── cabs list ─────────────────────►│
   │                           │                           │
   │                           │◄── PATCH /bookings/:id/assign ────│
   │                           │    (status: confirmed)    │
   │                           │─── booking confirmed ─────────────►│
   │                           │                           │
   │── GET /bookings/my/:id ──►│                           │
   │◄─ booking + cab details ──│                           │
```

---

## Implementation Order

### Phase 1 — Backend
1. Project init, dependencies, folder structure, `.env`, MongoDB connection
2. Mongoose models: User, Cab, Route, Booking
3. Auth system: signup, login, JWT middleware, role-guard, logout, delete account, admin seed
4. Routes API: public list/detail, admin CRUD
5. Cabs API: admin CRUD
6. Bookings API: customer create/history, admin list/assign/status update

### Phase 2 — iOS App
7. Xcode project setup, folder structure, APIClient, KeychainManager, AuthManager
8. Auth screens: LoginView, SignupView, ProfileView, role-based root navigation
9. Customer screens: RouteListView, BookingFormView, MyBookingsView, BookingDetailView
10. Admin screens: AllBookingsView, AdminBookingDetailView, AssignCabSheet, CabListView, AddEditCabView, AdminRouteListView, AddEditRouteView

---

## Environment Variables (`.env`)

```
PORT=3000
MONGODB_URI=mongodb://localhost:27017/cab
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRES_IN=7d
ADMIN_EMAIL=admin@cab.com
ADMIN_PASSWORD=Admin@123
```
