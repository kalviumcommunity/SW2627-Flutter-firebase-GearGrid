GearGrid Product Requirements Document (PRD)

1. Product Overview

Product: GearGrid
Product Type: Event equipment rental and dispatch management system
Primary Users: Clients and rental-company administrators

GearGrid replaces phone-based equipment coordination with a centralized application where clients can select an event window, request equipment, make an order, and track its status while administrators control inventory, approvals, reservations, and dispatch.

2. Problem Statement

A regional event equipment rental company supplies sound systems, lighting, and furniture for weddings and corporate events. Bookings and dispatch schedules are coordinated through individual phone calls.

During peak periods:

the same equipment can be promised to multiple events;

availability is difficult to verify;

warehouse staff may discover conflicts only during loading;

administrators lack a single live view of bookings and inventory;

clients have limited visibility into order status.

The product must make equipment commitments explicit and enforce capacity before an administrator confirms a booking.

3. Goals

Primary Goals

Centralize equipment inventory and event bookings.

Show availability for a selected event window.

Prevent inventory over-commitment.

Give admins a real-time approval and dispatch dashboard.

Provide clients with a simple booking and order-tracking experience.

Maintain role-based access and backend authorization.

Secondary Goals

Improve warehouse preparation.

Reduce manual phone coordination.

Make pricing transparent.

Provide a foundation for future delivery tracking and notifications.

4. Non-Goals

The first version does not attempt to provide:

a full ERP/accounting system;

route optimization;

automated driver navigation;

real payment settlement without a payment provider;

multi-company marketplace functionality;

predictive demand forecasting.

5. Personas

Client

An event organizer or customer renting equipment for a wedding, corporate event, reception, or similar function.

Needs:

reliable availability;

quick equipment selection;

clear pricing;

booking confirmation;

order status visibility.

Admin

A rental-company operator responsible for inventory, approvals, and dispatch.

Needs:

live inventory;

incoming booking queue;

conflict protection;

dispatch details;

historical orders.

Warehouse/Dispatch Staff

A future operational persona.

Needs:

approved dispatch schedule;

equipment quantities;

event and venue information;

driver/vehicle information;

loading confirmation.

6. User Journeys

6.1 Client Booking Journey

Open app
  ↓
Register/Login
  ↓
Select event date/time
  ↓
Browse equipment
  ↓
Select quantities
  ↓
Review cart
  ↓
Enter event/venue details
  ↓
Payment
  ↓
Booking created
  ↓
Wait for admin confirmation
  ↓
Track order

6.2 Admin Approval Journey

Admin login
  ↓
View booking queue
  ↓
Open incoming booking
  ↓
Check requested inventory
  ↓
Transactional capacity validation
  ↓
If capacity available → Approve
If capacity unavailable → Reject approval / show conflict

6.3 Dispatch Journey

Approved
  ↓
Enter driver details
  ↓
Enter vehicle details
  ↓
Dispatch
  ↓
Equipment delivered
  ↓
Completed

7. Functional Requirements

FR-01 Authentication

The system shall allow users to:

register using email/password;

sign in using email/password;

sign out;

maintain a Firebase-authenticated session.

FR-02 Role Management

The system shall support:

Client role;

Admin role.

The UI shall route authenticated clients to the storefront and admins to the management dashboard.

FR-03 Equipment Management

Admins shall be able to:

add equipment;

edit equipment;

delete equipment;

change total unit count;

set price per unit;

assign category;

upload an equipment image.

Clients shall be able to view equipment available for their selected event window.

FR-04 Event Slot Selection

A client shall select:

event date;

event start time.

The application currently derives the default event end time as five hours after the selected start time.

FR-05 Availability

For each equipment item:

available = totalUnits - reservedUnits

The client shall not be able to add more units than the currently displayed available quantity.

FR-06 Cart

The client shall be able to:

add equipment;

remove equipment;

change quantities;

review event slot;

review pricing.

FR-07 Booking

A booking shall contain at minimum:

client ID;

client name;

event name;

venue;

start time;

end time;

requested equipment quantities;

booking status.

The implementation also stores payment and dispatch metadata.

FR-08 Payment

The current product shall provide a simulated checkout supporting:

UPI;

card;

wallet.

A production release must replace the simulation with a real payment provider and server-side verification.

FR-09 Approval and Conflict Prevention

When an admin approves a booking:

booking must be in an approvable state;

required equipment must still exist;

every affected hourly reservation slot must be read;

reserved quantity plus requested quantity must not exceed inventory;

reservation slots must be updated transactionally;

booking status must change to approved.

If any capacity check fails, the booking must not be approved.

FR-10 Rejection

Admins shall be able to reject an incoming booking.

FR-11 Dispatch

Admins shall be able to move an approved booking to dispatched and provide:

driver name/phone information;

vehicle details;

delivery ETA.

FR-12 Completion

Admins shall be able to move a dispatched booking to completed.

FR-13 Order History

Clients shall be able to review their orders. Admins can access booking history for completed/rejected records.

FR-14 Error Handling

The UI shall surface:

authentication errors;

connection problems;

booking conflicts;

failed writes;

invalid form input.

8. Non-Functional Requirements

Performance

Equipment and bookings should update through Firestore realtime listeners.

Availability calculations should avoid unnecessary full-dataset processing.

Booking approval should use a Firestore transaction.

Security

All application data access must require authentication.

Admin writes must be protected by Firestore rules.

A client must not be able to create a booking for another user.

Role escalation must not be client-controlled.

Reliability

A booking approval must be atomic.

Partial reservation updates must not be allowed.

The system should recover gracefully from network errors.

Usability

Client booking should require minimal steps.

Availability should be visible before checkout.

Admin conflict messages should identify the unavailable equipment.

9. Acceptance Criteria

AC-01 No Overbooking

Given equipment has 10 total units and 8 units are already reserved for the relevant slot, a new request for 3 units must not be approved.

AC-02 Valid Approval

Given equipment has 10 total units and 6 units are reserved, a request for 4 units may be approved.

AC-03 Concurrent Approvals

If two admins attempt to approve bookings that together exceed inventory, Firestore transaction semantics must allow at most the capacity-supported approval to succeed.

AC-04 Client Isolation

A client must not be able to read another client's booking.

AC-05 Admin Access

An authenticated admin can view and manage inventory and bookings.

AC-06 Dispatch

An approved booking can move to dispatched only through the admin workflow.

10. Success Metrics

For a pilot deployment:

zero confirmed inventory-overlap incidents caused by system approval;

100% of approved bookings have a defined event window;

reduced manual phone-based availability checks;

faster admin approval time;

fewer warehouse loading conflicts.

11. Future Enhancements

temporary inventory holds;

automated expiry of unpaid holds;

real payment integration;

push/SMS/email notifications;

calendar-style dispatch board;

warehouse loading checklist;

QR/barcode equipment scanning;

equipment maintenance status;

driver mobile workflow;

analytics and peak-season demand forecasting.