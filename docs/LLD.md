GearGrid Low-Level Design (LLD)

1. Module Structure

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

2. Model Design

2.1 AppRole

enum AppRole {
  client,
  admin
}

Storage values:

client
admin

The model also provides user-facing labels and role-specific titles/subtitles.

2.2 AppUser

Fields:

Field

Type

Description

id

String

Firebase Auth UID

email

String

User email

displayName

String

Client/admin display name

role

AppRole

Application role

2.3 Equipment

Fields:

Field

Type

Description

id

String

Firestore document ID

name

String

Equipment name

category

String

Sound, Lighting, Furniture, etc.

description

String

Product description

powerProfile

String

Power/rig information

totalUnits

int

Physical available inventory

accent

Color

UI accent

pricePerUnit

double

Rental price per unit

imageUrl

String?

Firebase Storage/download URL

2.4 Booking

Fields:

Field

Type

Description

id

String

Booking ID

clientId

String

Firebase UID

clientName

String

Display name

eventName

String

Event title

venue

String

Delivery/event venue

start

DateTime

Event start

end

DateTime

Event end

status

BookingStatus

Lifecycle state

requestedUnits

Map<String,int>

Equipment ID → quantity

subtotal

double

Equipment subtotal

platformFee

double

Platform fee

taxAmount

double

Tax

totalAmount

double

Final amount

paymentId

String?

Payment reference

paymentMethod

String?

UPI/Card/Wallet

mapsLink

String?

Venue map link

driverName

String?

Dispatch driver

vehicleDetails

String?

Dispatch vehicle

deliveryEta

DateTime?

Expected delivery

3. Repository Design

FirestoreRepository is the data-access layer.

Methods

watchUser(userId)
ensureUserProfile(user)
watchEquipment()
watchBookings(user)
watchReservedUnits(start, end)
createBooking(booking)
approveBooking(bookingId)
updateBookingStatus(bookingId, status)
updateBooking(booking)
saveEquipment(equipment)
deleteEquipment(equipmentId)
updateEquipmentUnits(equipmentId, totalUnits)
fetchBookingHistory(limit, startAfter)

The repository hides Firestore implementation details from most UI screens.

4. Authentication Flow

Startup

main()
  ↓
GearGridApp
  ↓
Firebase.initializeApp()
  ↓
AuthGate
  ↓
FirebaseAuth.authStateChanges()

Unauthenticated

LandingScreen
    ↓
AuthScreen
    ↓
FirebaseAuth

Authenticated

Firebase User
    ↓
ensureUserProfile()
    ↓
watchUser(uid)
    ↓
role?
  ├── admin  → HomeScreen
  └── client → ClientStorefrontScreen

5. Client Availability Algorithm

For each equipment item:

available(equipment):
    reserved = reservedUnits[equipment.id] or 0
    return clamp(equipment.totalUnits - reserved, 0, equipment.totalUnits)

The storefront then limits the cart quantity to the calculated availability.

6. Reservation Slot Generation

The repository generates hourly slots using the booking start/end.

slots(start, end):
    current = floorToHour(start)

    while current < end:
        yield current
        current = current + 1 hour

Slot document ID:

{equipmentId}_{slotStartMilliseconds}

Example:

moving_heads_1789387200000

7. Approval Algorithm

This is the most important algorithm in the system.

approveBooking(bookingId):

    begin Firestore transaction

    booking = transaction.get(bookings/bookingId)

    if booking does not exist:
        fail

    if booking.status is not paid/pending:
        fail

    for each equipmentId in booking.requestedUnits:
        equipment = transaction.get(equipment/equipmentId)

        if equipment does not exist:
            fail

    for each equipmentId:
        for each hourly slot in booking.start..booking.end:
            slot = transaction.get(reservationSlots/slotId)

    for each requested equipment:
        for each affected slot:
            reserved = slot.reservedUnits or 0

            if reserved + requestedUnits > equipment.totalUnits:
                fail with conflict

    for each requested equipment:
        for each affected slot:
            write reservedUnits + requestedUnits

    update booking:
        status = approved
        approvedAt = server timestamp
        updatedAt = server timestamp

    commit transaction

Why transaction is required

Without a transaction:

Admin A reads 6 reserved
Admin B reads 6 reserved

Inventory = 10
Both request 4

A sees 6 + 4 <= 10
B sees 6 + 4 <= 10

Both approve
Actual = 14

With Firestore transaction conflict detection, one transaction must retry against the latest data and can then fail the capacity check.

8. Booking Creation

The checkout creates a booking containing:

