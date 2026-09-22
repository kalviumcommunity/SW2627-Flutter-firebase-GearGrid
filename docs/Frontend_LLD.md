# Low-Level Design (LLD): GearGrid Frontend Architecture

## 1. Module Structure (Frontend Focus)

The Flutter frontend is heavily modularized to prevent monolithic screen files. Complex screens are broken down into granular widgets stored in `lib/widgets/`.

```text
lib/
├── models/
│   ├── equipment.dart
│   ├── booking.dart
│   └── pay_method.dart         # Extracted to prevent circular dependencies
├── screens/
│   ├── landing_screen.dart
│   ├── client_storefront_screen.dart
│   ├── cart_screen.dart
│   └── payment_screen.dart
├── theme/
│   ├── client_theme.dart       # Light & Lime palette for client apps
│   ├── admin_theme.dart        # Dark structured palette for warehouse
│   └── landing_theme.dart      # Custom vibrant orange/lime for marketing
└── widgets/
    ├── landing/                # LandingHero, LandingNavBar, etc.
    ├── storefront/             # StoreHeroBanner, CategoryRail, etc.
    ├── cart/                   # CartItemTile, PriceBreakdownCard, etc.
    └── payment/                # PaymentForm, PaymentMethodTabs, etc.
```

## 2. Theming Engine

To ensure visual consistency and decouple styles from widget logic, GearGrid uses static theme classes.

### 2.1 `ClientTheme`
Used for all authenticated client views (`Storefront`, `Cart`, `Payment`).
- **Surface**: `#F6F4EE`
- **Ink (Text)**: `#0C1710`
- **Accent**: `#C8F135` (Lime)
- **Typography**: Space Grotesk (Headers), Manrope (Body/Labels)

### 2.2 `LandingTheme`
Used exclusively for the unauthenticated `LandingScreen`.
- **Accent**: `#FF6B35` (Vibrant Orange)
- **Lime**: `#C8F135`
- **Typography**: Heavily relies on tracking (letter spacing) adjustments on Space Grotesk for a premium marketing feel.

## 3. Screen Breakdown

### 3.1 Landing Screen (`landing_screen.dart`)
A static marketing page composed of several scrollable slivers and a sticky `AnimatedContainer` navbar.

- **`LandingNavBar`**: Listens to a `ScrollController`. If `offset > 60`, background changes from transparent to solid surface color.
- **`LandingHero`**: Uses two `AnimationController`s. 
  - `_heroFade`: Triggers a staggered slide-up and fade-in on mount.
  - `_floatingCards`: Uses a repeating `Math.sin()` translation to create a continuous floating effect for the live availability cards.
- **`LandingStatRail`**: Uses an `AnimatedBuilder` combined with a `CurvedAnimation` to count up integers (e.g., `0` to `2400+`) over 1600ms on initialization.

### 3.2 Client Storefront (`client_storefront_screen.dart`)
The primary inventory browser.

- **`StorefrontTopBar`**: A pinned header showing user details.
- **`SlotBanner`**: Interactive date-picker for selecting event window. Modifies parent state which propagates to the inventory stream.
- **`CategoryRail`**: Horizontal `ListView` acting as a filter.
- **`EquipmentCatalogCard`**: Grid item. Features a Hero animation transition into the `EquipmentDetailsSheet` and dynamic +/- increment buttons connected to the local cart state.
- **State**: Uses a `StreamBuilder` connected to `FirestoreRepository.watchEquipment()`. Filters the stream output based on the selected `CategoryRail` index.

### 3.3 Cart Screen (`cart_screen.dart`)
The pre-checkout validation page.

- **`CartAppBar`**: Custom header displaying item count.
- **`SlotCard`**: Highlights the selected time window.
- **`CartItemTile`**: List item that supports quantity adjustments and zero-quantity removal (with a confirmation `SnackBar`).
- **`PriceBreakdownCard`**: Performs local client-side calculation:
  - `subtotal = Σ (price * qty)`
  - `fee = platformFee`
  - `tax = (subtotal + fee) * 0.18`
- **`PremiumTextField`**: Highly styled, reused text input for Event Name, Venue, and Maps Link. Controlled by `TextEditingController`s with basic empty-string validation on submission.

### 3.4 Payment Screen (`payment_screen.dart`)
A state-machine driven checkout screen.

- **Phases (`_phaseIdle`, `_phaseProcessing`, `_phaseSuccess`, `_phaseError`)**: The UI switches entirely based on this string/enum state.
- **`PaymentMethodTabs`**: A custom pill-shaped tab bar built using `AnimatedContainer` and `InkWell`. Changes the active index state, which toggles the visibility of the corresponding tab content.
- **`CardPaymentTab`**: Utilizes custom `TextInputFormatter`s:
  - Space insertion after every 4 digits for card numbers.
  - `MM/YY` slash insertion for expiry dates.
  - Length limits via `LengthLimitingTextInputFormatter`.
- **`PaymentSuccessView`**: A full-screen overlay triggered by `_phaseSuccess`. Uses `ScaleTransition` and `FadeTransition` to animate a checkmark, followed by a programmatic `Navigator.pop()` after a delay.

## 4. UI Data Flow

1. **User Action**: User taps `+` on an `EquipmentCatalogCard`.
2. **Local State Update**: The screen's `_cart` map (Map of EquipmentID -> Quantity) is updated via `setState()`.
3. **Derived State**: Total units and floating cart banner visibility are re-evaluated.
4. **Navigation**: User navigates to `CartScreen`, passing the `_cart` map and `DateTime` window as constructor arguments.
5. **Validation**: Before pushing to `PaymentScreen`, `CartScreen` checks if Event Name and Venue `TextEditingController`s are non-empty.
6. **Checkout Execution**: `PaymentScreen` simulates a delay (`Future.delayed`), then triggers `FirestoreRepository.createBooking()`.

## 5. UI Animations & Feedback

To achieve the "premium" feel requested in the PRD, the frontend uses:
- **Micro-interactions**: `InkWell` components are styled with rounded borders to provide tactile ripple effects.
- **Elevations**: Heavy drop shadows (`blurRadius: 28`) on floating elements against clean, flat backgrounds.
- **Transitions**: Native Flutter `Hero` animations are used to smoothly transition equipment images from the catalog grid into bottom sheets and detailed views. 

## 6. Error Handling (Frontend)
- Forms use `ScaffoldMessenger.showSnackBar` for localized, non-blocking validation alerts.
- Firestore stream errors display a fallback `EmptyStateWidget` with a retry icon.
