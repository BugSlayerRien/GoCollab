# GoCollab

**GoCollab** is a production-oriented Flutter mobile application built exclusively for **Google Developer Groups on Campus (GDGoC) Philippines**. It centralizes community management — announcements, career opportunities, event management, member engagement analytics, and partnership management — into a single, role-aware Material Design 3 experience.

This project aligns with **SDG 17 – Partnerships for the Goals**, using technology to strengthen collaboration between the student community, its officers, and external partner organizations.

> Individual capstone project. Built with Flutter + Riverpod on the client and Supabase (PostgreSQL, Auth, Storage, Realtime) on the backend, following Clean Architecture and the Repository pattern throughout.

---

## Table of Contents

1. [Feature Overview](#feature-overview)
2. [Tech Stack](#tech-stack)
3. [Architecture](#architecture)
4. [Project Structure](#project-structure)
5. [Database Schema](#database-schema)
6. [Getting Started](#getting-started)
7. [Environment Configuration](#environment-configuration)
8. [Firebase Cloud Messaging Setup](#firebase-cloud-messaging-setup)
9. [Google Sign-In Setup](#google-sign-in-setup)
10. [Google Maps Setup](#google-maps-setup)
11. [Running the App](#running-the-app)
12. [Testing & Static Analysis](#testing--static-analysis)
13. [Building for Release](#building-for-release)
14. [Roles & Promoting an Officer](#roles--promoting-an-officer)
15. [Known Limitations](#known-limitations)

---

## Feature Overview

| Module | Members | Officers |
|---|---|---|
| **Authentication** | Email/password + Google Sign-In, forgot password | Same |
| **Dashboard** | Announcements, upcoming events, saved opportunities, community stats, quick actions | Officer-specific quick actions + summary stats |
| **Career Hub** | Browse/filter internships, scholarships, certifications, hackathons; bookmark; deadline reminders | Create/manage opportunity postings |
| **Events** | List, detail, register/cancel, QR ticket, calendar sync, venue map | QR check-in scanner, attendance validation |
| **Community Analytics** | — | Active members, attendance, engagement, event performance, growth charts (`fl_chart`) |
| **Partnership Management** | — | Partner directory, sponsorship tracking, meeting schedule, communication logs, collaboration status |
| **Community Announcements** | Feed with category badges, push notifications | Publish/pin announcements |
| **Profile** | Personal info, skills, GitHub stats, certificates, event history, saved opportunities | Same |

## Tech Stack

- **Frontend:** Flutter (stable channel, Dart ≥ 3.9), Material Design 3, [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) for state management, [`go_router`](https://pub.dev/packages/go_router) for declarative/role-based navigation.
- **Backend:** [Supabase](https://supabase.com) — PostgreSQL, GoTrue Auth, Storage, Realtime — accessed through `supabase_flutter`.
- **Integrations:** Google Sign-In (`google_sign_in`), Firebase Cloud Messaging (`firebase_messaging` + `flutter_local_notifications`), Google Maps (`google_maps_flutter`), device calendar sync (`add_2_calendar`), QR scanning (`mobile_scanner`) and generation (`qr_flutter`), charts (`fl_chart`).
- **Architecture:** Clean Architecture (`presentation` / `domain` / `data`) + Repository Pattern per feature, a shared `core/` layer for cross-cutting concerns, and an explicit `Result<T>`/`Failure` type for error handling instead of throwing across layers.

## Architecture

Every feature under `lib/features/<feature>/` is split into three layers so business logic never lives inside widgets:

```
presentation/   Screens, widgets, Riverpod providers/controllers (UI state only)
domain/         Entities, abstract repository interfaces, use cases (pure Dart, no Supabase imports)
data/           Models (Supabase row ↔ entity mapping), remote data sources, repository implementations
```

Dependency direction always points inward: `presentation → domain ← data`. The `domain` layer defines a repository *interface*; the `data` layer implements it against Supabase; Riverpod providers (in `presentation/providers`) wire the concrete implementation in and expose it to the UI. Swapping Supabase for another backend later only touches the `data` layer.

Cross-cutting code lives in `lib/core/`:

- `core/config` – `Env` (build-time configuration via `--dart-define`)
- `core/theme` – MD3 `ThemeData`, GoCollab color palette, typography, spacing scale
- `core/animations` – native (no GIF/Lottie) prismatic motion widgets: flowing gradient background, shimmer, glow border, loader
- `core/errors` – `Failure` hierarchy + `exception_mapper.dart` (Supabase/Postgrest exceptions → domain failures)
- `core/utils` – `Result<T>`, form `Validators`, `DateFormatter`
- `core/widgets` – shared `AppButton`, `AppTextField`, `StatusBadge`, `EmptyState`, `SectionHeader`
- `core/services` – `SupabaseService`, `NotificationService`, `CalendarService`
- `core/di` – Supabase client / auth-state Riverpod providers
- `core/router` – `go_router` configuration with auth + role-based redirects

## Project Structure

```
lib/
├── main.dart                      # Supabase + notification bootstrap, MaterialApp.router
├── core/
│   ├── animations/                # PrismaticBackground, PrismaticShimmer, PrismaticGlowBorder, PrismaticLoader
│   ├── config/env.dart            # Build-time config (Supabase URL/key, OAuth id, Maps key, FCM sender id)
│   ├── di/supabase_providers.dart
│   ├── errors/                    # Failure hierarchy + exception_mapper
│   ├── router/app_router.dart     # go_router + auth/role redirects
│   ├── services/                  # SupabaseService, NotificationService, CalendarService
│   ├── theme/                     # app_colors, app_typography, app_spacing, app_theme
│   ├── utils/                     # Result, Validators, DateFormatter
│   └── widgets/                   # AppButton, AppTextField, StatusBadge, EmptyState, SectionHeader
└── features/
    ├── auth/                      # login, register, forgot password, Google Sign-In, role-aware session
    ├── splash/                    # splash screen (prismatic background + session bootstrap)
    ├── shell/                     # role-aware bottom navigation shell (IndexedStack)
    ├── dashboard/                  # member + officer dashboards, community stats
    ├── opportunities/             # Career Hub: list, detail, bookmarking, officer create sheet
    ├── events/                    # list, detail, registration, QR check-in, calendar, venue map
    ├── announcements/ + community/ # announcements feed + officer publish sheet
    ├── analytics/                 # officer-only charts (growth, event performance)
    ├── partnerships/              # partner directory, sponsorships, meetings, communications
    ├── profile/                   # personal info, skills, GitHub stats, event history
    └── notifications/             # in-app notification records (domain scaffold for FCM-delivered items)
```

Each feature folder mirrors the `presentation / domain / data` split described above.

## Database Schema

Schema, RLS policies, and seed data live in `supabase/migrations/` and are applied in order:

| Migration | Purpose |
|---|---|
| `20260723190000_init_schema.sql` | Normalized tables: `roles`, `chapters`, `profiles`, `github_profiles`, `announcements`, `events`, `event_registrations`, `attendance`, `certificates`, `opportunities`, `saved_opportunities`, `partners`, `sponsorships`, `meetings`, `communications`, `engagement_logs`, `notifications` — with FKs, check constraints, indexes, `is_officer()` helper, and a `handle_new_user()` trigger that auto-creates a `profiles` row (defaulting to the `member` role) whenever someone signs up. |
| `20260723191000_rls_policies.sql` | Row Level Security on every table: members can read public content and manage only their own rows (registrations, saved opportunities, profile); officers get elevated read/write access via `is_officer()`. |
| `20260723192000_seed_data.sql` | Sample chapters, opportunities, events, announcements, and partners so the app has real content on first run. |

Apply them against the project referenced in [Environment Configuration](#environment-configuration) using the Supabase CLI:

```bash
supabase link --project-ref nhuoziavgyxtcutmygtl
supabase db push
```

(or paste each file, in order, into the Supabase Dashboard's SQL editor).

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel, Dart ≥ 3.9 — run `flutter --version` to confirm)
- Android Studio (Android SDK + an emulator or device) and/or Xcode (iOS, macOS only)
- A [Supabase](https://supabase.com) project (one is already provisioned for GoCollab — see below)
- Optional, for full functionality: a Firebase project and Google Cloud OAuth/Maps credentials

### Clone & install dependencies

```bash
git clone https://github.com/BugSlayerRien/GoCollab.git
cd GoCollab
flutter pub get
```

## Environment Configuration

GoCollab never hardcodes secrets in source. All runtime configuration is read in [`lib/core/config/env.dart`](lib/core/config/env.dart) via `String.fromEnvironment`, which Flutter populates at **build time** from `--dart-define` flags (or a `--dart-define-from-file` JSON file).

1. Copy the template and fill in anything you have:

   ```bash
   cp env.example.json env.json
   ```

   ```json
   {
     "SUPABASE_URL": "https://nhuoziavgyxtcutmygtl.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_0dTO5gPz68bTVW_2xxrs1A_t7qjZk_r",
     "GOOGLE_WEB_CLIENT_ID": "",
     "GOOGLE_MAPS_API_KEY": "",
     "FIREBASE_SENDER_ID": ""
   }
   ```

   `env.json` is gitignored. The Supabase URL/publishable key already default to the live GoCollab project (a publishable/anon key is safe to ship — every table is protected by RLS), so **the app builds and runs out of the box** even if you leave the rest blank. Google Sign-In and Google Maps degrade gracefully (friendly "not configured" states, see [`Env.hasGoogleSignIn`](lib/core/config/env.dart) / `hasGoogleMaps`) instead of crashing when their keys are empty.

2. Run/build with the file:

   ```bash
   flutter run --dart-define-from-file=env.json
   ```

## Firebase Cloud Messaging Setup

Push notifications (announcements, event reminders, registration confirmations, career opportunities, partnership updates) are scaffolded in [`lib/core/services/notification_service.dart`](lib/core/services/notification_service.dart) and fail gracefully if Firebase isn't configured — the app still builds and runs without it.

To enable FCM:

1. Create a Firebase project and add Android/iOS apps with package name `ph.gdgoc.gocollab.gocollab`.
2. Install the FlutterFire CLI and run `flutterfire configure` from the project root — this generates `lib/firebase_options.dart` and downloads `android/app/google-services.json` / `ios/Runner/GoogleService-Info.plist` (all gitignored; each developer/grader keeps their own).
3. Wire `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` into `NotificationService.initialize()` in place of the current bare `Firebase.initializeApp()` call.
4. Set `FIREBASE_SENDER_ID` in `env.json` for diagnostics.

## Google Sign-In Setup

1. In [Google Cloud Console](https://console.cloud.google.com/apis/credentials), create an **OAuth 2.0 Web Client ID** (used so Supabase can verify the Google ID token server-side).
2. Create matching **Android** and **iOS** OAuth client IDs (with your app's package name / bundle id and SHA-1 signing fingerprint for Android).
3. In the Supabase Dashboard, go to **Authentication → Providers → Google** and paste the Web Client ID + secret.
4. Set `GOOGLE_WEB_CLIENT_ID` (the *Web* client id) in `env.json`.

Until this is configured, the Google Sign-In button on the login/register screens shows a friendly "Google Sign-In isn't configured yet" message instead of crashing.

## Google Maps Setup

Used for event venue previews and the Partner Directory map.

1. Enable **Maps SDK for Android** and **Maps SDK for iOS** in Google Cloud Console and create an API key.
2. Set `GOOGLE_MAPS_API_KEY` in `env.json` **and**:
   - **Android:** add the same key to `android/gradle.properties` as `MAPS_API_KEY=...` (this file is read by `android/app/build.gradle.kts` and injected into `AndroidManifest.xml`'s `com.google.android.geo.API_KEY` meta-data).
   - **iOS:** paste the key into the empty `GMSApiKey` entry in `ios/Runner/Info.plist` — `AppDelegate.swift` reads it at launch and calls `GMSServices.provideAPIKey(...)`.

Without a key, map previews render an inline "map unavailable" fallback rather than crashing.

## Running the App

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

Camera (QR check-in), location (maps), and notification permissions are declared in `AndroidManifest.xml` / `Info.plist` and are requested at the point of use via `permission_handler`.

## Testing & Static Analysis

```bash
flutter analyze   # static analysis — 0 errors/warnings
flutter test      # Validators unit tests + SplashScreen widget test
```

## Building for Release

```bash
# Android App Bundle
flutter build appbundle --dart-define-from-file=env.json

# Android APK
flutter build apk --dart-define-from-file=env.json --split-per-abi

# iOS (requires macOS/Xcode)
flutter build ipa --dart-define-from-file=env.json
```

Android release builds currently sign with the debug keystore (see the `TODO` in `android/app/build.gradle.kts`) so `flutter run --release` works out of the box for grading; swap in a real signing config before a production Play Store release.

## Roles & Promoting an Officer

Every new sign-up is automatically inserted into `public.profiles` with `role_id = 1` (**member**) by the `handle_new_user()` trigger. `go_router`'s redirect logic in [`app_router.dart`](lib/core/router/app_router.dart) sends members and officers to different shells/tabs based on this role.

To promote an account to **Chapter Officer** (`role_id = 2`), run in the Supabase SQL editor:

```sql
update public.profiles set role_id = 2 where email = 'someone@dlsu.edu.ph';
```

## Known Limitations

- Century Gothic is a licensed commercial font and isn't bundled; **Poppins** (Open Font License) is used as a structurally-identical geometric sans-serif substitute. Swapping in a licensed Century Gothic later only requires dropping `.ttf` files into `assets/fonts/` and updating `pubspec.yaml` + `app_typography.dart` — no other code changes.
- Google Sign-In, FCM, and Google Maps all degrade gracefully but require the external setup steps above for full functionality.
- Android release builds sign with the debug keystore by default (see [Building for Release](#building-for-release)).
