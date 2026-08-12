# IMPLEMENTATION PLAN
## Equipment Rental Booking & Dispatch App

> Companion to `PROJECT_CONTEXT.md`, `FOLDER_STRUCTURE.md`, `TRD.md`, `DATA_MODEL.md`, `APPLICATION_FLOW.md`.
> This file answers: **in what order do we actually build this, step by step, and what has to be true before each step starts.**

**Ordering principle** (directly from `PROJECT_CONTEXT.md` §7): *Layer 1 → Layer 2 → AI Tier 1/2 → Layer 3 → Layer 4 → AI Tier 3/4 → Layer 5.* Every phase below follows that order. Layer 1 is not "phase one of many equal phases" — it's the mandatory backbone; nothing after it matters if it isn't solid.

**Sizing note:** steps are ordered by dependency, not by calendar time — team size and velocity aren't known, so this plan gives sequence and "what blocks what," not sprint dates. Attach dates once a team size is confirmed.

**Decisions that must be resolved before certain steps — collected in §9.** Several steps below are marked `⚠ BLOCKED ON DECISION` — don't start those specific steps until the linked open question is answered; everything else in the same phase can proceed.

---

## Phase 0 — Project Setup & Scaffolding

Nothing feature-related happens until this exists; every later phase assumes it.

- [ ] Create the Git repo with the structure defined in `FOLDER_STRUCTURE.md`
- [ ] Create three Firebase projects: `dev`, `staging`, `prod`; wire up `.firebaserc` aliases
- [ ] Initialize `app/` — Flutter project, add core packages from `TRD.md` §2.4
- [ ] Initialize `functions/` — TypeScript Cloud Functions project, add dependencies from `TRD.md` §3.2
- [ ] Set up `shared/types/` and confirm both `app/` (via `freezed`) and `functions/` import from the same source shapes
- [ ] Install and configure the **Firebase Emulator Suite** for local dev (Firestore, Auth, Functions, Storage)
- [ ] Write `firestore.rules` and `storage.rules` skeletons — default-deny, no collection open yet
- [ ] Set up GitHub Actions: `flutter_ci.yml`, `functions_ci.yml` (lint + test on PR); hold off on `deploy.yml` until there's something worth deploying
- [ ] Write `README.md` — how to run the emulator suite locally, how to run the app against it

**Exit criteria:** a developer can clone the repo, run the emulator suite, run the Flutter app against it, and see an empty login screen. No real features yet.

---

## Phase 1 — Layer 1: Mandatory Core

This is the backbone. Every sub-step below maps directly to a section of `DATA_MODEL.md` and `APPLICATION_FLOW.md` — build in this order because later steps in this phase depend on earlier ones.

### 1.1 Auth & Roles
- [ ] Firebase Auth email/password login screen (`app/lib/features/auth/`)
- [ ] `users/{uid}` document creation on signup (`DATA_MODEL.md` §3.1)
- [ ] `setCustomClaims` Cloud Function — role assignment, admin-only invocation
- [ ] Role-based routing (`app/lib/core/routing/`) — four home screens per role
- [ ] Security Rules: `users` collection read/write rules (§7 of `DATA_MODEL.md`)

### 1.2 Equipment Catalog
- [ ] `equipment/{id}` collection + Security Rules (admin/staff write, any authenticated read)
- [ ] Admin screen: add/edit/deactivate equipment (`app/lib/features/admin/`)
- [ ] Client/staff screen: catalog browse, filter by category

### 1.3 The Core Engine — Availability & Conflict Detection
This is the single most important step in the entire project — everything else depends on it being correct.
- [ ] Implement the collection-group index strategy from `DATA_MODEL.md` §3.4 and §8 (`items` collection group indexed on `equipmentId` + `status` + date fields)
- [ ] Write `checkAvailability.ts` — read-only query, used by catalog browsing (live availability) and as the first check inside the transaction
- [ ] Write `bookingTransaction.ts` — the atomic Firestore transaction: re-check availability, then write the booking + line items in one all-or-nothing operation
- [ ] ⚠ **BLOCKED ON DECISION** (§9.1): stale `Requested` soft-hold auto-expiry window — needed before finalizing which statuses the availability query counts and for how long
- [ ] Emulator test: simulate two concurrent booking attempts for the last unit — confirm exactly one succeeds (this is the test that proves the core problem is actually solved)

