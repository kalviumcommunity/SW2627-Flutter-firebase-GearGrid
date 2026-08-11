# Event Equipment Rental Management App

## Overview

A regional event equipment rental company provides **sound systems, lighting equipment, and furniture** for weddings and corporate events.

Currently, bookings and dispatch schedules are managed through individual phone calls. This manual process can result in the **same equipment being booked for multiple events at overlapping times**, with the conflict often discovered only when the warehouse team starts preparing the equipment for dispatch.

This project aims to build a **mobile application** that helps the rental company manage equipment bookings, track availability, and prevent overlapping equipment assignments.

---

## Problem Statement

A regional event equipment rental company supplies sound systems, lighting, and furniture for weddings and corporate events, but bookings and dispatch schedules are coordinated through individual phone calls.

During peak season, the same equipment gets committed to overlapping events, and the team finds out only when the warehouse crew begins loading.

The application will provide a centralized system for managing bookings and equipment availability, reducing scheduling conflicts and improving dispatch coordination.

---

## Proposed Solution

We are building a **Flutter-based mobile application** that allows the rental team to:

* Manage event equipment bookings
* View equipment availability
* Check existing bookings before assigning equipment
* Prevent overlapping bookings
* Track upcoming events and dispatch schedules
* Maintain centralized booking information
* Reduce dependency on phone-based coordination

The application will use **Firebase** for authentication, database management, and cloud storage where required.

---

## Target Users

### Rental Staff / Admin

The primary users of the application are the employees responsible for:

* Managing equipment
* Creating bookings
* Checking equipment availability
* Updating booking information
* Managing dispatch schedules
* Monitoring upcoming events

### Warehouse Team

The warehouse team can use the application to:

* View upcoming dispatches
* Check equipment assigned to each event
* Prepare equipment based on confirmed bookings
* Identify scheduling conflicts before loading

---

## Key Features

### 1. Equipment Management

Staff can manage the equipment available for rental.

Examples:

* Sound systems
* Speakers
* Microphones
* Lighting equipment
* Tables
* Chairs
* Other event furniture

### 2. Event Booking

Staff can create bookings containing information such as:

* Customer name
* Event type
* Event date
* Event location
* Required equipment
* Dispatch details

### 3. Equipment Availability

The application checks whether equipment is already assigned to another event during the requested period.

### 4. Overlapping Booking Prevention

Before confirming a booking, the system checks existing bookings.

If the requested equipment is already assigned to another event during an overlapping time period, the application prevents the conflicting assignment.

### 5. Booking Management

Staff can:

* Create bookings
* View bookings
* Update bookings
* Cancel bookings
* View booking details

### 6. Dispatch Schedule

The team can view upcoming dispatches and see:

* Event details
* Equipment required
* Event date and time
* Event location
* Dispatch status

### 7. Search & Filtering

Staff can search and filter bookings based on information such as:

* Event date
* Customer
* Event type
* Booking status
* Equipment

---

## 🛠️ Technology Stack

| Technology                  | Purpose                            |
| --------------------------- | ---------------------------------- |
| **Flutter**                 | Cross-platform mobile application  |
| **Dart**                    | Programming language               |
| **Firebase Authentication** | User authentication                |
| **Cloud Firestore**         | Store bookings and equipment data  |
| **Firebase Storage**        | Store images/documents if required |
| **Git & GitHub**            | Version control and collaboration  |

---

## Application Architecture

The basic application flow is:

```text
User
  ↓
Flutter Mobile App
  ↓
Firebase Authentication
  ↓
Cloud Firestore
  ↓
Security Rules
  ↓
Bookings / Equipment / Dispatch Data
```

### Booking Flow

```text
Staff selects equipment
        ↓
Selects event date & time
        ↓
System checks existing bookings
        ↓
   ┌───────────────┐
   │ Equipment     │
   │ Available?    │
   └───────┬───────┘
           │
      ┌────┴────┐
      ↓         ↓
     YES        NO
      ↓         ↓
Create      Show Conflict
Booking      Message
      ↓
Update Firestore
      ↓
Booking Confirmed
```

---

## Planned Firestore Collections

The application will use Cloud Firestore to store application data.

### Users

```text
users
 └── userId
      ├── name
      ├── email
      ├── role
      └── createdAt
```

### Equipment

```text
equipment
 └── equipmentId
      ├── name
      ├── category
      ├── quantity
      ├── availableQuantity
      └── status
```

### Bookings

```text
bookings
 └── bookingId
      ├── customerName
      ├── eventType
      ├── eventDate
      ├── startTime
      ├── endTime
      ├── location
      ├── equipment
      ├── status
      └── createdBy
```

### Dispatches

```text
dispatches
 └── dispatchId
      ├── bookingId
      ├── dispatchDate
      ├── dispatchTime
      ├── equipment
      ├── status
      └── assignedTo
```

> The final Firestore schema will be refined during the System Design phase based on the actual requirements of the product.

---

## 📱 Planned Screens

### Authentication

* Login
* Register

### Main Application

* Dashboard
* Equipment List
* Equipment Details
* Create Booking
* Booking List
* Booking Details
* Dispatch Schedule
* Profile / Settings

---

## Security

Firebase Authentication will be used to control access to the application.

Firestore Security Rules will ensure that users can only perform operations allowed by their role.

Example roles:

```text
Admin
Staff
Warehouse
```

Access permissions will be finalized during implementation.

---

## Project Structure

```text
event-equipment-rental/
│
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   │
│   ├── models/
│   │
│   ├── screens/
│   │
│   ├── widgets/
│   │
│   ├── services/
│   │
│   ├── providers/
│   │
│   └── utils/
│
├── test/
│
├── pubspec.yaml
├── README.md
└── .gitignore
```

---

##  Team

| Name            | Role                      |
| --------------- | ------------------------- |
| **Jatin Yadav** | Project Admin / Developer |
| **Priyanshu Dolwani** | Developer                 |
| **Madhav**  | Developer                 |

---


## Git Workflow

```text
main
 │
 ├── feature/equipment-management
 │
 ├── feature/booking
 │
 ├── feature/dispatch
 │
 └── feature/authentication
```


---

## Project Goals

The primary goals of this application are:

1. **Prevent overlapping equipment bookings**
2. **Centralize booking information**
3. **Improve equipment availability visibility**
4. **Improve warehouse dispatch coordination**
5. **Reduce dependency on phone-based coordination**
6. **Provide a reliable mobile workflow for rental staff**


---

## Future Scope

Potential improvements after the core application:

* Push notifications for upcoming dispatches
* Calendar-based booking view
* Customer management
* Booking reports
* Equipment maintenance tracking
* Automated dispatch reminders
* Analytics dashboard
* Role-based access improvements

---

## Project Status

**Status:** 🚧 In Development

**Sprint:** Mobile App Development

**Platform:** Android / Cross-platform

**Framework:** Flutter

**Backend:** Firebase


