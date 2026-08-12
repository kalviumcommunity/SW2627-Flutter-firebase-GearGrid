# DATA_MODEL — Firestore Schema
## Equipment Rental Booking & Dispatch App

> Companion to `PROJECT_CONTEXT.md` (scope), `FOLDER_STRUCTURE.md` (repo layout), `TRD.md` (technology).
> This file answers: **what does the data actually look like in Firestore, collection by collection, field by field, and why.**
> Every collection here lives under `shared/types/` as the TypeScript source of truth (see `FOLDER_STRUCTURE.md` §3) — this document is the human-readable explanation of those types, not a separate source of truth.

---

## 1. Modeling Approach (read this before any collection below)

**Quantity pools, not serialized units.** Per `PROJECT_CONTEXT.md` §2, equipment is tracked as a count (`totalQuantity`), not as individually identifiable items. Nothing in this schema has a "unit ID" for a specific speaker — availability math is always *counting against a pool*, never *checking out item #7*.

**The core hard problem, and how the schema is shaped around it.** The entire point of this app is: *"is there enough equipment left in the pool for these dates, checked atomically."* Firestore cannot do a SQL-style `JOIN` between a `bookings` collection and an `equipment` collection efficiently at write time. So the schema is deliberately **denormalized** in one specific place — booking line items carry a **copy of the date range** on each line item itself — so that a single **collection group query** across every booking's line items, filtered by `equipmentId` + date-overlap + status, is enough to compute demand for one piece of equipment without fetching parent booking documents first. This is the one denormalization the whole conflict-detection engine depends on; it's explained in detail in §3.2.

**Reserved fields.** Per `PROJECT_CONTEXT.md` §5, several fields exist from day one even though the feature that uses them (pricing, multi-warehouse, etc.) isn't built yet — so Layer 3/4 doesn't require a schema migration. These are marked **`[reserved]`** below. They exist in the schema, default to `null`/`0`, and are simply unused by Layer 1 code.

**Status is a finite state machine, not a free string.** `BookingStatus` is a fixed enum, not open text — enforced both in `shared/types/booking.ts` and again in Firestore Security Rules (a document can't be written with a status outside the enum, and — see §7 — can't jump illegal transitions like `Requested → Dispatched`).

---

## 2. Collection Overview

```
/users/{userId}
/equipment/{equipmentId}
/bookings/{bookingId}
    /items/{itemId}                 (subcollection)
/auditLogs/{logId}
/notifications/{notificationId}
/waitlist/{waitlistId}
/damageReports/{reportId}
/quotes/{quoteId}                   [reserved — Layer 3]
/payments/{paymentId}               [reserved — Layer 3]
/reviews/{reviewId}                 [reserved — Layer 3]
/warehouses/{warehouseId}           [reserved — Layer 4/5]
```

---

## 3. Layer 1 — Core Collections (mandatory, built first)

### 3.1 `users/{userId}`

Document ID = Firebase Auth `uid`, so no separate lookup is ever needed between an authenticated user and their profile.

| Field | Type | Notes |
|---|---|---|
| `role` | string enum | `"admin" \| "staff" \| "warehouse" \| "client"` — mirrored into the Auth custom claim; this field is the human-readable copy for querying/display, the claim is the enforced copy |
| `name` | string | |
| `email` | string | |
| `phone` | string \| null | |
| `isActive` | boolean | soft-disable instead of deleting a user, preserves history on their past bookings |
| `createdAt` | timestamp | |
| `updatedAt` | timestamp | |
| `companyName` | string \| null | client-only field; null for staff roles |

**Why role is stored twice (here *and* as a custom claim):** the claim is what Security Rules and Cloud Functions trust for access control. This document's `role` field is for the UI (e.g. showing an admin a list of "all warehouse staff") — never trusted for a permission decision. See §7.

---

### 3.2 `equipment/{equipmentId}`