### 1.4 Booking Lifecycle
- [ ] `createBookingRequest.ts` — client and staff phone-in bookings both call this (`APPLICATION_FLOW.md` §3, same code path, no separate staff shortcut)
- [ ] `approveBooking.ts` — `Requested → Confirmed`, with the modify-quantities case from `APPLICATION_FLOW.md` §3.3
- [ ] ⚠ **BLOCKED ON DECISION** (§9.2): partial-fulfillment client UX (auto-accept vs. client confirms reduced quantity) — needed before finalizing `approveBooking.ts`'s response contract
- [ ] `cancelBooking.ts` — rejection and cancellation paths
- [ ] ⚠ **BLOCKED ON DECISION** (§9.3): can a client self-cancel a `Confirmed` booking, or staff-only — needed before finalizing `cancelBooking.ts`'s permission check
- [ ] Client screen: submit request, view own booking + live status (Firestore listener)
- [ ] Staff screen: pending requests queue, approve/reject/modify UI

### 1.5 Dispatch / Warehouse View
- [ ] `generatePullList.ts` — same underlying query as `checkAvailability`, filtered to `Confirmed` bookings with near-term delivery dates (`APPLICATION_FLOW.md` §4.1)
- [ ] Warehouse screen: today's pull list, mark items loaded
- [ ] `markDispatched.ts` — `Confirmed → Dispatched`, updates line items in the same transaction
- [ ] `markReturned.ts` — `Dispatched → Returned`

### 1.6 Audit Trail
- [ ] `onBookingStatusChange.ts` Firestore trigger — writes to `auditLogs` automatically on every status transition (never a manual write from a feature screen)
- [ ] Admin screen: read-only audit log viewer, filterable by entity

### 1.7 Security Rules — Full Pass
- [ ] Implement the complete rules table from `DATA_MODEL.md` §7 (illegal status-transition rejection at the rules layer, not just the UI)
- [ ] Emulator test: confirm a `Requested → Dispatched` direct write is rejected regardless of role

**Exit criteria for Phase 1:** a client can submit a request, staff can approve it, warehouse can dispatch and receive it back, status is visible live to all relevant roles, two simultaneous booking attempts for the same last unit cannot both succeed, and every status change has an audit log entry. This is the app the original problem statement describes — everything after this point is enhancement.

---

## Phase 2 — Layer 2: Operational Excellence

Builds on Phase 1's data model — none of these need new core collections, just new fields/screens already reserved for them.

- [ ] **Buffer/turnaround time** — `equipment.bufferHours` (already in schema) wired into `checkAvailability` so a `Returned` item isn't immediately bookable again
- [ ] **Damage/shortage reporting** — `damageReports/{id}` collection, warehouse screen, `equipment.damagedQuantity` decrement Cloud Function
- [ ] **Delivery & pickup scheduling** — driver assignment, date/time fields on `bookings` (already reserved), staff scheduling screen
- [ ] **Overbooking/waitlist handling** — `waitlist/{id}` collection, triggered when `bookingTransaction` finds insufficient quantity (`APPLICATION_FLOW.md` §2 step 3)
- [ ] **Notifications** — FCM integration, `notifications/{id}` writes triggered from the relevant Cloud Functions per the table in `APPLICATION_FLOW.md` §7; push-only first, SMS/email providers deferred (`TRD.md` §7)
- [ ] **Offline mode for warehouse app** — `connectivity_plus` integration, Firestore offline cache tuning, explicit "sync pending" UI state for the warehouse screens specifically (this is the one role that needs it most, per the loading-dock connectivity problem in `PROJECT_CONTEXT.md`)

**Exit criteria:** the app is reliable in real field conditions, not just correct in ideal conditions.

---

## Phase 3 — AI Tier 1 & 2

Per `PROJECT_CONTEXT.md` §4, these attack the original problem most directly and come before Layer 3.

- [ ] ⚠ **BLOCKED ON DECISION** (§9.4): final prioritized order of which 2–3 AI features ship first within this phase
- [ ] **Smart conflict resolution assistant** (Tier 1) — `functions/src/ai/conflictResolution.ts`, structured-output call constrained to real inventory (`TRD.md` §5)
- [ ] **Demand forecasting baseline** (Tier 1) — start with a moving-average calculation over historical bookings (no AI needed yet), feeds Layer 4 dashboards later
- [ ] **Natural language booking intake** (Tier 2) — `functions/src/ai/nlBookingIntake.ts`, staff paste unstructured request → structured draft → still goes through the normal `createBookingRequest` review flow, never auto-committed
- [ ] **AI-assisted quote generation** (Tier 2) — depends on Layer 3's pricing model existing (see Phase 4) unless a placeholder pricing scheme is used to unblock it early

