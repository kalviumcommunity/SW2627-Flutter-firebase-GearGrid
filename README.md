GearGrid

GearGrid is a Flutter + Firebase application for managing event-equipment rentals, inventory availability, bookings, approvals, and dispatch.

It is designed for a regional event-equipment rental company that supplies sound systems, lighting, visual equipment, and furniture for weddings and corporate events.

Problem

The existing rental workflow relies heavily on phone calls and manual coordination. During peak season, the same physical equipment can be committed to overlapping events, with the conflict sometimes discovered only when the warehouse team starts loading.

GearGrid addresses this by making event slots, equipment quantities, booking status, and reservation capacity visible in one system.

Core Objectives

Show equipment availability for a selected event window.

Allow clients to browse equipment and create an event booking.

Capture event, venue, quantity, pricing, and payment information.

Give administrators a real-time booking queue.

Prevent approval of a booking when requested quantities exceed inventory during the selected time window.

Maintain hourly reservation slots so inventory commitments can be checked consistently.

Move approved bookings through dispatch and completion states.

Keep client and admin access separated through Firebase Authentication and Firestore rules.

Current Technology Stack

Frontend: Flutter / Dart

Authentication: Firebase Authentication

Database: Cloud Firestore

Images: Firebase Storage

UI: Material widgets, Google Fonts, custom theme/widgets

Platforms: Flutter-supported platforms configured by the project

Application Flow

Landing
   |
   v
Authentication
   |
   +--------------------+
   |                    |
 Client               Admin
   |                    |
   v                    v
Storefront          Dispatch Dashboard
   |
Select event slot
   |
Browse equipment
   |
Add quantities
   |
Cart
   |
Payment
   |
Booking created
   |
Admin approval
   |
Reservation slots locked
   |
Dispatch
   |
Completed

Main Features

Client

Email/password registration and login.

Browse equipment by category.

Select an event date/time window.

View live reserved quantities and calculated availability.

Add/remove equipment quantities.

Review event and delivery details.

Review subtotal, platform fee, tax, and total.

Simulated UPI/card/wallet payment flow.

View order history and booking status.

Profile and help/support screens.

Admin

Real-time equipment inventory.

Real-time booking queue.

Approve or reject incoming bookings.

Transactional availability validation during approval.

Automatic creation/update of hourly reservation slots.

Dispatch workflow with driver and vehicle information.

Move bookings from approved → dispatched → completed.

Add, edit, remove, and adjust equipment inventory.

Upload equipment images to Firebase Storage.

View historical completed/rejected bookings.

Booking Statuses

Status

Meaning

paid

Payment/order received and waiting for confirmation

pending

Legacy/backward-compatible pending state

approved

Admin confirmed the booking and inventory reservation

dispatched

Equipment has been sent out

completed

Event/order completed

rejected

Booking declined/cancelled

Inventory Conflict Logic

The important inventory rule is:

For every equipment item
and every hourly slot in the event window:

existing reserved units + requested units
must be <= total inventory units

Approval is performed inside a Firestore transaction. The transaction reads the booking, reads the required inventory records, reads the relevant reservation-slot documents, validates capacity, updates the reservation slots, and finally changes the booking to approved.

This is the critical protection against two administrators approving conflicting commitments at the same time.

Firestore Collections

users/{userId}
equipment/{equipmentId}
bookings/{bookingId}
reservationSlots/{slotId}

users

Stores application profile information and the application role.

equipment

Stores inventory information such as name, category, total units, price, description, power profile, and optional image URL.

bookings

Stores client, event, venue, time window, requested quantities, financial information, payment metadata, and dispatch information.

reservationSlots

Stores the reserved quantity for a particular equipment item and hourly time slot.

Project Structure

lib/
├── app.dart
├── main.dart
├── data/
│   └── demo_repository.dart
├── models/
│   ├── app_role.dart
│   ├── app_user.dart
│   ├── booking.dart
│   └── equipment.dart
├── screens/
│   ├── auth_screen.dart
│   ├── cart_screen.dart
│   ├── client_storefront_screen.dart
│   ├── help_support_screen.dart
│   ├── home_screen.dart
│   ├── landing_screen.dart
│   ├── order_history_screen.dart
│   ├── payment_screen.dart
│   └── profile_settings_screen.dart
├── services/
│   ├── booking_engine.dart
│   └── firestore_repository.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── glass_panel.dart
    └── live_pulse_dot.dart

Setup

Prerequisites

Flutter SDK

Dart SDK compatible with the version in pubspec.yaml

A Firebase project

Firebase Authentication enabled

Cloud Firestore enabled

Firebase Storage enabled if equipment images are used

Install

flutter pub get

Firebase

The project contains Firebase configuration files for the configured platforms.

Before running a new Firebase project, make sure the Flutter Firebase configuration points to the intended Firebase project.

Run

flutter run

Security Notes

Firebase Authentication identifies the user, while the Firestore users document determines the application role.

The current Firestore rules enforce:

authenticated users can access equipment;

only admins can write equipment;

clients can read their own bookings;

admins can read bookings;

clients can create bookings only for themselves;

booking updates/deletes are admin-only;

reservation-slot writes are admin-only.

For production, admin provisioning should be moved away from a client-controlled email check and handled with a trusted server-side/admin process or Firebase custom claims.

Important Production Considerations

The current payment screen simulates payment processing. A real deployment should use a trusted payment gateway and verify payment server-side before treating an order as paid.

Availability is protected at admin approval time. For a stronger production reservation experience, the booking creation flow can also introduce temporary holds with expiry, followed by payment confirmation and transactional reservation.

Other recommended production additions:

server-side payment verification;

audit logs for booking/inventory changes;

cancellation and refund rules;

timezone normalization;

dispatch preparation/checklist;

warehouse loading confirmation;

notifications for booking/dispatch changes;

stronger admin provisioning;

automated tests for concurrent booking scenarios.

Documentation

PRD.md - Product Requirements Document

HLD.md - High-Level Design

LLD.md - Low-Level Design