# Low-Level Design (LLD)
## Equipment Rental Booking & Dispatch App — Layer 1 (Mandatory Core)

| | |
|---|---|
| **Status** | Draft — implementation-ready for Layer 1 |
| **Scope** | Layer 1 (Mandatory Core) in full detail. Layer 2+ noted only where Layer 1 must be designed to absorb them without rework. |
| **Source docs** | `PRD.md` (what/why), `PROJECT_CONTEXT.md` (source of truth for scope) |
| **Stack assumed** | Flutter (Dart) client, Cloud Functions on Node.js/TypeScript, Cloud Firestore, Firebase Auth custom claims |

> This LLD is the *how* — concrete schemas, function signatures, rules, and algorithms an engineer can build directly from. If anything here conflicts with `PROJECT_CONTEXT.md`, that file wins; update it first, then this doc.

---

## 1. Purpose & Scope

This document translates the Layer 1 requirements in the PRD into buildable detail:

- Exact Firestore collection/document shapes, including fields not fully specified in the PRD's high-level data model.
- The conflict-detection algorithm, expressed as a concrete transaction, including the Firestore query limitations that shape it.
- Every Cloud Function Layer 1 needs, with inputs, outputs, and error contracts.
- Security Rules that enforce the PRD's "server-side only" access control rule.
- Flutter app structure mapped to roles and screens.

Everything here is scoped to **Layer 1**. Where a decision has to anticipate Layer 2/3 (per PRD §3: *"architecture that can grow ... without requiring rework"*), that's called out explicitly rather than built now.

---

## 2. System Architecture

```
                     ┌─────────────────────────────┐
                     │        Flutter Client        │
                     │  (Admin / Staff / Warehouse)  │
                     └───────────────┬───────────────┘
                                     │
                 ┌───────────────────┼───────────────────┐
                 │                   │                   │
                 ▼                   ▼                   ▼
       ┌─────────────────┐  ┌───────────────┐  ┌──────────────────┐
       │ Firebase Auth    │  │ Cloud         │  │ Firestore         │
       │ (custom claims:  │  │ Functions      │  │ (direct reads +   │
       │  role = admin /  │  │ (writes that   │  │  real-time        │
       │  staff /         │  │  touch         │  │  listeners)       │
       │  warehouse)      │  │  conflict-     │  │                   │
       └─────────────────┘  │  sensitive     │  └────────┬──────────┘
                             │  state)        │           │
                             └───────┬────────┘           │
                                     │                     │
                                     ▼                     ▼
                          ┌─────────────────────────────────┐
                          │      Cloud Firestore              │
                          │  equipment / bookings / users     │
                          └─────────────────────────────────┘
```

**Read path:** Flutter listens directly to Firestore (real-time snapshots) — this is what makes "everyone sees the same live data" free, per PRD §6.

