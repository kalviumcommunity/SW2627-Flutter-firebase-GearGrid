# Product Requirements Document (PRD)
## Equipment Rental Booking & Dispatch App

| | |
|---|---|
| **Status** | Draft — Layer 1 not yet started |
| **Owner** | You (Product) + Claude (Engineering partner) |
| **Last updated** | This conversation |
| **Related docs** | `PROJECT_CONTEXT.md` (source of truth for scope), `Equipment_Rental_App_Feature_Guide_Deep.docx` (how-to-build teaching guide) |

> This PRD is the *what and why* for stakeholders and planning. `PROJECT_CONTEXT.md` remains the source of truth if the two ever disagree — update that file first, then this one.

---

## 1. Summary

We are building a **Flutter + Firebase** mobile/web application that replaces a regional event equipment rental company's entirely **phone-call-based** booking and dispatch process with a **centralized, real-time system**. The company rents **sound systems, lighting, and furniture** for weddings and corporate events.

The app starts as an internal tool that guarantees equipment can never be double-booked, then grows into a full client-facing platform with pricing, payments, analytics, and AI-assisted workflows.

---

## 2. Problem Statement

Today, all bookings and dispatch coordination happen through individual phone calls — there is no central system of record.

**The core failure:** during peak season, the same piece of equipment gets promised to two overlapping events, and this is only discovered when the warehouse crew starts loading the truck. There is no real-time visibility into what has already been committed, and nothing structurally prevents it from happening again.

**What success looks like:** it becomes *technically impossible* for two bookings to overcommit the same equipment, and every role in the business — office staff, warehouse crew, and eventually clients themselves — can see the same live truth at the same time.

---

## 3. Goals

- Eliminate double-booking through structurally enforced, real-time conflict detection — not just visibility after the fact.
- Give the warehouse team a reliable, advance pull list instead of discovering loadouts while packing the truck.
- Replace phone-call intake with a centralized booking system usable by both staff (entering phone orders) and clients (self-service requests).
- Preserve a full audit trail — who booked what, when, and who approved it.
- Build a data model and architecture that can grow into pricing, payments, analytics, and AI features *without requiring rework* of the Layer 1 foundation.

## 4. Non-Goals (for now)

- Multi-warehouse / multi-location support — open question, not committed.
- White-label / multi-tenant productization — vision-level (Layer 5), not scoped.
- Serialized, per-unit equipment tracking — we use quantity pools, not individually tracked units, by design.
- Final selection of which AI features ship first — flagged as still open; see Section 9.

---

## 5. Users & Roles

| Role | Who they are | Core needs |
|---|---|---|
| **Admin** | Business owner / manager | Full visibility and control; approves structural decisions (e.g. marking damaged equipment repaired) |
| **Office / Staff** | Takes phone orders, manages bookings | Enter bookings on a client's behalf, confirm requests, resolve conflicts |
| **Warehouse** | Loads, prepares, and receives equipment | See what to pack and when; log damage/shortage on return |
| **Client** | Wedding/event customers renting equipment | Browse catalog, check availability, submit booking requests, (later) pay and sign contracts |

Access is enforced via **Firebase Auth custom claims + Firestore Security Rules** — role checks happen server-side, never only in the UI.

---

## 6. Tech Stack

| Layer | Choice | Why (brief) |
|---|---|---|
| Client | **Flutter** (Dart) | One codebase for iOS, Android, and web, covering four very different user roles |
| Auth | **Firebase Authentication** | Managed login + identity tokens; custom claims carry each user's role |
| Database | **Cloud Firestore** | NoSQL document database with real-time listeners — the "everyone sees the same live data" requirement is a database feature here, not something we build ourselves |
| Server logic | **Cloud Functions** | All sensitive/atomic logic (conflict checks, AI calls, payments) runs here — never trusted to the client |
| Notifications | **Firebase Cloud Messaging** | Push notifications to staff/warehouse/clients |
| File storage | **Cloud Storage** | Damage-report photos, generated contract PDFs |

**Non-negotiable rule:** AI calls and any conflict-sensitive writes always go through Cloud Functions, never directly from the Flutter client.

---

## 7. Foundational Decisions (locked — do not silently change)

- **Equipment tracking:** quantity pools (e.g. "10 speakers available"), not individually serialized units.
- **Booking confirmation flow:** client submissions are *requests*, not instant confirmations — staff/admin approval is required.
- **Core engine:** one shared availability/booking engine powers both conflict prevention *and* the dispatch view — they are two queries over the same data, not two systems.
- **Conflict detection:** must use Firestore transactions (atomic, all-or-nothing) — never a "check, then write" pattern that could race.
- **Booking lifecycle:** `Requested → Confirmed → Dispatched → Returned → Completed` (+ `Cancelled` as a side-exit).

---

## 8. Feature Requirements

Organized in layers for scope clarity — **not** strictly sequential build phases, though later layers do depend on earlier ones. Priority order: **Layer 1 → Layer 2 → AI Tier 1/2 → Layer 3 → Layer 4 → AI Tier 3/4 → Layer 5.**

### Layer 1 — Mandatory Core
*Non-negotiable. This is the entire reason the project exists.*

