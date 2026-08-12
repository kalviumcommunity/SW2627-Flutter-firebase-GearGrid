# Product Requirements Document (PRD)

# Event Equipment Rental & Booking System

## 1. Project Overview

The **Event Equipment Rental & Booking System** is a platform for managing the rental of event equipment such as sound systems, lighting equipment, tables, chairs, microphones, and other event-related items.

The system will allow customers to check equipment availability and create bookings while allowing administrators to manage equipment, bookings, availability, and dispatch schedules.

The main purpose of the system is to **prevent double bookings and equipment conflicts**.

---

## 2. Problem Statement

Currently, the rental company manages equipment bookings and dispatch schedules mainly through phone calls and manual coordination.

This creates several problems:

* The same equipment can be booked for multiple events at the same time.
* Equipment availability is difficult to track.
* Booking conflicts may only be discovered when equipment is being prepared for dispatch.
* Customers do not have a simple way to check availability.
* Admins have difficulty managing multiple bookings.
* Manual scheduling increases the possibility of human errors.

The system will solve these problems by maintaining a centralized record of equipment and bookings and automatically checking availability before confirming a booking.

---

## 3. Product Goal

The primary goal of the system is:

> **To prevent equipment double-booking by automatically checking equipment availability before confirming a booking.**

The system should provide:

* Easy equipment discovery for customers
* Accurate availability checking
* Reliable booking management
* Admin control over equipment and bookings
* Clear dispatch scheduling

---

## 4. Target Users

The system will have two main types of users.

### 4.1 Customer

Customers use the system to:

* Register and log in
* View available equipment
* Select required equipment
* Select event date and time
* Create bookings
* View booking details
* Track booking status
* Cancel eligible bookings

### 4.2 Admin

Admins use the system to:

* Manage equipment
* Manage equipment quantities
* View all bookings
* Approve or reject bookings
* Update booking status
* Check equipment availability
* Manage dispatch schedules
* Identify booking conflicts

---

# 5. User Roles & Permissions

| Feature                   | Customer | Admin |
| ------------------------- | -------- | ----- |
| Register                  | Yes      | No    |
| Login                     | Yes      | Yes   |
| View Equipment            | Yes      | Yes   |
| Create Booking            | Yes      | Yes   |
| View Own Bookings         | Yes      | Yes   |
| View All Bookings         | No       | Yes   |
| Cancel Own Booking        | Yes*     | Yes   |
| Manage Equipment          | No       | Yes   |
| Update Equipment Quantity | No       | Yes   |
| Update Booking Status     | No       | Yes   |
| Manage Dispatch           | No       | Yes   |

*Cancellation depends on the booking status and business rules.

---

# 6. Core Features

## 6.1 Authentication

The system should provide secure authentication.

### Customer

Customers should be able to:

* Register
* Login
* Logout
* Access their bookings

### Admin

Admins should be able to:

* Login
* Logout
* Access admin features

The system must ensure that customers cannot access admin-only functionality.

---

# 7. Equipment Management

Admins should be able to manage all rental equipment.

Each equipment item should contain information such as:

* Equipment name
* Category
* Description
* Total quantity
* Available quantity
* Rental price
* Equipment status

### Example Equipment

```text
Speakers
Microphones
Stage Lights
Chairs
Tables
Sound Mixers
Projectors
```

### Admin Actions

Admin can:

* Add equipment
* Edit equipment
* Remove equipment
* Update quantity
* View equipment
* Mark equipment as unavailable

---

# 8. Equipment Availability

The system must automatically calculate whether the requested equipment is available for the selected date and time.

Availability depends on:

* Equipment
* Required quantity
* Booking date
* Start time
* End time
* Existing confirmed bookings

### Example

Suppose the company owns:

```text
Total Speakers = 10
```

Existing booking:

```text
Event A
6 Speakers
10:00 AM - 2:00 PM
```

New customer requests:

```text
5 Speakers
11:00 AM - 1:00 PM
```

The system calculates:

```text
6 + 5 = 11 speakers required
```

But only 10 speakers exist.

Therefore:

```text
Booking = Rejected
```

The system should display:

> Selected equipment is not available for the requested time.

---

# 9. Booking System

Customers should be able to create equipment rental bookings.

## Booking Process

```text
Login
  ↓
Browse Equipment
  ↓
Select Equipment
  ↓
Select Quantity
  ↓
Select Event Date
  ↓
Select Start & End Time
  ↓
Enter Event Details
  ↓
Check Availability
  ↓
Available?
 ┌───────────────┐
 Yes             No
 ↓                ↓
Create Booking   Show Error
 ↓
Booking Created
```