**Write path, split in two:**
- **Non-sensitive writes** (e.g., staff editing a draft's notes field before confirming) → direct client write, gated by Security Rules.
- **Conflict-sensitive writes** (anything that changes booking `status` to `Confirmed`, or touches quantity accounting) → **always** through a Cloud Function, per PRD §6's non-negotiable rule. The client never has Firestore write permission for these fields — enforced in Security Rules (§8), not just app logic.

---

## 3. Firestore Data Model

### 3.1 `equipment/{equipmentId}`

```jsonc
{
  "name": "JBL EON615 Speaker",
  "category": "sound",            // "sound" | "lighting" | "furniture"
  "totalQuantity": 10,
  "damagedQuantity": 0,           // Layer 2 writes to this; present now to avoid migration
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

`availableQuantity` is **not stored** — it's derived (`totalQuantity - damagedQuantity`) and further reduced by querying overlapping bookings at check time (§6). Storing a live counter would drift under concurrent writes; deriving it is what makes the "structurally impossible to double-book" guarantee actually hold.

### 3.2 `bookings/{bookingId}`

```jsonc
{
  "clientName": "Priya & Arjun Wedding",
  "contactPhone": "+91XXXXXXXXXX",
  "eventType": "wedding",
  "location": "Leela Ambience, Gurugram",

  "startDateTime": Timestamp,     // full date+time, not just date — needed for overlap math
  "endDateTime": Timestamp,

  "equipmentIds": ["eq_speaker_01", "eq_light_02"],   // flat array — see 3.3
  "equipmentRequested": [
    { "equipmentId": "eq_speaker_01", "name": "JBL EON615 Speaker", "quantity": 4 },
    { "equipmentId": "eq_light_02",  "name": "Par Can LED",         "quantity": 8 }
  ],

  "status": "Requested",          // Requested | Confirmed | Dispatched | Returned | Completed | Cancelled
  "price": null,                  // present from day one per PRD §10; null until Layer 3 pricing exists

  "createdBy": "uid_staff_01",
  "createdByRole": "staff",
  "createdAt": Timestamp,
  "confirmedBy": null,
  "confirmedAt": null,

  "history": [
    {
      "action": "created",
      "byUserId": "uid_staff_01",
      "byRole": "staff",
      "timestamp": Timestamp,
      "note": "Phone booking taken by Jatin"
    }
  ]
}
```

### 3.3 Why both `equipmentIds` and `equipmentRequested` exist

This is a deliberate denormalization, not redundancy. Firestore can't run a query against values nested inside an array-of-maps field (e.g., "find bookings where `equipmentRequested` contains an item with `equipmentId == X`"). It **can** run `array-contains-any` against a flat array of scalars. So:

- `equipmentIds` (flat array of strings) exists **purely so the conflict-check query in §6 can find candidate bookings.**
- `equipmentRequested` (array of maps with quantity) is the actual data the UI and dispatch view render.

Any write path that creates/updates a booking must keep these two in sync. This belongs in one shared helper (client-side draft building, and again inside the Cloud Function before commit) — never trust the client's `equipmentIds` value for the actual conflict math; the Cloud Function derives it from `equipmentRequested` at write time.

### 3.4 `users/{uid}` — addition beyond the PRD's high-level model, flagged

The PRD is explicit that **roles** are not a Firestore collection (they live in custom claims — see §8). That's still true here. But the audit trail requirement (PRD §3: *"who booked what, when, who approved it"*) needs a human-readable name to display next to a `uid` in the booking history and dispatch view. Proposal:

```jsonc
// users/{uid}  — profile lookup only, NEVER the source of truth for access control
{
  "displayName": "Jatin Yadav",
  "email": "jatin@...",
  "roleDisplay": "staff",   // mirror of the custom claim, for UI display only — do not check this for auth
  "createdAt": Timestamp
}
```

Written once by a Cloud Function trigger (`onUserCreate`) when an admin provisions a new user. **This needs sign-off before Layer 1 is considered locked** — it's an LLD-level addition to make the audit trail readable, not a PRD scope change. If it's rejected, the alternative is resolving `uid → name` client-side via a small cached lookup, which is worse for the dispatch view's offline story (Layer 2) later.

---

## 4. Booking Lifecycle & State Machine

```
Requested ──confirm──▶ Confirmed ──dispatch──▶ Dispatched ──return──▶ Returned ──complete──▶ Completed
    │                       │
    └──────────cancel───────┴──────────────▶ Cancelled
```

| Transition | Who | Cloud Function | Notes |
|---|---|---|---|
| `Requested → Confirmed` | staff, admin | `confirmBooking` | **The only transition that runs the conflict-check transaction (§6).** This is the moment inventory is actually committed. |
| `Requested → Cancelled` | staff, admin, (client, own booking, Layer 3) | `cancelBooking` | No conflict check needed — nothing was ever committed. |
| `Confirmed → Cancelled` | staff, admin | `cancelBooking` | Releases the hold. Because availability is computed by querying `Confirmed`/`Dispatched` bookings (§6), cancelling just removes this booking from that query set — no counter to reconcile. |
| `Confirmed → Dispatched` | warehouse, staff | `dispatchBooking` | Marks equipment as physically out. Sets `dispatchedAt`, `dispatchedBy`. |
| `Dispatched → Returned` | warehouse | `returnBooking` | Sets `returnedAt`, `returnedBy`. Layer 2 attaches damage/shortage data here — schema leaves room (see §16). |
| `Returned → Completed` | staff, admin, or automatic | `completeBooking` | Closes the booking. Can be automated later (e.g., N hours after return) without touching this state machine. |

Every transition appends one entry to `history[]` (§11) inside the same Cloud Function call — never a separate write, so the audit trail can't desync from the status change.

---

## 5. Core Design Decision: Availability-by-Query, Not Counter Decrement

Two ways to track "how much of equipment X is free right now":

| Approach | How it works | Risk |
|---|---|---|
| **Counter decrement** (rejected) | Confirming a booking decrements `equipment.availableQuantity`; cancelling increments it back. | Any missed/duplicate write (retried Cloud Function, crashed client mid-write, forgotten edge case in a future feature) permanently desyncs the counter from reality. This is exactly the class of bug the PRD's "structurally impossible" goal is meant to rule out. |
| **Availability-by-query** (chosen) | There is no stored "available now" number. Availability for a given date range is computed on demand by querying `Confirmed`/`Dispatched` bookings that overlap that range and summing requested quantities. | Slightly more read cost per check; bounded by realistic booking volume for a regional rental company, not a concern at this scale. |

This is why `equipment.totalQuantity` and `damagedQuantity` are the only stored quantity fields — everything else is derived at check time, inside a transaction, from the actual booking documents. There is nothing to drift.

---

## 6. Conflict Detection Algorithm

This is the mechanism behind PRD §7's "must use Firestore transactions, never check-then-write."

### 6.1 Firestore query constraint that shapes the design

Firestore transactions support reads (including queries) followed by writes, but a query inside a transaction can only apply **one inequality/range filter**, on one field. Overlap detection needs two range comparisons (`existing.start < new.end` **and** `existing.end > new.start`). So the query does the cheap half in Firestore, and the code does the rest in memory:

```
Firestore query (inside transaction):
  bookings
    .where("equipmentIds", "array-contains-any", <requested equipment ids, max 10>)
    .where("status", "in", ["Confirmed", "Dispatched"])
    .where("startDateTime", "<", newBooking.endDateTime)

In-memory filter on the result set:
  keep only docs where doc.endDateTime > newBooking.startDateTime
```

> `array-contains-any` is capped at 10 values by Firestore. A booking requesting more than 10 distinct equipment types needs the check batched — flagged as an edge case in §12, not expected at typical event sizes.

### 6.2 Full transaction, step by step (`confirmBooking`)

```
function confirmBooking(bookingId, staffUid):
  runTransaction(tx =>
    booking = tx.get(bookings/bookingId)
    assert booking.status == "Requested"

    equipmentDocs = tx.get(equipment docs for booking.equipmentIds)
    // availableQuantity[eq] = equipmentDocs[eq].totalQuantity - equipmentDocs[eq].damagedQuantity

    overlapping = tx.get(query from §6.1)
    overlapping = overlapping.filter(b => b.endDateTime > booking.startDateTime)

    committedQuantity = {}   // per equipmentId, sum across `overlapping`
    for each b in overlapping:
      for each item in b.equipmentRequested:
        committedQuantity[item.equipmentId] += item.quantity

    conflicts = []
    for each item in booking.equipmentRequested:
      remaining = availableQuantity[item.equipmentId] - committedQuantity[item.equipmentId]
      if remaining < item.quantity:
        conflicts.push({ equipmentId: item.equipmentId, requested: item.quantity, available: remaining })

    if conflicts.length > 0:
      throw HttpsError("failed-precondition", "conflict", { conflicts })
      // client/staff UI surfaces this as the conflict message from PRD's
      // "Show Conflict Message" flow — and is the structured payload the
      // Tier 1 AI conflict-resolution assistant will consume later (PRD §9)

    tx.update(bookings/bookingId, {
      status: "Confirmed",
      confirmedBy: staffUid,
      confirmedAt: serverTimestamp(),
      history: arrayUnion({ action: "confirmed", byUserId: staffUid, timestamp: now })
    })
  )
```

Because this all happens inside one `runTransaction`, Firestore guarantees that if two staff members try to confirm two conflicting bookings at the same instant, the second transaction re-reads fresh data and correctly sees the first one's commit — no race window. This is the literal mechanism behind PRD §7's "never a check-then-write pattern."

---

## 7. Cloud Functions (API Design)

All callable from Flutter via `httpsCallable`. Every function re-validates the caller's role from their **auth token custom claim** server-side — never trusts a role field sent in the request body.

| Function | Type | Caller role | Input | Output / errors |
|---|---|---|---|---|
| `createBookingRequest` | Callable | staff, admin (client in Layer 3) | `{clientName, contactPhone, eventType, location, startDateTime, endDateTime, equipmentRequested[]}` | `{bookingId}`. Derives `equipmentIds` server-side from `equipmentRequested`. Sets `status: "Requested"`. No conflict check here — see §5/§6. |
| `confirmBooking` | Callable | staff, admin | `{bookingId}` | `{status: "Confirmed"}` or `failed-precondition` with `conflicts[]` (§6.2) |
| `cancelBooking` | Callable | staff, admin, (owning client) | `{bookingId, reason}` | `{status: "Cancelled"}`. Rejects if already `Dispatched`/`Returned`/`Completed`. |
| `dispatchBooking` | Callable | warehouse, staff, admin | `{bookingId}` | `{status: "Dispatched", dispatchedAt}`. Rejects if not `Confirmed`. |
| `returnBooking` | Callable | warehouse | `{bookingId}` | `{status: "Returned", returnedAt}`. Rejects if not `Dispatched`. Schema leaves room for Layer 2 condition fields. |
| `completeBooking` | Callable | staff, admin | `{bookingId}` | `{status: "Completed"}` |
| `setUserRole` | Callable | admin only | `{targetUid, role}` | Sets custom claim via Admin SDK; triggers `users/{uid}` doc write |
| `onUserCreate` | Auth trigger | — | Firebase Auth `onCreate` event | Writes initial `users/{uid}` profile doc (§3.4) |

All functions throw `permission-denied` if the caller's custom claim doesn't match the required role(s), and `not-found` if `bookingId`/`equipmentId` doesn't resolve — checked before any transaction work starts.

---

## 8. Firestore Security Rules

Enforces PRD §5: *"role checks happen server-side, never only in the UI."* Rules are the server-side enforcement for **direct client access**; Cloud Functions use the Admin SDK and bypass rules entirely (that's how conflict-sensitive writes stay Cloud-Function-only even though staff *reads* the same collection directly).

```
function role() {
  return request.auth.token.role;   // custom claim: "admin" | "staff" | "warehouse" | "client"
}

match /equipment/{equipmentId} {
  allow read: if request.auth != null;
  allow write: if role() == "admin";   // e.g. marking damaged equipment repaired (PRD §5)
}

match /bookings/{bookingId} {
  allow read: if role() in ["admin", "staff", "warehouse"]
              || (role() == "client" && resource.data.createdBy == request.auth.uid);

  // Direct client writes are intentionally narrow — this is NOT where
  // status changes to Confirmed/Dispatched/etc. happen. Those are Cloud-
  // Function-only (Admin SDK bypasses these rules).
  allow create: if role() in ["admin", "staff"]
                && request.resource.data.status == "Requested";

  allow update: if role() in ["admin", "staff"]
                && resource.data.status == "Requested"
                && request.resource.data.status == "Requested"
                && request.resource.data.equipmentRequested == resource.data.equipmentRequested;
                // ^ lets staff edit e.g. contactPhone on a draft, but blocks
                //   editing equipment/quantities or status outside the
                //   Cloud Function path

  allow delete: if false;   // bookings are cancelled, never deleted — audit trail (PRD §3)
}

match /users/{uid} {
  allow read: if request.auth != null;
  allow write: if false;   // Cloud-Function/Admin-SDK only
}
```

> `createBookingRequest` above is listed as a Cloud Function, but note it *could* also be a direct client `create` under these rules since it doesn't touch conflict state. Either is fine; the LLD keeps it as a Cloud Function anyway so `equipmentIds` derivation (§3.3) has one single trusted place to happen, rather than duplicating that logic in the Flutter client.

---

## 9. Sequence Diagrams

### 9.1 Staff enters a phone booking, then confirms it

```
Staff (Flutter)      createBookingRequest (CF)      Firestore
     │                        │                          │
     ├── call w/ booking ────▶│                          │
     │                        ├── derive equipmentIds ──▶│
     │                        ├── write status=Requested ▶│
     │◀── bookingId ──────────┤                          │
     │                                                     │
     │  (later, staff reviews and clicks "Confirm")        │
     │                        │                          │
     ├── confirmBooking(id) ─▶ confirmBooking (CF)         │
     │                        ├── runTransaction: ────────▶│
     │                        │     read booking, equipment,│
     │                        │     query overlaps          │
     │                        │◀── data ─────────────────┤
     │                        ├── conflicts? ── no ────────┤
     │                        ├── write status=Confirmed ──▶│
     │◀── {status:Confirmed} ─┤                          │
     │                                                     │
     │  (Firestore listener pushes update to warehouse app │
     │   dispatch view in real time — no extra call needed)│
```

### 9.2 Conflict rejected

```
Staff B                confirmBooking (CF)              Firestore
   │                          │                              │
   ├── confirmBooking(id2) ──▶│                              │
   │                          ├── runTransaction: ───────────▶│
   │                          │  overlapping booking already  │
   │                          │  Confirmed for same equipment │
   │                          │◀── committedQty > available ─┤
   │◀── failed-precondition ──┤   (transaction aborts,        │
   │    { conflicts: [...] } │    no write happens)          │
   │                          │                              │
   │  Staff sees "Show Conflict Message" (PRD booking flow)   │
```

---

## 10. Flutter App Structure

```
lib/
├── main.dart
├── models/            // Dart classes mirroring §3 schemas: Equipment, Booking,
│                       // BookingHistoryEntry, UserProfile — with fromFirestore/toMap
├── screens/
│   ├── auth/           // Login, Register
│   ├── dashboard/       // role-specific landing screen
│   ├── equipment/       // Equipment List, Equipment Details
│   ├── bookings/        // Create Booking, Booking List, Booking Details
│   └── dispatch/        // Dispatch Schedule (warehouse's pull list)
├── widgets/            // shared UI: role-gated nav shell, status chips, conflict dialog
├── services/           // FirestoreService (typed collection refs), CloudFunctionsService
│                       // (typed wrappers around each callable in §7), AuthService
├── providers/          // app state — current user/role, active booking draft,
│                       // live equipment/booking streams
└── utils/              // date-range overlap helpers (client-side pre-check only —
                          // never trusted, real check is always server-side, §6)
```

**Role-gated navigation:** the shell reads the role custom claim (surfaced via `AuthService` after token refresh) and renders only the screens in §5 of the PRD's role table for that role — this is a UX convenience, **not** the access control (§8 Security Rules are the real gate).

**State management:** `providers/` implies the Provider package, consistent with the existing project structure. Each provider wraps a Firestore stream (`snapshots()`) so screens re-render on the same live data every role is looking at — the "everyone sees the same live truth" goal from PRD §2 falls out of this for free.

---

## 11. Audit Trail Design

Every `history[]` entry (embedded in the booking doc, §3.2) has a fixed shape:

```jsonc
{
  "action": "created" | "confirmed" | "cancelled" | "dispatched" | "returned" | "completed",
  "byUserId": "uid",
  "byRole": "staff",     // snapshot at time of action — if their role changes later, history stays accurate
  "timestamp": Timestamp,
  "note": "optional free text"
}
```

Embedding in the booking doc (rather than a separate `auditLog` collection) means the full history loads with the booking — no extra query for the Booking Details screen — and it's write-once via `arrayUnion` inside the same transaction/Cloud Function call that performs the status change, so it can never fall out of sync with `status`.

---

## 12. Error Handling & Edge Cases

| Case | Handling |
|---|---|
| Confirm attempted on a booking not in `Requested` | `failed-precondition`, generic "this booking has already moved past Requested" |
| More than 10 distinct equipment types in one booking | `array-contains-any` cap — batch the conflict query into groups of 10 and merge results before deciding conflicts |
| Equipment doc deleted while a booking referencing it is still `Requested` | `confirmBooking` fails fast with `not-found`; UI prompts staff to edit the booking |
| Two staff confirm conflicting bookings simultaneously | Handled by transaction semantics (§6.2) — one succeeds, one gets a fresh conflict read, no race |
| Client app loses connectivity mid-`createBookingRequest` | Callable functions aren't idempotent by default — client should disable the submit button and rely on the call's own retry, not fire twice. Idempotency keys are a Layer 2 hardening item, not required for Layer 1 correctness since no inventory is committed at this step (§5) |
| Cancelling a `Dispatched` booking | Explicitly disallowed by `cancelBooking` — equipment is physically out; must go through `returnBooking` first |

---

## 13. Indexing & Performance

Composite index required for the query in §6.1:

```
Collection: bookings
Fields: equipmentIds (Array), status (Ascending), startDateTime (Ascending)
```

Firestore will prompt to create this automatically the first time the query runs in a dev environment (console link in the error message) — create it explicitly in `firestore.indexes.json` instead so it ships with the first deploy rather than being discovered at demo time.

At the scale described in the PRD (a single regional rental company's booking volume), the query in §6.1 returns a small result set even during peak season — no need for pagination or a materialized "busy calendar" cache in Layer 1.

---

## 14. Testing Strategy

- **Firebase Emulator Suite** (Firestore + Functions + Auth) for all of the below — no tests should hit production Firestore.
- **Unit tests, conflict algorithm:** feed `confirmBooking`'s core logic (§6.2) synthetic overlapping/non-overlapping booking sets and assert conflict detection is correct at the boundary (exact quantity match, off-by-one date overlap, adjacent-but-not-overlapping ranges).
- **Concurrency test:** fire two `confirmBooking` calls for genuinely conflicting bookings at the same time against the emulator; assert exactly one succeeds — this is the test that actually proves the "structurally impossible to double-book" claim, not just the single-threaded logic test above.
- **Security Rules tests:** using `@firebase/rules-unit-testing`, assert a `staff`-claim client **cannot** write `status: "Confirmed"` directly to Firestore, only `status: "Requested"` on create — this is the test that proves §8 actually blocks the bypass PRD §6 warns about.
- **Widget tests:** conflict dialog renders the `conflicts[]` payload from a rejected `confirmBooking` call correctly.

---

## 15. Assumptions & Items Needing Confirmation

Flagged explicitly per the PRD's instruction not to silently change locked decisions:

1. **`users/{uid}` collection (§3.4)** — added here to make the audit trail human-readable. Not in the PRD's high-level data model. Needs sign-off, or an alternative resolution strategy.
2. **Cloud Functions runtime assumed Node.js/TypeScript** — the PRD doesn't specify; this is the common default for Firebase and is assumed for the pseudocode in §6.2/§7.
3. **State management assumed Provider** — inferred from the `providers/` folder already present in the project structure, not stated outright in the PRD.
4. **Conflict check happens at `Requested → Confirmed`, not at creation** — chosen to keep Layer 1 (staff-entered bookings) and future Layer 3 (client requests) on one unified lifecycle, per PRD §7's "one shared engine" decision. The PRD's open question about whether *clients* see live availability while browsing (§12) is a separate, still-open UX question for Layer 3 and isn't resolved by this choice.

---

## 16. Forward-Compatibility Notes (Layer 2+)

Confirms the Layer 1 schema doesn't need rework later, per PRD §3:

- **Buffer/turnaround time (Layer 2):** add a `bufferMinutes` field per equipment category; the §6.1 query's date range simply widens by that buffer when checking overlaps — no schema change to `bookings`.
- **Damage/shortage reporting (Layer 2):** `returnBooking` already exists as the write point; it just gains a `conditionReport` field and increments `equipment.damagedQuantity` — which §5's derived-availability design already accounts for automatically.
- **Notifications (Layer 2):** a Firestore `onWrite` trigger on `bookings/{id}` watching `status` changes, fanning out to FCM — additive, no existing writes change.
- **Client portal (Layer 3):** `createBookingRequest` already accepts a `client` caller path (§7); Security Rules already scope client reads to `createdBy == uid` (§8). The state machine and conflict engine need zero changes — exactly the "no rework" goal.
