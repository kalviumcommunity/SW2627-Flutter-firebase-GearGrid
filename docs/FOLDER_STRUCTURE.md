# FOLDER STRUCTURE — Equipment Rental Booking & Dispatch App

> Companion to `PROJECT_CONTEXT.md`. That file defines *what* we're building and *why*.
> This file defines *where things live in the repo* and *why the repo is shaped this way*.
> Read `PROJECT_CONTEXT.md` first if you haven't — every structural decision below traces back to a rule in it.

---

## 1. Repo Strategy: Single Monorepo, Two Deployables

One Git repository, two independently deployable units inside it:

- **`app/`** — the Flutter client (Admin, Office/Staff, Warehouse, Client all run the *same* codebase, gated by role)
- **`functions/`** — Firebase Cloud Functions (all server-side logic, all AI calls, all writes that must be trusted)

**Why one repo instead of two:**
- The Flutter app and Cloud Functions share a data contract (booking status enum, equipment schema, role names). In two repos, that contract drifts silently. In one repo, a single `shared/` package is the single source of truth for both sides.
- One PR can change a Firestore field *and* the client code that reads it *and* the Cloud Function that writes it, reviewed together — exactly the kind of change that causes production bugs when split across repos with separate release cadences.
- Firebase deploys frontend (Hosting, if used for a web build) and backend (Functions, Firestore rules, Storage rules) from the same `firebase.json` anyway — the tooling already assumes co-location.

**Why still two clearly separated top-level folders, not one mixed pile:**
- `PROJECT_CONTEXT.md` §2 is explicit: AI calls and conflict-sensitive writes must **never** run client-side. Keeping `app/` and `functions/` as hard-separated folders makes "does this code run on the phone or on the server" a folder-path question, not a judgment call — which is the whole point of the never-trust-the-client rule.

---

## 2. Full Tree

