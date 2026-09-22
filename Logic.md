# Backend Logic Guide: Flutter + Firebase

Welcome! This guide will explain how backend logic works in your Flutter application using Firebase. We'll specifically focus on **Authentication** and **Firestore** (your database), and I will point out exactly where these are located in your `Gear Grid` project codebase.

---

## 1. The Role of the Backend

In a typical Flutter app, the backend is responsible for:
- **Identity Management:** Knowing who the user is (Authentication).
- **Data Persistence:** Saving, updating, and retrieving data reliably (Database/Firestore).
- **Security:** Ensuring users can only access or modify data they are allowed to (Security Rules).

Because you are using **Firebase**, you have a "Backend-as-a-Service". Instead of writing a separate server in Node.js or Python, you interact directly with Firebase's cloud services using the Flutter Firebase SDKs.

---

## 2. Authentication Logic

Authentication is the process of verifying who a user is.

### How it works logically:
1. **Sign-Up/Registration:** The user provides an email and password. Your app sends this to Firebase. Firebase creates a unique User ID (`uid`) and stores the credentials securely.
2. **Sign-In:** The user provides their credentials. Firebase verifies them and returns an auth token.
3. **Auth State Listener:** The app "listens" to changes. If a user signs in, the app automatically redirects them to the main screens. If they log out, they are redirected to the login screen.

### 📍 Where is this in your code?
- **UI & Logic:** `lib/screens/auth_screen.dart`
  - This file contains the stateful widget where users input their credentials (`_emailController`, `_passwordController`).
  - It uses `FirebaseAuth.instance` to register and log the user in.

  **Deep Dive: How the authentication code works:**
  When a user taps the submit button on the authentication screen, the `_submit()` method runs. Here is a breakdown of exactly what your code is doing:

  ```dart
  Future<void> _submit() async {
    // 1. Gather Input: Read the text typed into the text fields
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final displayName = _nameController.text.trim();

    // 2. Validate Input: Make sure the fields are not empty
    if (email.isEmpty || password.isEmpty || (_isRegistering && displayName.isEmpty)) {
      setState(() => _error = 'Complete every field to continue.');
      return;
    }

    // 3. UI State Update: Show a loading spinner by setting _isLoading to true
    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      // 4. Contact Firebase: Send the credentials to the cloud
      if (_isRegistering) {
        // a) Create the user in Firebase Auth
        final cred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        // b) Save their display name to their new profile immediately
        await cred.user?.updateDisplayName(displayName);
      } else {
        // c) Or simply sign them in if they already have an account
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      // 5. Error Handling: Catch Firebase-specific errors (like "wrong password") and translate them into a readable error for the UI.
      setState(() => _error = _parseError(e.code));
    } catch (e) {
      // Handle any non-Firebase errors
      setState(() => _error = 'An unexpected error occurred.');
    } finally {
      // 6. Cleanup: Stop the loading spinner whether the request succeeded or failed
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  ```

- **App Wrapper (State Listener):** Typically, a file like `lib/app.dart` or `lib/main.dart` will contain a `StreamBuilder` that listens to `FirebaseAuth.instance.authStateChanges()` to decide whether to show the `AuthScreen` or the `HomeScreen`.

---

## 3. Cloud Firestore Logic (Database)

Firestore is a NoSQL, document-oriented database.

### How it works logically:
- **Collections:** Think of these as folders (e.g., `users`, `equipment`, `bookings`).
- **Documents:** Think of these as files inside the folder. Each document contains data represented as key-value pairs (like JSON). For example, a document in the `users` collection will have the user's ID as the document name and store their `email` and `displayName`.
- **CRUD Operations:**
  - **C**reate: Adding a new document.
  - **R**ead: Fetching a single document or streaming a list of documents (real-time updates).
  - **U**pdate: Modifying an existing document.
  - **D**elete: Removing a document.