---

# 10. Booking Information

Each booking should contain:

* Booking ID
* Customer ID
* Event name
* Event location
* Event date
* Start time
* End time
* Selected equipment
* Equipment quantity
* Booking status
* Created date
* Updated date

---

# 11. Double Booking Prevention

This is the **most important business requirement** of the system.

The system must never confirm a booking when the required equipment quantity is unavailable during the requested time period.

## Overlapping Booking Rule

Two bookings overlap when:

```text
New Start < Existing End
AND
New End > Existing Start
```

If the bookings overlap, the system must check the total equipment quantity being used.

### Example

Total chairs:

```text
100
```

Existing booking:

```text
60 chairs
10 AM - 2 PM
```

New booking:

```text
50 chairs
12 PM - 3 PM
```

Because the times overlap:

```text
60 + 50 = 110
```

Available:

```text
100
```

Therefore:

```text
Booking rejected
```

---

# 12. Booking Status

Bookings should have the following statuses:

```text
PENDING
CONFIRMED
DISPATCHED
COMPLETED
CANCELLED
REJECTED
```

### Status Flow

```text
PENDING
   ↓
CONFIRMED
   ↓
DISPATCHED
   ↓
COMPLETED
```

A booking can also become:

```text
PENDING → REJECTED
```

or

```text
CONFIRMED → CANCELLED
```

depending on the business rules.

---

# 13. Booking Management

## Customer

Customers should be able to:

* View their bookings
* View booking details
* Check booking status
* Cancel eligible bookings

## Admin

Admins should be able to:

* View all bookings
* Search bookings
* Filter bookings
* Approve bookings
* Reject bookings
* Cancel bookings
* Update booking status
* View upcoming bookings

---

# 14. Dispatch Management

The system should help the warehouse team prepare equipment for upcoming events.

Admin should be able to view:

* Event name
* Customer
* Event location
* Event date
* Start time
* End time
* Equipment required
* Quantity required
* Dispatch status

### Example

```text
Event: Sharma Wedding

Date: 20 August 2026
Time: 5 PM - 11 PM

Equipment:
- Speakers: 6
- Microphones: 4
- Lights: 10

Status:
CONFIRMED
```

This allows the warehouse team to prepare the required equipment before dispatch.

---

# 15. Search & Filtering

The system should allow admins to find bookings quickly.

Admin should be able to filter bookings by:

* Date
* Booking status
* Customer
* Equipment
* Event

Customers should be able to filter their booking history by:

* Date
* Status

---

# 16. Notifications

For the MVP, notifications are optional.

In future versions, the system can provide:

* Booking confirmation
* Booking rejection
* Booking cancellation
* Dispatch notification
* Booking reminder

Notifications may be sent through:

* Email
* SMS
* Push notifications

---

# 17. Functional Requirements

## Customer Requirements

* Customer must be able to register.
* Customer must be able to login.
* Customer must be able to view equipment.
* Customer must be able to select equipment and quantity.
* Customer must be able to select event date and time.
* Customer must be able to create a booking.
* System must check equipment availability.
* System must prevent overlapping equipment conflicts.
* Customer must be able to view booking history.
* Customer must be able to view booking status.
* Customer must be able to cancel eligible bookings.

## Admin Requirements

* Admin must be able to login.
* Admin must be able to add equipment.
* Admin must be able to edit equipment.
* Admin must be able to remove equipment.
* Admin must be able to update equipment quantity.
* Admin must be able to view all bookings.
* Admin must be able to approve/reject bookings.
* Admin must be able to update booking status.
* Admin must be able to view dispatch schedules.
* Admin must be able to identify equipment conflicts.

---

# 18. Non-Functional Requirements

## Security

* User passwords must be securely stored.
* Authentication must be implemented securely.
* Customers must not access admin functionality.
* Sensitive user information must be protected.

## Performance

* Availability checks should return quickly.
* Booking operations should be reliable.
* The system should support multiple users.

## Reliability

The system must correctly prevent double bookings even when multiple customers try to book the same equipment at nearly the same time.

## Usability

* The interface should be simple.
* Important information should be easy to find.
* Booking errors should have clear messages.

## Scalability

The system should be designed so that the company can add:

* More equipment
* More customers
* More bookings
* More administrators

in the future.

---

# 19. Important Business Rules

### Rule 1 — Equipment Quantity

A booking cannot be confirmed if the requested quantity is greater than the available quantity.

### Rule 2 — Time Overlap

The system must check existing bookings for overlapping time periods.

### Rule 3 — Cancelled Bookings

