# Product Requirements Document (PRD)

## 1. Project Title

**Event Equipment Rental & Booking System**

---

## 2. Problem Statement

A regional event equipment rental company supplies sound systems, lighting, and furniture for weddings and corporate events.

Currently, bookings and dispatch schedules are managed through individual phone calls. During peak season, the same equipment can be committed to multiple events at overlapping times.

The company often discovers these conflicts only when the warehouse team starts preparing the equipment.

This creates confusion, delays, and problems for both the company and customers.

---

## 3. Project Goal

The main goal of this system is to:

> **Prevent double bookings by checking equipment availability before confirming a booking.**

The system should make it easy for customers to book equipment and for admins to manage bookings and equipment availability.

---

## 4. Users

### Customer

Customers can:

* View available equipment
* Select equipment
* Select event date and time
* Create a booking
* View their bookings
* Check booking status

### Admin

Admins can:

* Add and manage equipment
* View all bookings
* Check equipment availability
* Approve or manage bookings
* Update booking status
* Manage dispatch schedules
* Prevent overlapping bookings

---

## 5. Core Features

### 5.1 Equipment Management

Admin can:

* Add equipment
* Update equipment details
* Remove equipment
* Set equipment quantity
* View available equipment

Examples:

* Speakers
* Microphones
* Lights
* Chairs
* Tables

---

### 5.2 Equipment Availability

The system should check:

* Equipment required
* Booking date
* Start time
* End time
* Available quantity

If the required equipment is already booked for that time, the system should **not allow the booking**.

---

### 5.3 Customer Booking

Customer can:

1. Select equipment
2. Select event date
3. Select start and end time
4. Enter event details
5. Submit booking

The system checks availability before confirming the booking.

---

### 5.4 Double Booking Prevention

This is the **most important feature**.

Example:

If:

**Event A → Speaker → 10 AM–2 PM**

is already booked, another customer should **not be able to book the same unavailable speaker for an overlapping time**.

The system should show a message such as:

> "Selected equipment is not available for this time."

---

### 5.5 Booking Management

Customers can:

* View their bookings
* See booking details
* Check booking status
* Cancel a booking if allowed

Admins can:

* View all bookings
* Approve/reject bookings
* Update booking status
* Cancel bookings
* View booking schedules

---

### 5.6 Dispatch Management

Admin can see:

* Event details
* Equipment required
* Event date
* Start/end time
* Dispatch status

This helps the warehouse team prepare the correct equipment.

---

## 6. Booking Status

A booking can have statuses such as:

* **Pending**
* **Confirmed**
* **Dispatched**
* **Completed**
* **Cancelled**

---

## 7. Basic Booking Flow

```text
Customer
   ↓
Login / Register
   ↓
Select Equipment
   ↓
Select Date & Time
   ↓
Check Availability
   ↓
Available?
  / \
Yes  No
 ↓    ↓
Book  Show Error
 ↓
Booking Confirmed
```

---

## 8. Functional Requirements

### Customer Requirements

* Customer should be able to register/login.
* Customer should be able to view equipment.
* Customer should be able to select date and time.
* Customer should be able to create a booking.
* System should check equipment availability.
* System should prevent overlapping bookings.
* Customer should be able to view booking history.

### Admin Requirements

* Admin should be able to login.
* Admin should be able to manage equipment.
* Admin should be able to view all bookings.
* Admin should be able to manage booking status.
* Admin should be able to view dispatch schedules.
* Admin should be able to identify equipment availability.

---

## 9. Non-Functional Requirements

* **Security:** Customer and admin data should be protected.
* **Reliability:** The system should correctly prevent double bookings.
* **Performance:** Availability checks should be fast.
* **Usability:** The interface should be simple and easy to understand.
* **Scalability:** The system should support more customers, equipment, and bookings in the future.

---

## 10. Important Business Rule

The system **must not confirm a booking if the required equipment quantity is unavailable during the requested time period.**

For example:

```text
Available speakers = 10

Event A books = 6 speakers
Event B wants = 5 speakers

6 + 5 = 11

Only 10 are available
→ Booking B must be rejected
```

---

## 11. Success Criteria

The project will be successful if:

* Customers can make equipment bookings.
* Admin can manage equipment and bookings.
* The system correctly checks availability.
* The same equipment cannot be double-booked.
* Admin can view upcoming bookings and dispatch schedules.
* Booking conflicts are detected before the warehouse/loading stage.

---

## 12. Future Enhancements

Possible future features:

* Online payment
* Email/SMS notifications
* Automatic reminders
* Invoice generation
* Equipment maintenance tracking
* Reports and analytics
* Calendar-based scheduling
* Delivery staff management
* Mobile application

---

## 13. Platform

**To be decided.**

The system can later be implemented as a web application or mobile application depending on the project requirements.