### 📍 Where is this in your code?
- **Database Logic Center:** `lib/services/firestore_repository.dart`
  - This is a dedicated class `FirestoreRepository` that centralizes all your database calls.
  - It defines references to your collections: `_equipment`, `_bookings`, `_users`, `_reservationSlots`.

  **Deep Dive: How the Firestore code works:**
  Here are two core methods from your repository. One handles streaming data in real-time, and the other handles creating/updating a user document.

  ```dart
  // 1. Streaming Real-Time Data (Read)
  Stream<AppUser?> watchUser(String userId) {
    // We target the specific user's document inside the '_users' collection.
    // .snapshots() creates a real-time stream. Every time the data changes in the cloud,
    // this stream automatically emits the new data to your app.
    return _users.doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      // We convert the raw JSON (Map) into a strongly typed Dart object (AppUser)
      return data == null ? null : AppUser.fromMap(snapshot.id, data);
    });
  }

  // 2. Creating or Updating Data (Create/Update)
  Future<void> ensureUserProfile(User user) async {
    final displayName = user.displayName?.trim();
    // Point to the specific document using the user's unique ID
    final userReference = _users.doc(user.uid);
    // Fetch the document once to see if they already have a profile
    final existingProfile = await userReference.get();
    
    // Prepare the data we want to save
    final commonFields = {
      'email': user.email ?? '',
      'displayName': displayName == null || displayName.isEmpty
          ? 'GearGrid client'
          : displayName,
      'updatedAt': FieldValue.serverTimestamp(), // Always use server time!
    };

    // If the profile exists, UPDATE it so we don't overwrite their other data (like role)
    if (existingProfile.exists) {
      final updates = Map<String, dynamic>.from(commonFields);
      // Hardcoded check: if it's the admin email, give them admin privileges
      if (user.email == 'admin@geargrid.app') {
        updates['role'] = AppRole.admin.storageValue;
      }
      await userReference.update(updates);
      return;
    }

    // If the profile DOES NOT exist, CREATE (set) it with default roles and createdAt timestamp
    await userReference.set({
      ...commonFields,
      'role': user.email == 'admin@geargrid.app' 
          ? AppRole.admin.storageValue 
          : AppRole.client.storageValue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. Transactions & Conflict Checks (Complex Updates)
  Future<void> approveBooking(String bookingId) async {
    final bookingRef = _bookings.doc(bookingId);

    // A Transaction ensures that if someone else modifies the data at the exact 
    // same time, the whole operation restarts or fails safely to prevent double-booking.
    await _firestore.runTransaction((transaction) async {
      
      // STEP 1: READ everything first (Transactions require all reads before any writes)
      final bookingSnapshot = await transaction.get(bookingRef);
      final booking = Booking.fromMap(bookingSnapshot.id, bookingSnapshot.data()!);
      
      // Fetch current inventory and slot data...
      // (code omitted for brevity)

      // STEP 2: CONFLICT CHECK (Business Logic)
      // Check if adding the requested units to the currently reserved units 
      // exceeds the total physical units available in inventory.
      if (reserved + entry.value > equipment.totalUnits) {
        // If it does, abort the transaction and throw an error
        throw BookingConflictException(
          '${equipment.name} is no longer available for this event window.',
        );
      }
      
      // STEP 3: WRITE the updates
      // If we made it past the conflict checks, it means we have enough inventory!
      // We can safely save the new reserved slots and update the booking to 'approved'.
      transaction.set(slotReference, {
        // ... slot details
        'reservedUnits': reserved + entry.value,
      });
      
      transaction.update(bookingRef, {
        'status': BookingStatus.approved.name,
      });
    });
  }
  ```
- **Models:** `lib/models/`
  - When fetching data from Firestore, it comes in as a raw `Map<String, dynamic>`. Your app converts this raw data into strongly typed Dart objects (like `AppUser`, `Booking`, `Equipment`) using `fromMap` factory methods.
- **Business Rules (Booking Logic):** `lib/services/booking_engine.dart`
  - This likely handles the specific logic for ensuring items can be booked, checking availability, and returning errors (like the `BookingConflictException` seen in your repository) before saving to Firestore.

---

## 4. Security and Backend Configuration

Even though the code lives in your app, Firebase needs rules to know who is allowed to do what, so malicious users can't just change data directly.