- Equipment catalog (categories: sound / lighting / furniture; name; total quantity owned)
- Centralized booking system replacing phone-call-only coordination
- Real-time, structurally enforced conflict detection (Firestore transactions)
- Dispatch/warehouse view — reliable advance pull list
- Booking lifecycle status tracking
- Multi-user roles with real (server-enforced) access control
- Audit trail — who booked what, when, who approved it

### Layer 2 — Operational Excellence
*Makes the core reliable in the field.*

- Buffer/turnaround time between bookings (cleaning/inspection window)
- Damage/shortage reporting, reducing usable pool count until repaired
- Delivery & pickup scheduling (truck times, routes, driver assignment)
- Overbooking/waitlist handling with substitute-equipment suggestions
- Notifications (push/SMS/email) for staff, warehouse, and clients
- Offline mode for the warehouse app (poor loading-dock connectivity)

### Layer 3 — Client Experience
*Grows beyond an internal-only tool.*

- Client self-service portal (browse, check live availability, submit requests)
- Quotes & pricing engine (equipment + duration + delivery distance)
- Digital contracts / e-signature
- Payments — deposits, invoicing, payment status tracking
- Booking history & reordering for repeat clients
- Post-event reviews/ratings

### Layer 4 — Business Intelligence & Growth
*Mostly reads and summarizes data the earlier layers already generate.*

- Utilization analytics (most/least booked equipment → informs purchasing)
- Seasonal demand forecasting
- Revenue dashboards (by category, client, season)
- Staff performance / dispatch efficiency tracking
- Multi-warehouse/multi-location support *(open question — not committed)*
- Vendor/subcontractor equipment tracking for overflow periods

### Layer 5 — Future / Platform Scale
*Vision-level. Not being built now, but designed around.*

- QR/barcode scanning for warehouse check-in/check-out
- Route optimization for multi-drop delivery days
- White-label / multi-tenant potential

---

## 9. AI Integration

AI is a first-class part of this product, organized by how directly each feature ties back to the core problem. **Every AI feature follows one rule: the AI can suggest, only the Cloud Function's transaction can confirm.** Nothing an AI produces is ever written to Firestore without being re-validated server-side first.

| Tier | Feature | Ties to |
|---|---|---|
| **Tier 1** | Smart conflict resolution assistant — suggests alternatives instead of a flat rejection | Directly strengthens the core no-double-booking problem |
| **Tier 1** | Demand forecasting — predicts peak-season crunches from historical data | Feeds Layer 4 analytics |
| **Tier 2** | Natural language booking intake — converts unstructured staff input into a structured draft | **Flagged as highest-leverage AI feature**; most directly replaces the phone call |
| **Tier 2** | AI-assisted quote generation | Builds on Layer 3 pricing engine |
| **Tier 3** | Damage assessment via photo | Speeds up Layer 2 damage reporting |
| **Tier 3** | Smart dispatch/route assistant | Builds on Layer 2 delivery scheduling |
| **Tier 4** | AI chat concierge — 24/7 client-facing booking assistant | Strongest demo/pitch "wow factor"; depends on client portal existing |
| **Tier 4** | Package/equipment recommendation engine | Builds on Layer 4 utilization analytics |

**Final prioritized order within the AI layer is still open** — Tier 1 (conflict resolution) + Tier 2 (natural language intake) attack the original problem most directly and are the current leading candidates to build first.

---

## 10. Data Model (high level)

- `equipment` — one document per equipment type: `id`, `name`, `category`, `totalQuantity`, `damagedQuantity`
- `bookings` — one document per booking: client info, equipment + quantities requested, date range, `status`, `price` (present from day one, even before billing logic exists, to avoid a future schema migration), `history[]` (audit trail)
- Roles are not a Firestore collection — they live as **custom claims** on each user's Firebase Auth token and are checked in Security Rules.

---

## 11. Success Metrics

- **Zero** double-bookings after Layer 1 ships (the core measurable outcome).
- Time from "client calls/submits a request" to "warehouse has an accurate pull list" — should shrink from same-day scrambling to advance, predictable prep.
- % of bookings entered without a phone call, once the client portal (Layer 3) ships.
- Reduction in disputed bookings, attributable to the audit trail.

---

## 12. Open Questions

*Not yet decided — do not assume answers.*

- Should clients see real-time availability while browsing, or is availability checked silently on submit with conflicts handled at staff approval?
- Final prioritized order for AI features — which 2–3 ship first?
- Is multi-warehouse support needed now, or purely a future (Layer 5) concern?
- Pricing model specifics — flat per-item, per-day, delivery distance tiers — not yet defined.

---

## 13. Risks & Assumptions

- **Assumption:** equipment is largely interchangeable within a category, making quantity-pool tracking sufficient (vs. serialized tracking). Revisit if the company starts renting high-value, individually distinct items.
- **Risk:** offline mode at the warehouse depends on Firestore's built-in offline persistence behaving well under real loading-dock conditions — needs field testing, not just simulation.
- **Risk:** AI-suggested content (bookings, quotes, damage reports) must never be trusted without human or transactional re-validation — a lapse here reintroduces the exact race-condition risk Layer 1 exists to eliminate.

---

## 14. How This Document Should Be Used

- Treat `PROJECT_CONTEXT.md` as the source of truth for scope; this PRD is the readable summary for planning and stakeholder conversations.
- If scope changes, update `PROJECT_CONTEXT.md` first, then reflect the change here.
- Layer 1 is mandatory and must never be silently dropped or simplified away.
