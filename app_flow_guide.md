# Gear Grid: App Flow Guide

This guide explains the "happy path" and overall navigation flow of the Gear Grid application. It breaks down how users move from opening the app to completing a successful booking.

---

## 1. The Entry Point: Authentication Gate
When the app launches, it checks if the user is already logged in (using Firebase Auth). This logic is handled in the `_AuthGate` inside `lib/app.dart`.

*   **Logged Out / First Time User:**
    *   The app displays the **`LandingScreen`** (`landing_screen.dart`). This is the welcome screen.
    *   When the user taps "Get Started", they are taken to the **`AuthScreen`** (`auth_screen.dart`) to either log in or register a new account.
*   **Logged In User:**
    *   The app bypasses the landing screen entirely and proceeds to Role-Based Routing.

---

## 2. Role-Based Routing (Admin vs. Client)
Once a user is authenticated, the app checks their role (stored in Firestore) to determine which main screen to show them.

*   **If the user is an Admin (`role == 'admin'`):**
    *   They are taken to the **`HomeScreen`** (`home_screen.dart`). This serves as the Admin Dashboard where they can manage inventory, view all incoming orders, and approve or dispatch gear.
*   **If the user is a Client (`role == 'client'`):**
    *   They are taken to the **`ClientStorefrontScreen`** (`client_storefront_screen.dart`). This is the premium UI where they can browse available equipment.

---

## 3. The Client Flow: Booking Equipment
When a client logs in, they experience an e-commerce-style booking flow:

1.  **Browsing (Storefront):**
    *   On the **`ClientStorefrontScreen`**, the user views categories and equipment.
    *   They select the items they need and add them to their cart.
2.  **Reviewing (Cart):**
    *   They navigate to the **`CartScreen`** (`cart_screen.dart`).
    *   Here, they select the specific dates (start and end times) for their event. The app calculates the total price and checks initial availability.
3.  **Checkout (Payment):**
    *   They proceed to the **`PaymentScreen`** (`payment_screen.dart`).
    *   They enter delivery details (address/maps link) and payment info. Once submitted, the backend creates a `Booking` document in Firestore with a status of `paid` (or `pending`).
4.  **Tracking (Order History):**
    *   After checkout, they can track their booking on the **`OrderHistoryScreen`** (`order_history_screen.dart`) to see if it has been approved or dispatched by an admin.

---

## 4. The Admin Flow: Order Fulfillment
When an admin logs in, their job is to process the incoming requests from clients:

1.  **Dashboard:**
    *   On the **`HomeScreen`**, the admin sees a list of all bookings.
2.  **Approval (Conflict Resolution):**
    *   The admin reviews a `paid` booking.
    *   When they hit "Approve", the `approveBooking()` backend transaction runs (as explained in the backend guide) to ensure the gear isn't double-booked. If successful, the status changes to `approved`.
3.  **Dispatch & Completion:**
    *   When the gear leaves the warehouse, the admin marks it as `dispatched`.
    *   When the gear is returned safely, they mark the order as `completed`.

---

## 5. Secondary Settings Flows
Both admins and clients have access to secondary screens via menus or profile tabs:

*   **`ProfileSettingsScreen`**: For updating their display name or logging out.
*   **`HelpSupportScreen`**: For contacting the Gear Grid team or reading FAQs.