| Field | Type | Notes |
|---|---|---|
| `name` | string | e.g. `"JBL PA Speaker"` |
| `category` | string enum | `"sound" \| "lighting" \| "furniture"` |
| `totalQuantity` | number | the size of the pool — the number this whole app protects |
| `damagedQuantity` | number | current units out of service (reduces effective availability without changing `totalQuantity`, per Layer 2 damage handling) |
| `bufferHours` | number | `[Layer 2]` turnaround/inspection time required between one booking's return and the next booking's dispatch for this item; `0` until Layer 2 buffer logic is built, but the field exists now so `checkAvailability` can be written once to always read it |
| `tags` | array\<string\> | e.g. `["portable", "battery-powered"]` |
| `imageUrl` | string \| null | Cloud Storage URL |
| `isActive` | boolean | soft-delete — a discontinued item disappears from catalog browsing but stays on historical bookings |
| `pricePerDay` | number \| null | `[reserved — Layer 3]` |
| `warehouseId` | string \| null | `[reserved — Layer 4]` — which location owns this pool, once multi-warehouse is decided |
| `createdAt` / `updatedAt` | timestamp | |

**Effective available quantity is never stored on this document** — it's always computed at query time as `totalQuantity - damagedQuantity - (sum of quantities committed for the requested date range)`. Storing a running "available now" counter would itself be a race-condition risk (two transactions decrementing the same counter is exactly the bug this app exists to prevent) — so it's always derived, never cached as truth.

---

### 3.3 `bookings/{bookingId}`

The parent document holds everything that is *about the booking as a whole*, not about a specific piece of equipment in it.

| Field | Type | Notes |
|---|---|---|
| `status` | string enum | `"Requested" \| "Confirmed" \| "Dispatched" \| "Returned" \| "Completed" \| "Cancelled"` — the lifecycle from `PROJECT_CONTEXT.md` §3 |
| `clientId` | string | reference to `users/{userId}` |
| `createdBy` | string | `uid` of whoever entered the booking — staff (phone-in order) or the client themselves (self-service request) |
| `eventType` | string \| null | e.g. `"wedding"`, `"corporate"` — free text for now, used by AI quote/recommendation features later |
| `guestCount` | number \| null | |
| `startDate` / `endDate` | timestamp | the rental window — this is the range every conflict check runs against |
| `deliveryAddress` | string \| null | `[Layer 2]` |
| `deliveryDate` / `deliveryTime` | timestamp / string \| null | `[Layer 2]` |
| `pickupDate` / `pickupTime` | timestamp / string \| null | `[Layer 2]` |
| `assignedDriverId` | string \| null | `[Layer 2]` |
| `totalPrice` | number \| null | `[reserved — Layer 3]` — exists from day one per `PROJECT_CONTEXT.md` §5 so no migration is needed when pricing ships |
| `depositAmount` / `depositPaid` | number / boolean \| null | `[reserved — Layer 3]` |
| `approvedBy` | string \| null | `uid` of staff/admin who moved `Requested → Confirmed` |
| `approvedAt` | timestamp \| null | |
| `cancelledReason` | string \| null | |
| `notes` | string \| null | |
| `createdAt` / `updatedAt` | timestamp | |

**Why `startDate`/`endDate` live on the booking and not only on line items:** the whole booking shares one rental window in the common case (an event has one date range), but see §3.4 for why the window is *also* copied onto each line item — that duplication is intentional, not an oversight.

---

### 3.4 `bookings/{bookingId}/items/{itemId}` (subcollection)

One document per equipment line in the booking — e.g. a wedding booking might have three items: speakers, uplighting, chairs.

| Field | Type | Notes |
|---|---|---|
| `equipmentId` | string | reference to `equipment/{equipmentId}` |
| `equipmentName` | string | **denormalized copy** of `equipment.name` at booking time — so a dispatch pull-list or historical booking still shows the right name even if the catalog entry is later renamed |
| `category` | string enum | denormalized copy of `equipment.category`, for filtering the pull-list by category without a second read |
| `quantityRequested` | number | what was asked for |
| `quantityConfirmed` | number \| null | what staff actually approved (may differ from requested if a substitute/partial fill was offered) |
| `startDate` / `endDate` | timestamp | **denormalized copy of the parent booking's dates.** This is the field that makes collection-group conflict queries possible — see below |
| `status` | string enum | denormalized copy of the parent booking's status, kept in sync by `functions/src/triggers/onBookingStatusChange.ts`; needed so the collection-group query can filter to only `Confirmed`/`Dispatched` items without a second lookup per item |
| `pricePerUnit` | number \| null | `[reserved — Layer 3]` |