### 📍 Where is this in your code?
- **Security Rules:** `firestore.rules`
  - This file dictates the read/write permissions for your collections. For example, ensuring only logged-in users can book equipment, or a user can only edit their own profile.

  **Deep Dive: How Security Rules work:**
  These rules run on Google's servers. Every time your app tries to read or write data, Firestore checks these rules first. If the rule evaluates to `false`, the request is denied.

  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      
      // 1. Reusable Functions
      // Checks if the user is currently logged into the app
      function signedIn() {
        return request.auth != null;
      }
      
      // Checks if the user is an admin by reading their user document
      function isAdmin() {
        return signedIn() &&
          get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
      }

      // 2. Collection Rules
      
      // Users can only read/edit their OWN profile, but Admins can read anyone's.
      match /users/{userId} {
        allow read: if signedIn() && (request.auth.uid == userId || isAdmin());
        // Logic to prevent normal users from giving themselves admin privileges
        allow create: if signedIn() && request.auth.uid == userId &&
          (request.resource.data.role == 'client' || 
           (request.auth.token.email == 'admin@geargrid.app' && request.resource.data.role == 'admin'));
        allow update: if signedIn() && request.auth.uid == userId &&
          (request.resource.data.role == resource.data.role || 
           (request.auth.token.email == 'admin@geargrid.app' && request.resource.data.role == 'admin'));
      }

      // Anyone logged in can see equipment, but ONLY Admins can add or edit it.
      match /equipment/{equipmentId} {
        allow read: if signedIn();
        allow write: if isAdmin();
      }

      // Users can only see and create their OWN bookings. Admins manage them.
      match /bookings/{bookingId} {
        allow read: if signedIn() && (isAdmin() || resource.data.clientId == request.auth.uid);
        allow create: if signedIn() && request.resource.data.clientId == request.auth.uid &&
          (request.resource.data.status == 'pending' || request.resource.data.status == 'paid');
        allow update, delete: if isAdmin();
      }
    }
  }
  ```
- **Database Indexes:** `firestore.indexes.json`
  - When you perform complex queries (like sorting equipment by price *and* filtering by category), Firestore needs an index. This file defines them.
- **Firebase Initialization:** `lib/firebase_options.dart`
  - This file contains the API keys and project IDs necessary to link your Flutter code to your specific Firebase Cloud project.

---

## 5. How the Frontend Connects to the Backend

Unlike a traditional web app where you might write HTTP requests (using `fetch` or `axios`) to reach your backend, Firebase uses **SDKs (Software Development Kits)** to handle the connection for you.

Here is exactly how your Flutter frontend wires up to the Firebase backend:

### Step 1: Initialization
Before your app can talk to the cloud, it must initialize the connection. You can see this in `lib/app.dart` inside the `_FirebaseBootstrapState`:
```dart
  @override
  void initState() {
    super.initState();
    // This line boots up the Firebase SDK and connects it to your specific Google Cloud project
    // using the keys found in firebase_options.dart
    _firebaseInitialization = Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
```

### Step 2: Direct SDK Calls from the UI
Once initialized, your frontend widgets (like buttons and text fields) don't need to make API calls. They just call the Firebase instances directly. 
For example, when a user clicks the login button in `auth_screen.dart`, your frontend directly commands the backend like this:
```dart
await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
```

### Step 3: Real-Time Listening (The "Gate")
Instead of constantly asking the backend "is the user logged in?", the frontend sets up a listener (a Stream) that reacts instantly when the backend state changes. You can see this in `lib/app.dart` inside the `_AuthGateState`:
```dart
// The frontend listens to this stream
StreamBuilder<User?>(
  stream: FirebaseAuth.instance.authStateChanges(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      // Backend says user is logged in! Show the home screen.
      return const HomeScreen(); 
    } else {
      // Backend says user is logged out! Show the login screen.
      return const AuthScreen(); 
    }
  }
)
```

---

## Summary Map of Your Backend Code

| Feature | Primary File | Purpose |
| :--- | :--- | :--- |
| **Authentication UI & Auth Calls** | `lib/screens/auth_screen.dart` | Sign up, login, text field state. |
| **Firestore Database Service** | `lib/services/firestore_repository.dart` | Reads and writes all data to Firestore. |
| **Data Models** | `lib/models/` | Converts raw database JSON to Dart objects. |
| **Database Security Rules** | `firestore.rules` | Secures your cloud data from unauthorized access. |
| **Database Indexes** | `firestore.indexes.json` | Optimizes complex database queries. |
