
# Project Blueprint: inCar

## Overview

**Purpose:** This document outlines the architecture, features, and implementation plan for the "inCar" Flutter application. inCar is a ride-sharing app with real-time features, user authentication, and separate Firebase projects for passengers and drivers.

**Target Platform:** Android

## Core Features & Style

### Implemented Features:
- **Multi-Project Firebase Integration:** Connects to separate Firebase projects for passengers and drivers.
- **Google Maps Integration:** Configured for Google Maps on Android with a custom dark theme.
- **Dependencies:** `google_maps_flutter`, `firebase_auth`, `cloud_firestore`, `google_fonts`, `geocoding`, `location`, `http`.
- **Services:**
  - **`AuthService`:** Manages all user authentication logic.
  - **`FirestoreService`:** Handles data interactions, including fetching vehicle types, creating ride requests, and managing ride status.
  - **`LocationService`:** Manages device location permissions and retrieval.
  - **`DirectionsService`:** Calls the Google Directions API to calculate route distances.
  - **`LocationSharingService`:** A dedicated service for the driver app to periodically send location updates to Firestore.
- **Firebase Integration:**
  - **Authentication:** An `AuthWrapper` in `main.dart` handles automatic navigation based on login state.
  - **Firestore:** The app reads `vehicletypes` and creates/updates `rides` and `drivers_locations` documents.
- **UI Components:**
  - **Splash Screen, Auth Screen, Home Screen:** Core navigation and user authentication flow.
  - **Map Screen (Passenger):**
    - An advanced map interface for location selection.
    - **Real-time Driver Tracking:** Once a ride is accepted, the screen listens for the assigned driver's location and displays their car icon moving in real-time on the map.
  - **VehicleSelector Widget:** A bottom sheet panel for passengers to choose a vehicle and see estimated fares.
  - **RideRequestsScreen (Driver):**
    - **Listens in real-time** for pending rides.
    - **Optimized Query:** Fetches only the last 20 pending rides, sorted by creation time.
    - **Background Location Sharing:** Automatically starts sharing the driver's location every 15 seconds when this screen is active and stops when it's closed, ensuring battery efficiency.
- **Ride Lifecycle & Real-Time Features:**
  - **Passenger:** Creates a ride request. Once the ride is accepted, their map screen transitions to a tracking view, showing the driver's approach.
  - **Driver:** Views pending rides, accepts one, and automatically starts broadcasting their location for the passenger to see.
  - **Automatic Listener Management:** The app uses `StreamBuilder` and manual `StreamSubscription` cancellation in `dispose()` methods to ensure efficient, leak-free real-time updates.

### Style & Design:
- **Global Theme:** A consistent dark theme (`#000000` background, `#BEF574` accent) is applied app-wide.
- **Typography:** Uses the **Poppins** font via `google_fonts`.
- **Custom Icons:** A custom car icon (`assets/images/car_icon.png`) is used as a map marker for the driver's vehicle.
- **Animations & UI:** Uses modern components like `StreamBuilder`, `ModalBottomSheet`, and `Marker` updates for a dynamic and interactive user experience.

## Current Plan

**Request:** Implement real-time location sharing for drivers and tracking for passengers.

**Steps Completed:**

**Part 1: Driver - Location Sharing**
1.  **Create `LocationSharingService`:**
    - Built a new service (`lib/services/location_sharing_service.dart`).
    - It uses a `Timer.periodic` to send the driver's current coordinates to the `drivers_locations/{driverId}` document in Firestore every 15 seconds.
2.  **Integrate into Driver UI:**
    - Converted `RideRequestsScreen` into a `StatefulWidget`.
    - In `initState`, the `LocationSharingService` is started.
    - In `dispose`, the service is stopped to conserve battery, ensuring location is only shared when the driver is actively looking for rides.

**Part 2: Passenger - Driver Tracking**
1.  **Enhance `FirestoreService`:**
    - Added a `getRideStream(String rideId)` method to listen to real-time changes on a single ride document.
2.  **Major `MapScreen` Overhaul:**
    - Converted the screen to handle complex state, including the current `rideId` and multiple `StreamSubscription`s.
    - Implemented a simulated flow: when a ride is created via the `VehicleSelector`, the `MapScreen` starts listening to that ride's document.
    - **Chained Subscriptions:** When the `ride` document updates with a `driverId`, the screen automatically cancels the ride subscription and starts a new subscription to the driver's location using `getDriverLocationStream()`.
    - **Visual Feedback:** A `Marker` with a custom car icon is added to the map. The `_updateDriverMarker` method moves this marker smoothly to reflect the driver's live position.
3.  **Update `VehicleSelector`:** Modified the widget to accept the pre-generated `rideId` from the `MapScreen` to ensure data consistency.
4.  **Update Blueprint:** Documented the entire real-time location sharing and tracking feature, from the driver's background updates to the passenger's live map view.