**Why dates and status are duplicated here instead of only living on the parent `bookings` document:**
Firestore **collection group queries** can search across every `items` subcollection in the database at once (e.g. "every line item for `equipmentId = X` where `status` is `Confirmed` or `Dispatched` and the date range overlaps March 14–15"), but a collection group query can only filter on fields *that exist on the document being queried* — it cannot reach up into the parent `bookings` document to check its date or status. Copying `startDate`, `endDate`, and `status` onto every item is what makes `checkAvailability` a single, fast, indexed query instead of "fetch every booking, then fetch its parent, then filter in application code" — which would not only be slow but would defeat the purpose of doing the check inside an atomic transaction.

This duplication is kept correct by the Cloud Function layer (never by the client) — every place that changes a booking's status or dates writes to both the parent and, in the same transaction, every item subcollection document.

---

### 3.5 `auditLogs/{logId}`

Append-only. Written automatically by `functions/src/triggers/onBookingStatusChange.ts` and similar triggers — never written directly by a feature screen, so it can't be forgotten (per `FOLDER_STRUCTURE.md` §3).

| Field | Type | Notes |
|---|---|---|
| `entityType` | string enum | `"booking" \| "equipment" \| "user"` |
| `entityId` | string | which document changed |
| `action` | string | e.g. `"status_changed"`, `"created"`, `"approved"`, `"cancelled"` |
| `performedBy` | string | `uid` |
| `performedAt` | timestamp | |
| `previousValue` | map \| null | e.g. `{ status: "Requested" }` |
| `newValue` | map \| null | e.g. `{ status: "Confirmed" }` |
| `notes` | string \| null | |

Audit logs are never edited or deleted (Security Rules deny `update`/`delete` on this collection entirely — see §7).

---

### 3.6 `notifications/{notificationId}`

| Field | Type | Notes |
|---|---|---|
| `userId` | string | recipient |
| `type` | string enum | `"booking_confirmed" \| "dispatch_reminder" \| "loadout_today" \| "return_reminder" \| ...` |
| `title` / `body` | string | |
| `relatedBookingId` | string \| null | |
| `read` | boolean | |
| `channel` | string enum | `"push" \| "sms" \| "email"` — `[Layer 2]`, defaults to `"push"` until SMS/email providers are integrated (see `TRD.md` §7) |
| `createdAt` | timestamp | |

---

## 4. Layer 2 Collections (operational — schema exists now, features built next)

### 4.1 `waitlist/{waitlistId}`

| Field | Type | Notes |
|---|---|---|
| `equipmentId` | string | |
| `requestedQuantity` | number | |
| `startDate` / `endDate` | timestamp | |
| `clientId` | string | |
| `relatedBookingId` | string \| null | if created from a booking attempt that couldn't be fully filled |
| `status` | string enum | `"waiting" \| "fulfilled" \| "expired" \| "cancelled"` |
| `createdAt` | timestamp | |

Used by the overbooking/waitlist handling feature — when `checkAvailability` finds insufficient pool quantity, the client is offered a waitlist entry (or an AI-suggested substitute, Tier 1) instead of a hard rejection.

### 4.2 `damageReports/{reportId}`

| Field | Type | Notes |
|---|---|---|
| `bookingId` | string | which booking the item returned from |
| `equipmentId` | string | |
| `quantityDamaged` | number | decremented from `equipment.damagedQuantity` via a Cloud Function, never directly from the client |
| `description` | string | |
| `photoUrl` | string \| null | Cloud Storage — feeds AI Tier 3 damage assessment |
| `aiDraftDescription` | string \| null | `[reserved]` — AI-drafted damage description before warehouse staff confirms it |
| `reportedBy` | string | `uid`, warehouse role |
| `reportedAt` | timestamp | |
| `repairStatus` | string enum | `"pending" \| "in_repair" \| "returned_to_pool"` |

---

## 5. Layer 3 Collections `[reserved — schema only, not built yet]`