status = pending
clientId = authenticated user UID
requestedUnits = cart quantities
event data
financial data
payment metadata

The current payment flow waits approximately two seconds to simulate payment processing before creating the booking.

9. Pricing Logic

The cart calculates:

subtotal = Σ(pricePerUnit × quantity)

GST/tax = (subtotal + platformFee) × taxRate

total = subtotal + platformFee + GST/tax

The exact tax rate is maintained by the checkout implementation.

10. Dispatch State Machine

                +-----------+
                | paid      |
                +-----+-----+
                      |
                      v
                +-----------+
                | pending   |
                +-----+-----+
                      |
                      v
                +-----------+
                | approved  |
                +-----+-----+
                      |
                      v
                +-----------+
                |dispatched |
                +-----+-----+
                      |
                      v
                +-----------+
                | completed |
                +-----------+

pending/paid
    |
    v
rejected

The current admin UI supports:

approved → dispatched
dispatched → completed

and rejection from the incoming-booking workflow.

11. Firestore Security Rules

User document

Client may access its own profile.

Admin may read user profiles.

Role updates are constrained so a normal client cannot change itself into an admin.

Equipment

read  → authenticated users
write → admins

Bookings

read:
    admin OR booking.clientId == authenticated UID

create:
    authenticated AND
    booking.clientId == authenticated UID AND
    status is pending or paid

update/delete:
    admin only

Reservation Slots

read  → authenticated users
write → admins

12. Data Validation Rules

Equipment

name must not be empty;

category must not be empty;

description must not be empty;

power profile must not be empty;

total units must be at least 1;

price must be numeric.

Booking

client must be authenticated;

client ID must equal authenticated UID at creation;

event name required;

venue required;

cart must contain equipment;

event start/end must define a valid window.

Payment

UPI requires a selected app or UPI ID;

card requires at least a 16-digit card number;

card expiry must be provided;

CVV must be provided.

These client-side validations are usability checks, not a substitute for backend validation.

13. Realtime Listeners

Client

watchEquipment()
watchReservedUnits(start, end)

Admin

watchEquipment()
watchBookings(user: admin)

A listener error is surfaced to the UI as a connection/reconnect message.

14. Image Upload Flow

Admin equipment editor:

Image Picker
    ↓
Read image bytes
    ↓
Firebase Storage
    ↓
equipment_images/{generated filename}
    ↓
getDownloadURL()
    ↓
Equipment.imageUrl
    ↓
Firestore equipment document

15. Error Handling

The repository defines:

class BookingConflictException implements Exception

It is used to distinguish inventory conflicts from generic database errors.

UI behavior:

BookingConflictException
    → clear conflict message

Firebase/other exception
    → generic operation failure message

Authentication maps Firebase error codes to user-friendly messages.

16. Concurrency and Consistency

The reservation-slot write is the consistency boundary for inventory approval.

Important invariant:

For every equipment + hourly slot:

reservedUnits <= equipment.totalUnits

The invariant is checked inside the approval transaction.

17. Recommended LLD Improvements for Production

Server-side admin provisioning

Replace the email-based admin assignment with:

Firebase custom claims, or

a trusted Cloud Function/admin service.

Server-side payment verification

The client should never be the authority for payment success.

Recommended flow:

Client
  ↓
Payment provider
  ↓
Webhook/backend verification
  ↓
Verified payment
  ↓
Booking status

Temporary reservation holds

For high-demand periods:

cart
  ↓
temporary hold
  ↓
payment
  ↓
confirmed reservation

Expired holds should automatically release capacity.

Stronger inventory editing

Prevent admins from reducing totalUnits below already committed quantities unless a controlled conflict-resolution workflow is used.

18. Test Scenarios

Unit Tests

booking overlap calculation;

availability calculation;

quantity boundaries;

status transitions;

pricing calculations.

Integration Tests

create booking;

approve valid booking;

reject conflicting booking;

update reservation slots;

dispatch booking;

complete booking.

Security Tests

anonymous read/write rejection;

client reading another client's booking;

client modifying a booking;

client writing equipment;

client writing reservation slots;

client escalating role.

Concurrency Test

Create two bookings for the same equipment and overlapping window where combined quantity exceeds inventory.

Expected:

at most one capacity-exceeding approval succeeds

depending on requested quantities and existing reservations.

19. Observability Recommendations

Production deployment should record:

booking approval attempts;

conflict failures;

inventory changes;

dispatch changes;

authentication failures;

payment verification failures.

Each audit record should include timestamp, actor UID, operation, target ID, and outcome.