# Event Equipment Rental Management App

> A Flutter + Firebase platform for centralized event-equipment booking, real-time availability, conflict prevention, warehouse dispatch, and AI-assisted rental operations.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase)](https://firebase.google.com/)
[![TypeScript](https://img.shields.io/badge/TypeScript-Backend-3178C6?logo=typescript)](https://www.typescriptlang.org/)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-7B61FF)](https://riverpod.dev/)
[![GitHub Actions](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF?logo=githubactions)](https://github.com/features/actions)

---

## 📌 Overview

This project is designed for a regional event-equipment rental company that supplies **sound systems, lighting, and furniture** for weddings and corporate events.

The existing workflow depends heavily on phone calls. During peak periods, the same equipment can be committed to overlapping events, with the conflict sometimes discovered only when the warehouse team starts loading the truck.

The application replaces that fragmented process with a centralized system where clients, office staff, warehouse teams, and administrators work from the same real-time booking and inventory state.

### Core objective

> **Make it technically impossible for two bookings to overcommit the same equipment pool for overlapping dates.**

The project starts with this mandatory core and is designed to grow into operational automation, AI-assisted workflows, client self-service, analytics, and platform-scale capabilities.

---

# 🎯 Problem Statement

The traditional workflow looks like:


Client / Customer
       ↓
   Phone Call
       ↓
Office Staff
       ↓
 Manual Availability Check
       ↓
    Booking
       ↓
 Warehouse Preparation
       ↓
Conflict discovered too late


This creates:

- Double-booking risk
- No single source of truth
- Manual availability checking
- Communication gaps between office and warehouse
- Poor visibility into upcoming dispatches
- No reliable audit history
- Difficulty handling peak-season demand

The proposed system changes this to:


Client / Staff
      ↓
Centralized Application
      ↓
Real-Time Availability
      ↓
Atomic Booking Transaction
      ↓
Confirmed Booking
      ↓
Warehouse Pull List
      ↓
Dispatch
      ↓
Return / Inspection


---

# 🚀 Goals

The primary goals are:

1. Prevent overlapping equipment bookings through transaction-safe conflict detection.
2. Provide live equipment availability.
3. Replace phone-call-only booking coordination with a centralized workflow.
4. Give warehouse staff an advance pull list.
5. Support client and staff-created booking requests through the same core booking path.
6. Enforce role-based access server-side.
7. Maintain an automatic audit trail.
8. Build a foundation that can later support pricing, payments, analytics, and AI.

---

# 👥 User Roles

The application has four roles:

| Role | Main Responsibility |
|---|---|
| **Admin** | Full system visibility, catalog, users/roles, audit logs, overrides |
| **Office / Staff** | Phone bookings, booking review, approval/rejection, scheduling |
| **Warehouse** | Pull lists, loading, dispatch, returns, damage reporting |
| **Client** | Browse equipment, view availability, request bookings, track bookings |

All four roles use the same Flutter application. Role-based routing determines the appropriate home screen and permissions.

---

# ⭐ Key Features

## 1. Equipment Catalog

Manage equipment pools such as:

- Sound systems
- Speakers
- Microphones
- Lighting
- Tables
- Chairs
- Other event furniture

Equipment is tracked as **quantity pools**, not as individually serialized units.

For example:


JBL PA Speaker
Total Quantity: 20
Damaged Quantity: 2
Effective Pool: 18


The system derives availability instead of storing a mutable `availableQuantity` counter as the source of truth.

---

## 2. Live Availability

Clients can browse equipment and see remaining quantity for a selected date range.

The same availability engine is reused by:

- Client catalog browsing
- Booking transactions
- Warehouse pull lists

This avoids maintaining separate availability logic for different parts of the application.

---

## 3. Conflict-Free Booking

This is the most important feature of the system.

A booking does **not** use a simple:


check availability → write booking


Pattern.

Instead:


Availability Check
       ↓
Firestore Transaction
       ↓
Re-check Availability
       ↓
Write Booking + Items
       ↓
Commit atomically


If two people attempt to reserve the last available equipment at the same time, only one transaction can successfully commit.

### Example


Available speakers = 10

Booking A requests 8
Booking B requests 5

          ↓

Atomic transactions

          ↓

Booking A → SUCCESS
Booking B → REJECTED / ALTERNATIVE


This transaction-based approach is the foundation of the project.

---

# 📅 Booking Lifecycle

Bookings follow a controlled state machine:


Requested
    ↓
Confirmed
    ↓
Dispatched
    ↓
Returned
    ↓
Completed


Cancellation is a side exit:


Requested ─────→ Cancelled
Confirmed ─────→ Cancelled


Status is treated as a finite state machine rather than arbitrary text, and invalid transitions are rejected at the security layer.

---

# 🧑‍💼 Client Flow


Login / Signup
      ↓
Browse Catalog
      ↓
Select Dates
      ↓
View Live Availability
      ↓
Select Equipment
      ↓
Submit Request
      ↓
Server-Side Transaction
      ↓
Requested + Soft Hold
      ↓
Staff Review
   ↙        ↘
Approved    Rejected
   ↓
Confirmed
   ↓
Dispatched
   ↓
Returned
   ↓
Completed


If requested equipment is unavailable, the system can provide:

- Alternative equipment suggestions
- Alternative date suggestions
- Waitlist entry

---

# 🏢 Office / Staff Flow

Staff can:

- View pending requests
- Approve bookings
- Reject bookings
- Modify requested quantities
- Enter phone bookings
- Schedule delivery and pickup
- Assign drivers
- Monitor booking status

### Important design decision

Phone bookings and client bookings use the **same `createBookingRequest` flow**.

There is no separate booking path that bypasses conflict detection.


Client Booking
      ↓
createBookingRequest
      ↑
Staff Phone Booking


This keeps the most important business rule centralized.

---

# 📦 Warehouse Flow

The warehouse receives an advance pull list instead of discovering conflicts during loading.


Today's Confirmed Bookings
          ↓
     Pull List
          ↓
    Load Equipment
          ↓
      Dispatched
          ↓
        Event
          ↓
      Equipment Return
          ↓
       Inspection
       ↙        ↘
      OK       Damaged
      ↓           ↓
  Returned    Damage Report
      ↓           ↓
  Completed   AI Draft + Review


Warehouse capabilities include:

- Today's pull list
- Equipment loading
- Dispatch status
- Return processing
- Damage reporting
- Damage photos
- Offline-aware workflow

---

# 🧾 Audit Trail

Important booking status changes are recorded automatically.

For example:


Requested → Confirmed


creates an audit entry containing the relevant actor and transition information.

Audit logs are generated through Firestore triggers rather than relying on individual screens to remember to create logs.

Admins can access a read-only audit log viewer.

---

# 🔐 Security

Security is enforced server-side.

The application uses:


Firebase Authentication
        +
Custom Claims
        +
Firestore Security Rules
        +
Cloud Functions
        +
Atomic Transactions

### Role enforcement

Roles:


admin
staff
warehouse
client


The role stored in the user's Firestore document is for application data/display. The trusted permission source is the Firebase Auth custom claim.

### Default security posture

Default → DENY
Explicitly permitted → ALLOW


The UI is never treated as the security boundary.

---

# 🏗️ Architecture

The repository is a single monorepo containing two deployable units:


equipment-rental-app/
│
├── app/                 # Flutter client
│
├── functions/           # Firebase Cloud Functions
│
└── shared/              # Shared data contracts


### Why a monorepo?

The Flutter client and Cloud Functions share the same concepts:

- Booking status
- Equipment schema
- User roles
- API payloads
- Business rules

Keeping shared contracts together reduces the risk of frontend/backend schema drift.

---

# 🛠️ Technology Stack

| Area | Technology |
|---|---|
| Client | Flutter / Dart |
| State Management | Riverpod |
| Backend | Firebase |
| Database | Cloud Firestore |
| Server Logic | Firebase Cloud Functions |
| Backend Language | TypeScript / Node.js |
| Authentication | Firebase Authentication + Custom Claims |
| Storage | Firebase Cloud Storage |
| Notifications | Firebase Cloud Messaging |
| AI | Claude / Anthropic API |
| Routing | go_router |
| Models | Freezed + json_serializable |
| Offline | Firestore offline cache |
| Connectivity | connectivity_plus |
| CI/CD | GitHub Actions |
| Monitoring | Firebase Crashlytics + Performance Monitoring |
| Analytics | Firebase Analytics + Firestore aggregations |
| Version Control | Git / GitHub |

---

# 🤖 AI Layer

AI is introduced after the mandatory booking and inventory foundation.

The core rule is:

> **AI can suggest. Only a trusted server-side transaction can confirm.**

AI never directly writes critical booking decisions to Firestore.

---

## AI Tier 1

### Smart Conflict Resolution

When inventory is insufficient, AI can suggest:

- Substitute equipment
- Adjusted quantities
- Alternative dates

Suggestions are constrained by real inventory.

### Demand Forecasting

Historical booking data can be used to establish a demand-forecasting baseline and later support business analytics.

---

## AI Tier 2

### Natural Language Booking Intake

Staff can provide an unstructured request:

```text
Wedding for 500 guests on Saturday.
Need speakers, lights and 300 chairs.
```

The system converts it into a structured draft:


Event Type: Wedding
Guests: 500
Date: Saturday

Equipment:
- Speakers
- Lighting
- Chairs: 300


The draft still goes through the normal booking review and transaction flow.

### AI Quote Generation

AI-assisted quote generation is planned on top of the pricing engine.

---

## AI Tier 3

### Photo-Based Damage Assessment

Warehouse staff can upload a damage photo.


Damage Photo
     ↓
AI Draft Description
     ↓
Warehouse Review
     ↓
Confirmed Damage Report


AI output is always human-reviewed before being committed.

### Smart Dispatch / Route Assistant

Uses dispatch and scheduling data to assist warehouse and delivery operations.

---

## AI Tier 4

### AI Chat Concierge

A future client-facing assistant for:

- Equipment discovery
- Availability questions
- Booking assistance
- Event requirement collection

### Equipment Recommendation Engine

Suggests equipment bundles based on factors such as:

- Event type
- Guest count
- Historical usage
- Available inventory

---

# 🗄️ Firestore Data Model

The core collections are:

```text
/users/{userId}

/equipment/{equipmentId}

/bookings/{bookingId}
    /items/{itemId}

/auditLogs/{logId}

/notifications/{notificationId}

/waitlist/{waitlistId}

/damageReports/{reportId}
```

Reserved collections for future layers include:

```text
/quotes/{quoteId}
/payments/{paymentId}
/reviews/{reviewId}
/warehouses/{warehouseId}
```

### Quantity-pool model

The application deliberately does not track:

```text
Speaker #1
Speaker #2
Speaker #3
...
```

Instead it tracks:

```text
Speaker
totalQuantity = 20
damagedQuantity = 2
```

and calculates committed quantity from booking line items.

---

# 📁 Repository Structure

```text
equipment-rental-app/
│
├── README.md
├── PROJECT_CONTEXT.md
├── PRD.md
├── TRD.md
├── DATA_MODEL.md
├── APPLICATION_FLOW.md
├── FOLDER_STRUCTURE.md
├── IMPLEMENTATION_PLAN.md
│
├── firebase.json
├── .firebaserc
├── firestore.rules
├── firestore.indexes.json
├── storage.rules
├── .env.example
│
├── shared/
│   ├── types/
│   │   ├── booking.ts
│   │   ├── equipment.ts
│   │   ├── user.ts
│   │   └── index.ts
│   └── constants/
│       ├── bookingStatuses.ts
│       └── roles.ts
│
├── app/
│   ├── lib/
│   │   ├── core/
│   │   ├── services/
│   │   ├── models/
│   │   ├── state/
│   │   ├── features/
│   │   └── shared_widgets/
│   ├── test/
│   ├── integration_test/
│   ├── assets/
│   └── pubspec.yaml
│
└── functions/
    ├── src/
    │   ├── booking/
    │   ├── dispatch/
    │   ├── inventory/
    │   ├── ai/
    │   ├── notifications/
    │   ├── triggers/
    │   └── shared/
    └── package.json
```

---

# 🔥 Firebase Environments

Three environments are planned:

```text
Development
    ↓
Staging
    ↓
Production
```

Firebase project aliases are managed through:

```text
.firebaserc
```

Local development uses the Firebase Emulator Suite for:

- Firestore
- Authentication
- Cloud Functions
- Storage

---

# 🧪 Testing Strategy

Testing focuses heavily on the application's core failure mode.

## Critical concurrency test

The system must pass:

```text
Initial inventory = 1

Request A ──────┐
                ├──→ Firestore Transaction
Request B ──────┘

Expected:
Exactly ONE succeeds
```

## Security Rules tests

Invalid transitions such as:

```text
Requested → Dispatched
```

must be rejected regardless of the user's role.

## Offline tests

Warehouse workflows should be tested with the network actually disabled, not only through simulated connectivity states.

## AI validation tests

Every AI-suggested action must be re-validated server-side before any database write.

---

# 📈 Development Roadmap

The project follows a dependency-first roadmap:

```text
Phase 0
Project Setup
    ↓
Phase 1
Mandatory Core
    ↓
Phase 2
Operational Excellence
    ↓
Phase 3
AI Tier 1 & 2
    ↓
Phase 4
Client Experience
    ↓
Phase 5
Business Intelligence
    ↓
Phase 6
AI Tier 3 & 4
    ↓
Phase 7
Future Platform Scale
```

### Phase 0 — Setup

- Monorepo
- Firebase environments
- Flutter project
- Cloud Functions
- Shared types
- Emulator Suite
- Security rule skeleton
- CI

### Phase 1 — Mandatory Core

- Authentication
- Roles
- Equipment catalog
- Availability engine
- Atomic booking transaction
- Booking lifecycle
- Warehouse dispatch
- Returns
- Audit trail
- Security Rules

### Phase 2 — Operational Excellence

- Buffer/turnaround time
- Damage reporting
- Delivery/pickup scheduling
- Waitlist
- Notifications
- Warehouse offline mode

### Phase 3 — AI Tier 1 & 2

- Conflict resolution
- Demand forecasting
- Natural-language booking intake
- AI-assisted quotes

### Phase 4 — Client Experience

- Client portal
- Pricing
- Quotes
- Contracts/e-signature
- Payments
- Booking history
- Reordering
- Reviews

### Phase 5 — Business Intelligence

- Equipment utilization
- Seasonal demand
- Revenue dashboards
- Staff/dispatch analytics
- Vendor equipment tracking

### Phase 6 — AI Tier 3 & 4

- Photo damage assessment
- Dispatch/route assistant
- AI concierge
- Equipment recommendations

### Phase 7 — Future Scale

- QR/barcode scanning
- Route optimization
- Multi-warehouse capability
- White-label / multi-tenant potential

---

# ⚠️ Current Open Decisions

Some architectural/product decisions intentionally remain open:

| Decision | Affects |
|---|---|
| Auto-expiry duration for stale `Requested` soft-holds | Availability engine |
| Partial fulfillment UX | Booking approval |
| Whether clients can cancel `Confirmed` bookings | Cancellation |
| First 2–3 AI features to prioritize | AI roadmap |
| Final pricing model | Quotes |
| Multi-warehouse requirement | Future architecture |

These decisions should be resolved before implementing the corresponding blocked features.

---

# 🚦 Project Status

**Status: Architecture / Implementation Planning**

The current implementation sequence prioritizes the booking and inventory backbone before higher-level features.

The most important milestone is:

> A client can request equipment, staff can approve it, warehouse staff can dispatch and receive it, all relevant users see the status live, concurrent last-unit booking attempts cannot both succeed, and every status transition is audited.

---

# 👨‍💻 Team

| Name | Role |
|---|---|
| **Jatin Yadav** | Project Admin / Developer |
| **Priyanshu Dolwani** | Developer |
| **Madhav** | Developer |

---

# 🌿 Git Workflow

Recommended feature branches:

```text
main
│
├── feature/authentication
├── feature/equipment-management
├── feature/booking
├── feature/dispatch
├── feature/notifications
├── feature/ai
└── feature/analytics
```

Pull requests should keep CI green and include appropriate tests for changes to business-critical logic.

---

# 📚 Project Documentation

The repository is intentionally documented as a set of complementary design documents:

| Document | Purpose |
|---|---|
| `PROJECT_CONTEXT.md` | Product scope and foundational decisions |
| `PRD.md` | Product requirements and feature layers |
| `TRD.md` | Technology choices and technical rationale |
| `DATA_MODEL.md` | Firestore schema and data modeling |
| `APPLICATION_FLOW.md` | Role-by-role application behavior |
| `FOLDER_STRUCTURE.md` | Repository architecture |
| `IMPLEMENTATION_PLAN.md` | Dependency-ordered implementation roadmap |
| `README.md` | Developer-facing project overview and setup |

---

# 🧠 Design Principles

### One shared availability engine

Availability and warehouse pull-list logic should use the same underlying query.

### Server-side trust

Critical business logic belongs in Cloud Functions and Security Rules, not only in the Flutter client.

### Atomic writes

Anything that checks availability and modifies inventory must use a Firestore transaction.

### Shared contracts

`shared/types/` prevents the Flutter and backend data models from silently diverging.

### AI with guardrails

AI provides suggestions and drafts; server-side validation and transactions make the final decision.

### Build the backbone first

The mandatory booking, availability, dispatch, security, and audit foundation must be correct before advanced AI and analytics features are layered on top.

---

# 📄 License

Add the project's chosen license here before public distribution.

---

## ⭐ Vision

The long-term goal is to move event-equipment rental operations from:

```text
Phone Calls
   +
Manual Availability Checks
   +
Disconnected Teams
   +
Warehouse Surprises
```

to:

```text
Real-Time Inventory
       +
Conflict-Free Booking
       +
Automated Dispatch
       +
AI Assistance
       +
Business Intelligence
       +
Client Self-Service
```

**One system. One source of truth. Zero double-booking surprises.**

