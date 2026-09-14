GearGrid High-Level Design (HLD)

1. Architecture Overview

GearGrid follows a client-server architecture using Flutter as the application layer and Firebase as the backend platform.

+---------------------------+
|       Flutter App         |
|---------------------------|
| Landing / Auth            |
| Client Storefront         |
| Cart / Payment            |
| Orders / Profile          |
| Admin Dashboard           |
+-------------+-------------+
              |
              | Firebase SDK
              v
+---------------------------+
|        Firebase           |
|---------------------------|
| Firebase Authentication  |
| Cloud Firestore           |
| Firebase Storage          |
+---------------------------+

The Flutter application communicates directly with Firebase using the official Firebase Flutter SDKs. Firestore Security Rules provide backend authorization.

2. Major Components

2.1 Authentication Layer

Technology: Firebase Authentication

Responsibilities:

registration;

login;

logout;

authentication state;

user identity.

The application listens to authStateChanges() and routes users based on authentication and application profile.

2.2 User Profile Layer

Collection: users

Responsibilities:

display name;

email;

application role.

Roles:

client
admin

2.3 Client Storefront

Flutter screen: ClientStorefrontScreen

Responsibilities:

live equipment listing;

category filtering;

event slot selection;

availability display;

cart management.

2.4 Cart and Checkout

Flutter screens:

CartScreen

PaymentScreen

Responsibilities:

event details;

venue;

quantities;

pricing;

payment method;

booking creation.

The current payment processor is intentionally simulated.

2.5 Admin Dashboard

Flutter screen: HomeScreen

Responsibilities:

inventory management;

booking monitoring;

booking approval/rejection;

dispatch progression;

equipment image upload;

booking history.

2.6 Booking Service

Service: FirestoreRepository

Responsibilities:

CRUD operations;

realtime streams;

transactional booking approval;

reservation-slot maintenance.

2.7 Availability Engine

Service: BookingEngine

The engine calculates requested versus reserved units and reports conflicts before approval.

The authoritative approval protection is implemented in the Firestore transaction inside FirestoreRepository.approveBooking().

3. Data Architecture

users
 └── userId
      ├── email
      ├── displayName
      └── role

equipment
 └── equipmentId
      ├── name
      ├── category
      ├── description
      ├── powerProfile
      ├── totalUnits
      ├── pricePerUnit
      └── imageUrl

bookings
 └── bookingId
      ├── clientId
      ├── clientName
      ├── eventName
      ├── venue
      ├── start
      ├── end
      ├── status
      ├── requestedUnits
      ├── subtotal
      ├── platformFee
      ├── taxAmount
      ├── totalAmount
      ├── paymentId
      ├── paymentMethod
      ├── mapsLink
      ├── driverName
      ├── vehicleDetails
      └── deliveryEta

reservationSlots
 └── {equipmentId}_{hourEpoch}
      ├── equipmentId
      ├── slotStart
      ├── reservedUnits
      └── updatedAt

4. Booking/Reservation Architecture

GearGrid separates a booking request from its committed inventory reservation.

Booking
   |
   | admin approval
   v
Read booking
   |
   +--> Read equipment
   |
   +--> Read reservation slots
   |
   +--> Validate capacity
   |
   +--> Update reservation slots
   |
   +--> Set booking = approved

This operation runs in one Firestore transaction.

5. Availability Model

The system uses hourly slots.

For a booking from 18:00 to 23:00, the affected slots are:

18:00
19:00
20:00
21:00
22:00

For each equipment item:

newReserved = existingReserved + requestedUnits

newReserved <= totalUnits

If the condition is false for any affected slot, the transaction fails and the booking remains unapproved.

6. Security Architecture

Firebase Auth
     |
     v
Authenticated UID
     |
     v
users/{uid}
     |
     +---- role = client
     |
     +---- role = admin

Firestore rules then authorize access.

Client

read own user profile;

read equipment;

create own booking;

read own booking;

cannot write inventory;

cannot modify bookings after creation.

Admin

read users;

read/write equipment;

read/update bookings;

write reservation slots.

7. Realtime Data Flow

The client storefront subscribes to:

equipment snapshots
reservationSlots snapshots for selected window

The admin dashboard subscribes to:

equipment snapshots
bookings snapshots

This means changes made by one operator can propagate to other connected clients without manual refresh.

8. Dispatch Flow

paid/pending
     |
     v
approved
     |
     | driver + vehicle + ETA
     v
dispatched
     |
     v
completed

Rejected bookings move to:

rejected

9. External Services

Service

Purpose

Firebase Authentication

Identity

Cloud Firestore

Users, inventory, bookings, reservation slots

Firebase Storage

Equipment images

Flutter

Application UI

Google Fonts package

Typography

10. Deployment View

Mobile / Desktop Flutter Client
              |
              v
       Firebase Project
       /      |       \
      /       |        \
   Auth   Firestore   Storage

The system does not currently require a separate REST API server for core CRUD and reservation operations.

11. Key Architectural Decisions

Firestore transaction for approval

Chosen because inventory approval is a read-modify-write operation that must remain atomic.

Reservation slot documents

Chosen to avoid repeatedly calculating overlap across every historical booking and to provide a simple capacity ledger for hourly periods.

Firebase realtime listeners

Chosen because inventory and booking status are operational data that benefit from live updates.

Role in user profile

Used for application routing and authorization. Production admin provisioning should use a trusted mechanism rather than a client-visible email rule.

12. Risks and Mitigations

Risk

Mitigation

Concurrent booking approval

Firestore transaction

Client role escalation

Firestore rules

Payment spoofing

Replace simulation with server-verified gateway

Stale UI availability

Realtime listeners + transactional approval

Inventory deletion while booked

Add validation/prevent destructive changes in production

Timezone mistakes

Store/normalize timestamps consistently