Cancelled bookings should no longer consume equipment availability.

### Rule 4 — Completed Bookings

Completed bookings should remain in booking history but should not block future availability.

### Rule 5 — Equipment Availability

Equipment marked unavailable by an admin cannot be booked.

### Rule 6 — Booking Validation

Start time must be before end time.

### Rule 7 — Past Dates

Customers should not be allowed to create bookings for dates/times that have already passed.

### Rule 8 — Atomic Booking

Availability checking and booking creation should be handled safely so that two users cannot successfully reserve the same limited equipment at the same time.

---

# 20. Main User Flow

## Customer Flow

```text
Register/Login
      ↓
Browse Equipment
      ↓
Select Equipment
      ↓
Select Quantity
      ↓
Select Date & Time
      ↓
Enter Event Details
      ↓
Check Availability
      ↓
Available?
   /       \
 Yes       No
 ↓          ↓
Create     Show
Booking    Error
 ↓
View Booking
 ↓
Track Status
```

## Admin Flow

```text
Admin Login
     ↓
Dashboard
     ↓
Manage Equipment
     ↓
View Bookings
     ↓
Check Availability
     ↓
Approve / Reject
     ↓
Manage Dispatch
     ↓
Update Status
```

---

# 21. Suggested Main Screens

## Customer Screens

1. Login
2. Register
3. Home
4. Equipment List
5. Equipment Details
6. Create Booking
7. Booking Confirmation
8. My Bookings
9. Booking Details
10. Profile

## Admin Screens

1. Admin Login
2. Admin Dashboard
3. Equipment Management
4. Add Equipment
5. Edit Equipment
6. Booking Management
7. Booking Details
8. Availability Calendar
9. Dispatch Schedule

---

# 22. MVP Scope

The first version of the project should focus only on the most important functionality.

### MVP Features

* Customer registration/login
* Admin login
* Equipment management
* Equipment listing
* Equipment quantity management
* Date/time selection
* Booking creation
* Availability checking
* Double booking prevention
* Customer booking history
* Admin booking management
* Booking status management
* Basic dispatch schedule

### Not Required for MVP

The following can be added later:

* Online payments
* SMS notifications
* Email notifications
* Invoices
* Analytics
* Maintenance tracking
* Delivery staff management
* Advanced reports

---

# 23. Future Enhancements

Future versions may include:

* Online payment integration
* Email/SMS notifications
* Automatic booking reminders
* Invoice generation
* Equipment maintenance tracking
* Advanced analytics
* Calendar integration
* Delivery tracking
* Staff management
* Customer reviews
* Mobile application
* Multi-location inventory management

---

# 24. Success Criteria

The project will be considered successful when:

1. Customers can register and login.
2. Customers can view available equipment.
3. Customers can select equipment and quantities.
4. Customers can select event dates and times.
5. The system checks equipment availability.
6. The system prevents double bookings.
7. Admins can manage equipment.
8. Admins can manage bookings.
9. Admins can update booking status.
10. Admins can view dispatch schedules.
11. Booking conflicts are detected before equipment dispatch.
12. Equipment quantities are correctly calculated for overlapping bookings.

---

# 25. Technology

The exact technology stack can be finalized based on project requirements.

### Possible Stack

**Frontend**

* Flutter

**Backend**

* Node.js
* Express.js

**Database**

* PostgreSQL

**Authentication**

* JWT

**API**

* REST API

**Version Control**

* Git
* GitHub

The final technology stack may be changed if required.

---

# 26. High-Level System Architecture

```text
                Customer
                   ↓
             Flutter App
                   ↓
              REST API
                   ↓
          Node.js / Express
                   ↓
          Business Logic
                   ↓
        Availability Checking
                   ↓
             PostgreSQL
                   ↓
        Booking & Equipment Data
```

Admin will use the same backend through an admin interface.

---

# 27. Core Data Entities

The system will primarily require the following entities:

```text
User
  ↓
Booking
  ↓
BookingItem
  ↓
Equipment
```

Additional entities may include:

```text
Dispatch
Category
Notification
```

### Basic Relationship

```text
User
  │
  └──< Booking
          │
          └──< BookingItem >── Equipment
```

One customer can have multiple bookings.

One booking can contain multiple equipment items.

One equipment type can appear in multiple bookings.

---

# 28. Final Product Objective

The final system should replace manual phone-based equipment booking with a centralized digital system.

The most important outcome is:

> **Before confirming any booking, the system must verify that the required equipment quantity is available for the requested date and time.**

This will reduce booking conflicts, improve warehouse preparation, make booking easier for customers, and help the company manage its equipment more efficiently.