```
equipment-rental-app/
│
├── README.md                        # setup, run, deploy — first thing any dev reads
├── PROJECT_CONTEXT.md                # scope source of truth (already exists)
├── FOLDER_STRUCTURE.md               # this file
├── .gitignore
├── .env.example                      # documents required env vars, no real secrets
│
├── firebase.json                     # ties the whole repo together for `firebase deploy`
├── .firebaserc                       # project aliases (dev / staging / prod)
├── firestore.rules                   # security rules — enforced server-side, not UI-level
├── firestore.indexes.json            # composite indexes (date-range + status queries need these)
├── storage.rules                     # rules for photos: damage reports, equipment images
│
├── shared/                           # the ONE contract both app/ and functions/ import from
│   ├── types/
│   │   ├── booking.ts                 # BookingStatus enum, Booking shape
│   │   ├── equipment.ts               # Equipment shape, category enum
│   │   ├── user.ts                    # Role enum (admin/staff/warehouse/client)
│   │   └── index.ts
│   └── constants/
│       ├── bookingStatuses.ts         # Requested→Confirmed→Dispatched→Returned→Completed→Cancelled
│       └── roles.ts
│
├── app/                              # ── FLUTTER FRONTEND (all 4 roles, one codebase) ──
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart                   # MaterialApp, top-level routing, role-based home redirect
│   │   │
│   │   ├── core/
│   │   │   ├── config/                # Firebase options, environment flavors (dev/staging/prod)
│   │   │   ├── theme/
│   │   │   ├── routing/               # named routes, role-based route guards
│   │   │   ├── errors/                # typed exceptions, error-to-user-message mapping
│   │   │   └── utils/
│   │   │
│   │   ├── services/                  # thin wrappers around Firebase SDKs — nothing else touches Firebase directly
│   │   │   ├── auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   ├── functions_service.dart # calls Cloud Functions — the ONLY path to AI features
│   │   │   ├── storage_service.dart
│   │   │   └── messaging_service.dart # push notifications
│   │   │
│   │   ├── models/                    # Dart classes mirroring shared/types/*, with fromJson/toJson
│   │   │   ├── equipment_model.dart
│   │   │   ├── booking_model.dart
│   │   │   ├── user_model.dart
│   │   │   └── audit_log_model.dart
│   │   │
│   │   ├── state/                     # state management layer (e.g. Riverpod providers / Bloc)
│   │   │   ├── auth/
│   │   │   ├── catalog/
│   │   │   ├── booking/
│   │   │   └── dispatch/
│   │   │
│   │   ├── features/                  # feature-first, NOT type-first — each folder is a vertical slice
│   │   │   ├── auth/
│   │   │   │   └── presentation/      # login, role-based redirect screens
│   │   │   ├── catalog/
│   │   │   │   └── presentation/      # equipment browsing, availability calendar
│   │   │   ├── booking/
│   │   │   │   └── presentation/      # booking request flow, status tracking
│   │   │   ├── dispatch/
│   │   │   │   └── presentation/      # warehouse pull-list, load-out view
│   │   │   ├── admin/
│   │   │   │   └── presentation/      # approvals, user/role management, audit log viewer
│   │   │   └── client_portal/
│   │   │       └── presentation/      # Layer 3 — client-facing self-service screens
│   │   │
│   │   └── shared_widgets/            # reusable UI: buttons, status badges, calendar picker
│   │
│   ├── test/                          # unit + widget tests, mirrors lib/ structure
│   ├── integration_test/
│   ├── assets/
│   │   ├── images/
│   │   ├── icons/
│   │   └── fonts/
│   ├── android/
│   ├── ios/
│   ├── web/                           # only if a web build of the client is planned
│   ├── pubspec.yaml
│   └── analysis_options.yaml          # lint rules — enforced in CI, not optional
│
├── functions/                        # ── FIREBASE CLOUD FUNCTIONS (all backend logic) ──
│   ├── src/
│   │   ├── index.ts                   # exports every function — the deploy manifest
│   │   │
│   │   ├── booking/
│   │   │   ├── createBookingRequest.ts
│   │   │   ├── approveBooking.ts      # staff approval step — Requested → Confirmed
│   │   │   ├── checkAvailability.ts   # the shared availability engine (PROJECT_CONTEXT §2)
│   │   │   ├── bookingTransaction.ts  # the Firestore transaction — atomic conflict prevention
│   │   │   └── cancelBooking.ts
│   │   │
│   │   ├── dispatch/
│   │   │   ├── generatePullList.ts    # same underlying query as checkAvailability, different view
│   │   │   └── markReturned.ts
│   │   │
│   │   ├── inventory/
│   │   │   ├── damageReport.ts        # reduces pool count on damage
│   │   │   └── waitlist.ts
│   │   │
│   │   ├── ai/                        # EVERY AI call lives here — never called from app/ directly
│   │   │   ├── nlBookingIntake.ts     # Tier 2: unstructured text → structured booking draft
│   │   │   ├── conflictResolution.ts  # Tier 1: suggests alternatives on shortage
│   │   │   ├── demandForecast.ts      # Tier 1: feeds Layer 4 analytics
│   │   │   ├── quoteGeneration.ts     # Tier 2
│   │   │   ├── damageAssessment.ts    # Tier 3: photo-based
│   │   │   └── shared/
│   │   │       ├── aiClient.ts        # single place the LLM API key is read from env
│   │   │       └── promptTemplates.ts
│   │   │
│   │   ├── notifications/
│   │   │   ├── sendPushNotification.ts
│   │   │   └── sendEmailReminder.ts
│   │   │
│   │   ├── triggers/                  # Firestore-triggered functions (onCreate/onUpdate)
│   │   │   ├── onBookingStatusChange.ts  # writes audit trail entries automatically
│   │   │   └── onEquipmentUpdate.ts
│   │   │
│   │   ├── auth/
│   │   │   └── setCustomClaims.ts     # assigns role via Firebase Auth custom claims
│   │   │
│   │   └── shared/
│   │       ├── firestoreClient.ts
│   │       ├── validators/            # re-validates availability server-side, always
│   │       └── errors.ts
│   │
│   ├── test/                          # mirrors src/ structure
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example                   # AI API key placeholder — real key set via Firebase config, never committed
│
├── scripts/
│   ├── seed_data.ts                   # populates dev Firestore with sample equipment/bookings
│   ├── deploy.sh                      # wraps `firebase deploy` per environment
│   └── setup.sh                       # first-time repo setup for a new dev
│
├── docs/
│   ├── ARCHITECTURE.md                # system diagram, client-server flow
│   ├── DATA_MODEL.md                  # Firestore collection/document shapes, incl. fields reserved for later layers
│   ├── SECURITY_RULES.md              # plain-English explanation of firestore.rules
│   └── AI_INTEGRATION.md              # maps each AI tier to its Cloud Function
│
└── .github/
    └── workflows/
        ├── flutter_ci.yml             # lint + test app/ on every PR
        ├── functions_ci.yml           # lint + test functions/ on every PR
        └── deploy.yml                 # deploy functions + rules on merge to main
```