**Exit criteria:** the highest-leverage AI features (per the guide's own "Tier 2 is highest-leverage given current workflow" note) are live and reviewed by humans before any write commits.

---

## Phase 4 — Layer 3: Client Experience

- [ ] **Client self-service portal enhancements** — most of this exists from Phase 1/2; this step is polish (saved filters, richer catalog browsing)
- [ ] **Quotes & pricing engine** — activate the reserved `pricePerDay`/`pricePerUnit`/`totalPrice` fields (`DATA_MODEL.md` §3.2–3.4); build `quotes/{id}` collection rules and screens (§5.1)
- [ ] ⚠ **BLOCKED ON DECISION**: pricing model specifics (flat/per-day/distance-tiered) — `PROJECT_CONTEXT.md` §6, still open
- [ ] **Digital contracts/e-signature** — vendor integration (candidate: DocuSign/HelloSign, `TRD.md` §7 — not yet chosen)
- [ ] **Payments** — vendor integration (candidate: Stripe, `TRD.md` §7 — not yet chosen), `payments/{id}` collection (`DATA_MODEL.md` §5.2)
- [ ] **Booking history & reordering** — duplicate-past-booking action (already described in `APPLICATION_FLOW.md` §2 step 7)
- [ ] **Reviews/ratings** — `reviews/{id}` collection (`DATA_MODEL.md` §5.3), post-`Completed` prompt

---

## Phase 5 — Layer 4: Business Intelligence & Growth

- [ ] **Utilization analytics** — most/least booked equipment, aggregation queries over `bookings`/`items`
- [ ] **Seasonal demand forecasting** — extends the Phase 3 moving-average baseline with more historical data and, optionally, AI-assisted trend narration
- [ ] **Revenue dashboards** — by category/client/season, depends on Phase 4 pricing data existing
- [ ] **Staff performance / dispatch efficiency tracking**
- [ ] ⚠ **BLOCKED ON DECISION**: multi-warehouse support — `PROJECT_CONTEXT.md` §6, still open; if confirmed, activate the reserved `equipment.warehouseId` and `warehouses/{id}` collection (`DATA_MODEL.md` §6.1)
- [ ] **Vendor/subcontractor equipment tracking** — extends `equipment` schema for externally-sourced overflow stock

---

## Phase 6 — AI Tier 3 & 4

- [ ] **Damage assessment via photo** (Tier 3) — builds on Phase 2's damage reporting; adds `aiDraftDescription` field usage (`DATA_MODEL.md` §4.2), always human-confirmed before commit
- [ ] **Smart dispatch/route assistant** (Tier 3) — pairs with Phase 5's dispatch efficiency data
- [ ] **AI chat concierge** (Tier 4) — client-facing, reuses the `nlBookingIntake` pattern with a conversational front end
- [ ] **Package/equipment recommendation engine** (Tier 4) — suggests bundles based on event type + guest count

---

## Phase 7 — Layer 5: Future / Platform Scale

Vision-level; not scoped for active work per `PROJECT_CONTEXT.md` §3. Listed for completeness only.

- [ ] QR/barcode scanning for warehouse check-in/check-out
- [ ] Route optimization for multi-drop delivery days
- [ ] White-label / multi-tenant potential

---

## 8. Testing Checkpoints (apply throughout, not just at the end)

| After phase | Required before moving on |
|---|---|
| Phase 1 | Emulator concurrency test (two simultaneous last-unit bookings) passes; full Security Rules test suite passes; manual walkthrough of all four role flows end-to-end |
| Phase 2 | Offline mode tested with network actually disabled mid-session on a real device, not just simulated |
| Phase 3 | Every AI-suggested action verified to be re-validated server-side before commit — no AI output writes to Firestore directly |
| Phase 4 | Payment/e-signature integration tested in each vendor's sandbox mode before any real transaction |
| Ongoing | CI (`flutter_ci.yml`, `functions_ci.yml`) green on every PR; `deploy.yml` only fires on `main` |

---

## 9. Decisions Required (consolidated — do not proceed past the marked step without an answer)

| # | Decision | Blocks |
|---|---|---|
| 9.1 | Auto-expiry window for stale `Requested` soft-holds | Phase 1.3 |
| 9.2 | Partial-fulfillment UX (auto-accept vs. client confirms) | Phase 1.4 |
| 9.3 | Can clients self-cancel a `Confirmed` booking, or staff-only | Phase 1.4 |
| 9.4 | Final prioritized order of first 2–3 AI features | Phase 3 |
| 9.5 | Pricing model specifics | Phase 4 |
| 9.6 | Multi-warehouse: needed now or Layer 5 vision only | Phase 5 |

These mirror the open items already tracked in `PROJECT_CONTEXT.md` §6, `DATA_MODEL.md` §9, and `APPLICATION_FLOW.md` §8 — collected here so nobody starts a blocked step without checking this table first.

---

*Keep this file in sync with actual progress — check items off as they land in `main`, and update the decisions table the moment an open question is answered.*