### 5.1 `quotes/{quoteId}`
`bookingId`, `lineItems` (array of `{equipmentId, quantity, unitPrice, subtotal}`), `deliveryFee`, `tax`, `total`, `generatedBy` (`"staff" | "ai"`), `status` (`"draft" | "sent" | "accepted"`), `createdAt`.

### 5.2 `payments/{paymentId}`
`bookingId`, `amount`, `type` (`"deposit" | "final"`), `status` (`"pending" | "paid" | "refunded"`), `method`, `externalTransactionId` (from whichever payment provider is eventually chosen, per `TRD.md` §7), `paidAt`.

### 5.3 `reviews/{reviewId}`
`bookingId`, `clientId`, `rating` (1–5), `comment`, `createdAt`.

These three collections are documented here so their shape is agreed in advance, but **no Security Rules, indexes, or Cloud Functions exist for them yet** — do not build against them until Layer 3 is scoped for active work, per `PROJECT_CONTEXT.md` §3.

---

## 6. Layer 4/5 Collections `[reserved — vision-level]`

### 6.1 `warehouses/{warehouseId}`
`name`, `address`, `isActive`. Referenced by `equipment.warehouseId` and `bookings.assignedDriverId`'s home warehouse, once multi-warehouse support is confirmed (open question in `PROJECT_CONTEXT.md` §6).

No other Layer 4/5 collections are pre-defined — analytics (utilization, revenue, forecasting) are computed via aggregation queries over existing collections, not new source-of-truth collections, until a specific rollup is confirmed to need pre-computation for performance.

---

## 7. Security Rules Shape (summary — full rules live in `firestore.rules`)

Rules read the Auth custom claim (`request.auth.token.role`), never the `users/{uid}.role` field, for any access decision — the document field is for UI display only.

| Collection | Read | Write |
|---|---|---|
| `equipment` | any authenticated user | `admin`, `staff` only |
| `bookings` (own) | `client` can read their own; staff/admin/warehouse can read all | `client` can `create` only (status forced to `Requested` server-side); `staff`/`admin` can update status forward through the state machine; no role can skip a status (e.g. `Requested → Dispatched` directly is denied) |
| `bookings/{id}/items` | same as parent booking | writable only by Cloud Functions (via Admin SDK, which bypasses rules) — never directly by any client role, since this is where the denormalized date/status copies live and must stay in sync |
| `auditLogs` | `admin`, `staff` | **no client write, ever** — only Cloud Functions triggers write here; `update`/`delete` denied entirely |
| `users` | self, or `admin` | self (limited fields: name/phone), `admin` only for `role` |
| `waitlist`, `damageReports`, `notifications` | relevant role/owner | staff/warehouse roles per collection |

---

## 8. Required Composite Indexes (`firestore.indexes.json`)

| Collection group | Fields | Purpose |
|---|---|---|
| `items` (collection group) | `equipmentId` ASC, `status` ASC, `startDate` ASC | the availability/conflict-check query — this is the index the entire core feature depends on |
| `items` (collection group) | `equipmentId` ASC, `status` ASC, `endDate` ASC | supports the other side of the date-overlap check |
| `bookings` | `clientId` ASC, `status` ASC, `createdAt` DESC | client's own booking history view |
| `bookings` | `status` ASC, `startDate` ASC | dispatch pull-list generation (upcoming confirmed bookings) |
| `damageReports` | `equipmentId` ASC, `reportedAt` DESC | equipment damage history lookup |

---

## 9. Open Items (do not assume answers — per `PROJECT_CONTEXT.md` §6)

- Whether `bookings.status = "Requested"` items count toward the availability check (soft-hold) or only `"Confirmed"` items do (hard commitment only) — this changes what statuses the §8 index query filters on. **Not yet decided; flag before writing `checkAvailability.ts`.**
- Multi-warehouse: `equipment.warehouseId` and `warehouses/` collection exist in the schema but are inert until this is confirmed.
- Pricing model (flat/per-day/distance-tiered) affects whether `pricePerUnit` on line items is enough, or whether a separate pricing-rules collection is needed later.

---

*Keep this file in sync with `shared/types/*.ts`. If a field is added, renamed, or removed, update this document in the same PR.*
