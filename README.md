# GearGrid Live

GearGrid Live is a Flutter-based Android application for event equipment rental and dispatch management. It is designed around two roles:

- `Client`: browse equipment, prepare booking requests, choose event date and time, and track request status.
- `Admin`: manage inventory, review bookings, approve requests, monitor schedules, and advance dispatch status.

## What Is Included

- A custom visual system with layered gradients, premium glass panels, and a more cinematic event-production look.
- Email/password authentication and persistent role profiles.
- Realtime Cloud Firestore streams for inventory, booking requests, and dispatch status.
- Booking conflict detection that atomically reserves each equipment item for every hour of an approved event window.
- Admin inventory controls for add, edit, remove, and stock adjustment flows.

## Firebase Backend

GearGrid is connected to the Firebase project `geargrid-live-2026-pd37`, with its default Firestore database hosted in `asia-south1` (Mumbai) and delete protection enabled.

- `firebase.json`, `firestore.rules`, and `firestore.indexes.json` define the Firestore deployment.
- `lib/firebase_options.dart` and `android/app/google-services.json` contain the generated Android configuration for this project.
- New accounts are always created with the `client` role. Promote the intended warehouse administrator by changing `users/{uid}.role` to `admin` in the Firebase console. The deployed rules prevent users from promoting themselves.
- In Firebase Console, enable **Authentication > Sign-in method > Email/Password** before creating the first account.
- The first administrator can add inventory through the app. Clients then see the shared collection in realtime.

The Firestore rules and booking index are already deployed. The initial live catalog contains six equipment records. The only manual console step remaining is enabling the Email/Password provider; Firebase requires this one-time activation before it exposes the Authentication configuration API.

## Run The App

```bash
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```

`flutter analyze` and `flutter test` pass in this workspace.
