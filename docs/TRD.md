# TRD — Technical Requirements Document
## Equipment Rental Booking & Dispatch App

> Companion to `PROJECT_CONTEXT.md` (scope) and `FOLDER_STRUCTURE.md` (repo layout).
> This file answers one question only: **what technology, exactly, do we use for each part of the system, and why that one and not an alternative.**
> If a technology choice here conflicts with `PROJECT_CONTEXT.md`, that file wins — raise it, don't silently pick a different stack.

---

## 1. Stack at a Glance

| Layer | Technology |
|---|---|
| Client (all 4 roles) | **Flutter** (Dart) |
| State management | **Riverpod** |
| Backend platform | **Firebase** (BaaS) |
| Database | **Cloud Firestore** |
| Server logic | **Cloud Functions for Firebase** (TypeScript, Node.js) |
| Auth | **Firebase Authentication** + Custom Claims (RBAC) |
| File/image storage | **Firebase Cloud Storage** |
| Push notifications | **Firebase Cloud Messaging (FCM)** |
| AI / LLM | **Claude (Anthropic API)**, called only from Cloud Functions |
| CI/CD | **GitHub Actions** |
| Crash & performance monitoring | **Firebase Crashlytics** + **Firebase Performance Monitoring** |
| Analytics | **Firebase Analytics** (usage) + custom Firestore aggregations (business analytics, Layer 4) |
| Local/offline persistence | **Firestore offline cache** (built-in) |
| Version control | **Git / GitHub** |

Every choice below is justified against the alternative(s) we didn't pick, because a TRD that just lists names without reasoning invites someone to swap a piece later without knowing what breaks.

---

## 2. Frontend