---

## 3. Rules This Structure Enforces (traced to `PROJECT_CONTEXT.md`)

| Rule from PROJECT_CONTEXT.md | How the folder structure enforces it |
|---|---|
| AI calls must go through Cloud Functions, never called directly from the Flutter client | All AI code lives only under `functions/src/ai/`. The client only ever calls `functions_service.dart`, which calls a Cloud Function — there is no code path in `app/` that can reach an LLM API key. |
| Conflict detection must use Firestore transactions | `functions/src/booking/bookingTransaction.ts` is the single, isolated place this logic lives — not duplicated per-screen in the client. |
| One shared availability/booking engine powers both conflict prevention AND the dispatch list | `checkAvailability.ts` (booking) and `generatePullList.ts` (dispatch) are separate files but both are documented to call the same underlying query — kept in sibling folders (`booking/`, `dispatch/`) rather than merged, so each stays readable, but `docs/ARCHITECTURE.md` records that they're one engine, two views. |
| Roles enforced via Firebase Auth custom claims + Firestore security rules, not just UI-level hiding | `firestore.rules` sits at the repo root, not inside `app/` — it's server-enforced infrastructure, not a client concern. `functions/src/auth/setCustomClaims.ts` is the only place claims are assigned. |
| Audit trail: who booked what, when, who approved it | `triggers/onBookingStatusChange.ts` writes audit entries automatically on every status transition, so no feature can forget to log one — it isn't left to each screen's code. |
| Data model must anticipate later layers even if not built yet | `shared/types/booking.ts` is the one place the `Booking` shape is defined; adding a `price` field (Layer 3) or a `warehouseId` field (Layer 4) happens once, and both `app/` and `functions/` pick it up — no schema drift between two hand-maintained copies. |
| Client submissions are requests, not instant confirmations | `booking/createBookingRequest.ts` and `booking/approveBooking.ts` are deliberately two separate functions, mirroring the two-step human process, not one "createBooking" that assumes trust. |
| Feature layers (1–5) shouldn't require rework to slot in later | `app/lib/features/` and `functions/src/` are organized by feature, not by layer number — `client_portal/`, `admin/` etc. already exist as folders even before every screen inside them is built, so Layer 3+ work adds files, not restructures. |

---

## 4. Why This Deploys Cleanly

- `firebase.json` at the repo root references `functions/` (Cloud Functions), `firestore.rules`, `storage.rules`, and optionally `app/build/web` (Hosting) — one `firebase deploy` from the repo root ships backend + rules together, so they can never go out of sync.
- `app/` is deployed separately per platform (`flutter build apk` / `ipa` / `web`) through normal Flutter tooling — it doesn't need Firebase CLI at all for mobile builds, only for a web build via Hosting.
- CI (`.github/workflows/`) lints and tests each side independently on every PR, but `deploy.yml` only runs against `main`, so `functions/` and `firestore.rules` always ship together as one atomic deploy — never a half-updated ruleset against new function code.
- `.env.example` (root) and `functions/.env.example` document every required secret name without ever committing a real one; actual secrets go into Firebase's own config/secret manager, never into the repo.

---

## 5. Open Item

`PROJECT_CONTEXT.md` §6 leaves multi-warehouse support undecided. This structure already isolates warehouse-specific logic under `functions/src/dispatch/` and reserves `warehouseId` as a future field in `shared/types/equipment.ts`/`booking.ts` — so if multi-warehouse is confirmed later, it's an additive change, not a restructure.

---

*Keep this file in sync with the actual repo. If the tree changes, update this document in the same PR — don't let them drift.*
