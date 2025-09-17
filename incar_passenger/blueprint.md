# inCar - Project Blueprint

## Overview

This document outlines the architecture, features, and design of the **inCar** ecosystem, a mobile ride-sharing service inspired by platforms like inDrive and Bolt. The ecosystem consists of two distinct Flutter applications:

*   **inCar Passenger**: For users to request and track rides.
*   **inCar Driver**: For drivers to accept and manage rides.

Both applications are built for **Android**, connected to a unified **Firebase** backend, and share a consistent "premium dark" design aesthetic.

## Core Technical Stack

*   **Platform**: Flutter for Android
*   **Backend**:
    *   **Authentication**: Firebase Authentication (Phone OTP)
    *   **Database**:
        *   Cloud Firestore: For managing user profiles, ride requests (`ride_requests`), and ride history.
        *   Realtime Database: For high-frequency location updates (driver tracking).
*   **Mapping & Geolocation**:
    *   `google_maps_flutter`: For displaying maps.
    *   `location`: For accessing device location.
    *   `geocoding`: For reverse geocoding (address lookup from coordinates).
*   **Networking**: `http` for communication with Google Maps APIs (Directions, etc.).
*   **Design**:
    *   **Theme**: Premium Dark (Black background, Pistachio accents).
    *   **Typography**: Clean and modern, using the `google_fonts` package.

## Application: inCar Passenger (`com.incar.passenger`)

### Current Plan: Initial Project Setup

The goal for this initial phase is to establish the foundational structure of the **inCar Passenger** application.

### Steps for Current Request

1.  **Project Creation**:
    *   [x] Create a new Flutter project named `incar_passenger`.
    *   [x] Configure for Android only (`com.incar.passenger`).
2.  **Initial Configuration**:
    *   [ ] Configure `build.gradle` for optimized Android builds (`minSdkVersion 21`, `multiDexEnabled true`).
    *   [ ] Set up the Firebase project and connect the Android app.
    *   [ ] Define the premium dark theme with pistachio accents.
3.  **Dependency Installation**:
    *   [ ] Add core packages to `pubspec.yaml`:
        *   `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_database`
        *   `google_maps_flutter`, `location`, `geocoding`, `http`
        *   `google_fonts`

### Implemented Features (as of now)

*   **Project Scaffolding**: The basic Flutter project structure for `inCar Passenger` has been created.