### 2.1 Flutter (client framework)
**What:** Google's UI toolkit — one Dart codebase compiles to Android, iOS, and Web.
**Why chosen over native (Swift/Kotlin) or React Native:**
- Four roles (Admin, Office/Staff, Warehouse, Client) share ~80% of the same data and a large share of the same UI patterns (lists, forms, calendars). One codebase avoids building and maintaining that logic twice.
- Warehouse staff need a reliable **offline mode** (`PROJECT_CONTEXT.md` Layer 2) at the loading dock; Flutter's widget rebuild model plus Firestore's offline cache handle this cleanly without a native bridge layer (React Native's JS↔native bridge is a known source of offline/sync bugs).
- Native would mean two separate codebases (iOS + Android) for a small team — direct conflict with "ship reliably, don't double the maintenance surface."

### 2.2 Dart
The language Flutter requires. Statically typed, null-safe — null safety matters here specifically because a `null` equipment quantity or booking status is exactly the kind of silent bug that causes a double-booking.

### 2.3 State Management — Riverpod
**What:** A reactive state-management library for Flutter.
**Why over Bloc or Provider (legacy):**
- Real-time Firestore listeners (availability changes, booking status changes) map naturally onto Riverpod's `StreamProvider` — a listener's output becomes reactive app state with almost no boilerplate.
- Compile-time safety (no `BuildContext`-based lookup failures at runtime) matters more here than in a typical app, because a stale availability read is the exact bug class this whole project exists to eliminate.
- Bloc is a fine alternative and not wrong — it's heavier boilerplate for the amount of real-time stream wiring this app needs, which is why Riverpod is the default. Not a hard rule; flag if the team has stronger Bloc experience.

### 2.4 Key Flutter packages

| Package | Purpose |
|---|---|
| `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `firebase_storage`, `firebase_messaging` | Official Firebase SDKs — one per Firebase product used |
| `flutter_riverpod` | State management |
| `go_router` | Declarative routing + role-based route guards |
| `table_calendar` (or equivalent) | Availability calendar UI (client browsing, dispatch scheduling) |
| `connectivity_plus` | Detects online/offline state for the warehouse offline-mode UX |
| `intl` | Date/time formatting, timezone-safe booking date handling |
| `freezed` + `json_serializable` | Immutable model classes with generated `fromJson`/`toJson`, kept in sync with `shared/types/` |
| `flutter_local_notifications` | In-app notification handling alongside FCM |
| `image_picker` | Warehouse photo capture for damage reports (Layer 2 / AI Tier 3) |

---

## 3. Backend — Firebase (Backend-as-a-Service)

**Why Firebase over a custom backend (e.g. Node/Express + PostgreSQL on a VM):** already decided in `PROJECT_CONTEXT.md` §2. Reasoning restated here for completeness: no server to provision or patch, Firestore's real-time listeners give live availability updates "for free," and Firestore transactions provide the atomic all-or-nothing guarantee the core conflict-prevention requirement depends on — a custom backend would have to build all three of those from scratch.

### 3.1 Cloud Firestore (database)
**What:** NoSQL document database, part of Firebase.
**Why over a SQL database:** bookings and equipment map naturally to self-contained JSON-like documents rather than normalized relational tables (see `PROJECT_CONTEXT.md`/feature guide §1.5). Real-time listeners and offline cache are native to Firestore, not bolt-ons.
**Non-negotiable usage rule:** every write that checks-then-modifies availability **must** go through a Firestore **transaction**. This is not a style preference — it's the mechanism that makes "two staff members book the last speaker at the same instant" structurally impossible instead of just unlikely.
**Composite indexes:** required for the date-range + status queries that power both the availability engine and the dispatch pull-list (same query, two views, per `PROJECT_CONTEXT.md` core engine philosophy). Defined in `firestore.indexes.json`.

### 3.2 Cloud Functions for Firebase (server logic)
**What:** Serverless functions triggered by HTTPS calls, Firestore events, or scheduled jobs.
**Language:** TypeScript (not raw JavaScript) — static typing here matters for the same reason it matters in Dart: a booking payload with a wrong field name should fail at compile time, not silently write bad data to Firestore.
**What must live here, never in the Flutter client:**
- The booking transaction (conflict check + write)
- Every AI call (see §5)
- Role assignment (custom claims)
- Any write that needs re-validation server-side, even if the client or an AI model already "checked"

**Function types used:**
- **Callable HTTPS functions** — invoked directly from the Flutter app (e.g. `createBookingRequest`, `checkAvailability`)
- **Firestore triggers** (`onCreate`/`onUpdate`) — e.g. automatically writing an audit-trail entry whenever a booking's status field changes, so logging can't be forgotten by a feature developer
- **Scheduled functions** — e.g. a nightly job for demand-forecasting data prep (Layer 4)

### 3.3 Firebase Authentication + Custom Claims (RBAC)
**What:** Handles login (email/password to start; can add phone or SSO later without a schema change) and issues a signed JWT per user.
**Role enforcement:** the user's role (`admin` / `staff` / `warehouse` / `client`) is embedded in the JWT as a **custom claim**, set only by a Cloud Function (`setCustomClaims.ts`) — never settable by the client. Firestore Security Rules then read that claim to allow/deny reads and writes.
**Why claims + rules, not just app-side role checks:** hiding an admin button in the UI does nothing if the underlying Firestore write is still reachable by a Client-role JWT. `PROJECT_CONTEXT.md` §5 requires enforcement at the rules layer explicitly for this reason.

### 3.4 Firestore Security Rules
Server-side, declarative rules (`firestore.rules`) — the actual access-control enforcement point, independent of anything the client claims to be doing. Every collection needs an explicit rule; the default posture is deny, not allow.

### 3.5 Firebase Cloud Storage
Holds equipment catalog images, damage-report photos (Layer 2/AI Tier 3), and any signed contract documents (Layer 3). Access governed by `storage.rules`, mirroring the same role-based approach as Firestore.

### 3.6 Firebase Cloud Messaging (FCM)
Push notifications: staff (upcoming dispatch), warehouse (today's load-out), clients (confirmation/reminders) — Layer 2 requirement. SMS/email notification channels (also listed in Layer 2) are a later addition via a third-party provider (e.g. Twilio for SMS, SendGrid for email) called from a Cloud Function — not decided yet, flagged as open below.

---

## 4. Data Contract Layer — `shared/types/`

Not a runtime technology but a required convention: TypeScript type definitions in `shared/types/` are the single authoritative shape for `Booking`, `Equipment`, and `User`/role, mirrored into Dart via `freezed` models on the client side. This exists specifically to prevent the two codebases (`app/`, `functions/`) from drifting into two different ideas of what a "booking" looks like — see `FOLDER_STRUCTURE.md` §3.

---

## 5. AI Layer

**What:** Anthropic's Claude, called via the Anthropic API.
**Where it's called from:** exclusively inside `functions/src/ai/` Cloud Functions — never from the Flutter client. This is a hard rule from `PROJECT_CONTEXT.md` §2 and §5, not a preference: it keeps the API key server-side and guarantees every AI-suggested availability or booking change gets re-validated against Firestore in the same transaction before it's committed, so a model's mistake ("hallucination," see feature guide glossary) can't corrupt the booking data.

**How each AI tier maps to technology:**

| Tier | Feature | Technical approach |
|---|---|---|
| 1 | Smart conflict resolution assistant | Cloud Function passes current availability data + the conflicting request to Claude, requests **structured output** (JSON) constrained to real substitute-equipment options actually in Firestore — model never invents an option that doesn't exist in inventory |
| 1 | Demand forecasting | Historical booking data aggregated in a scheduled Cloud Function; can start as a simple moving-average calculation (no AI needed) and layer in Claude-assisted pattern narration later |
| 2 | Natural language booking intake | Cloud Function sends staff's free-text request to Claude with a structured-output schema (equipment, dates, guest count); result returned to app as an editable draft, never auto-committed |
| 2 | AI-assisted quote generation | Cloud Function, structured prompt from event type + guest count + catalog data |
| 3 | Damage assessment via photo | Requires an image-capable model call — Storage-hosted photo passed to Claude for a draft damage description; human warehouse staff still confirms before the pool count changes |
| 3 | Smart dispatch/route assistant | Longer-term; likely pairs an optimization approach (loosely related to the Traveling Salesman Problem) with AI-drafted route notes |
| 4 | AI chat concierge / recommendation engine | Client-facing Cloud Function-backed chat; same "AI drafts, transaction re-validates" pattern as Tier 2 |

**Final choice of which 2–3 AI features ship first is still an open question per `PROJECT_CONTEXT.md` §6** — this TRD documents the technical approach for all of them so whichever gets picked doesn't require new infrastructure decisions.

---

## 6. DevOps, Testing, and Quality

### 6.1 Version Control & CI/CD
- **Git**, hosted on **GitHub**.
- **GitHub Actions** (`.github/workflows/`, per `FOLDER_STRUCTURE.md`): lint + test on every PR for both `app/` and `functions/` independently; deploy job runs only on merge to `main`, deploying Cloud Functions + Firestore/Storage rules together as one atomic unit — never a rules update shipped without the function code it assumes.
- **Environments:** dev / staging / prod, managed via `.firebaserc` project aliases — AI calls and destructive writes are tested against dev/staging Firestore data, never directly against production inventory.

### 6.2 Testing
- **Flutter:** unit tests + widget tests (`app/test/`), integration tests (`app/integration_test/`) for the booking flow specifically, since that's the highest-consequence path.
- **Cloud Functions:** unit tests against the Firebase Emulator Suite — the booking transaction's race-condition behavior should be tested with the emulator's concurrent-write simulation, not just manually.
- **Firebase Emulator Suite** is used for **local development end-to-end** (Firestore, Functions, Auth, Storage all run locally) so engineers aren't developing against production data.

### 6.3 Monitoring & Observability
- **Firebase Crashlytics** — client crash reporting.
- **Firebase Performance Monitoring** — client-side latency (relevant given the async-heavy, network-dependent nature of every booking action).
- **Cloud Functions logs** (via Google Cloud Logging, included with Firebase) — server-side error tracking, especially for AI call failures and transaction retries.
- **Firebase Analytics** — usage patterns; separate from the business-facing analytics dashboards in Layer 4, which are custom Firestore aggregation queries, not a general-purpose analytics tool.

### 6.4 Linting & Code Style
- **Flutter:** `analysis_options.yaml` with Dart's recommended lint set, enforced in CI (not optional/manual).
- **Functions:** ESLint + TypeScript strict mode.

---

## 7. Third-Party / Not-Yet-Decided Technologies (flagged, not committed)

These are named in `PROJECT_CONTEXT.md`'s later layers but the specific vendor is **not yet chosen** — listed here so a future decision has a place to land, not to imply the choice has been made:

| Need | Layer | Candidate options (undecided) |
|---|---|---|
| SMS notifications | Layer 2 | Twilio |
| Transactional email | Layer 2 | SendGrid, Firebase Extensions email trigger |
| Payments (deposits, invoicing) | Layer 3 | Stripe |
| E-signature | Layer 3 | DocuSign API, HelloSign/Dropbox Sign |
| Delivery route optimization | Layer 5 | Google Maps Directions API / Routes API |
| QR/barcode scanning | Layer 5 | `mobile_scanner` (Flutter package) |

None of these are integrated yet. Do not add a payment or e-signature SDK to the project without confirming — Layer 3 hasn't been scoped for build yet per `PROJECT_CONTEXT.md`.

---

## 8. Why This Stack Deploys as "One App"

Every backend piece (Firestore, Functions, Auth, Storage, Messaging) is under the same Firebase project, deployed via the same `firebase.json` referenced in `FOLDER_STRUCTURE.md`. The Flutter client talks to all of them through the official Firebase SDKs — there is no separate backend framework, separate hosting provider, or separate database to keep in sync. This is the direct technical payoff of choosing Firebase as BaaS in `PROJECT_CONTEXT.md` §2: fewer moving pieces to deploy and keep aligned, at the cost of being tied to Google's platform (a trade-off worth naming, not hiding — see below).

---

## 9. Known Trade-offs of This Stack (stated plainly, not glossed over)

- **Vendor lock-in:** Firestore's query model and security rules don't port to another database without a real rewrite. Accepted because the speed and reliability win (real-time + transactions + no server ops) outweighs portability for this project's scale.
- **Firestore query limitations:** no arbitrary joins, and some queries need denormalized data or Cloud Functions to compute what a SQL `JOIN` would do in one query. Addressed by intentional denormalization (documented per-collection in `docs/DATA_MODEL.md`) rather than fighting the database's model.
- **Cloud Functions cold starts:** the first call to an idle function has noticeable latency. Acceptable for booking/dispatch actions (not a hard real-time path); worth revisiting with minimum-instance config if the AI chat concierge (Tier 4) needs snappier responses.

---

*Keep this file in sync with actual dependencies (`pubspec.yaml`, `functions/package.json`). If a technology is added or swapped, update this document in the same PR.*
