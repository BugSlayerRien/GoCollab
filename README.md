# GoCollab

**GoCollab** is a production-oriented Flutter mobile application built exclusively for **Google Developer Groups on Campus (GDGoC) Philippines**. It centralizes community management - announcements, career opportunities, event management, member engagement analytics, and partnership management - into a single, role-aware Material Design 3 experience.

This project aligns with **SDG 17 - Partnerships for the Goals**, using technology to strengthen collaboration between the student community, its officers, and external partner organizations.

 Built with Flutter + Riverpod on the client and Supabase (PostgreSQL, Auth, Storage, Realtime) on the backend, following Clean Architecture and the Repository pattern throughout.

----------------

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
10. [GitHub REST API Integration](#github-rest-api-integration)
11. [Google Calendar API Integration](#google-calendar-api-integration)
12. [Running the App](#running-the-app)
12. [Testing & Static Analysis](#testing--static-analysis)
13. [Building for Release](#building-for-release)
14. [Roles & Promoting an Officer](#roles--promoting-an-officer)
15. [Known Limitations](#known-limitations)

-------

## Feature Overview

| Module | Members | Officers |
|---|---|---|
| **Authentication** | Email/password + Google Sign-In, forgot password | Same |
| **Dashboard** | Announcements, upcoming events, saved opportunities, community stats, quick actions | Officer-specific quick actions + summary stats |
| **Career Hub** | Browse/filter internships, scholarships, certifications, hackathons; bookmark; deadline reminders | Create/manage opportunity postings |
| **Events** | List, detail, register/cancel, QR ticket, **My Calendar** (live Google Calendar), calendar sync, venue map | QR check-in scanner, attendance validation |
| **Community Analytics** | — | Active members, attendance, engagement, event performance, growth charts (`fl_chart`) |
| **Partnership Management** | — | Partner directory, sponsorship tracking, meeting schedule, communication logs, collaboration status |
| **Community Announcements** | Feed with category badges, push notifications | Publish/pin announcements |
| **Notifications inbox** | Realtime in-app feed (announcements, event reminders, registrations, career opportunities, partnership updates), pulsing unread badge, mark-as-read | Same |
| **Profile** | Personal info, skills, GitHub stats, certificates, event history, saved opportunities | Same |

## Tech Stack

- **Frontend:** Flutter (stable channel, Dart ≥ 3.9), Material Design 3, [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) for state management, [`go_router`](https://pub.dev/packages/go_router) for declarative/role-based navigation.
- **Backend:** [Supabase](https://supabase.com) — PostgreSQL, GoTrue Auth, Storage, and Realtime (the in-app notifications inbox streams live via `.stream()` on the `notifications` table) — accessed through `supabase_flutter`.
- **Integrations:** Google Sign-In (`google_sign_in`), Google Calendar API v3 (REST via `http` — GET/POST/PATCH/DELETE for event sync), Firebase Cloud Messaging (`firebase_messaging` + `flutter_local_notifications`), in-app maps via OpenStreetMap (`flutter_map`), device calendar sync (`add_2_calendar`), QR scanning (`mobile_scanner`) and generation (`qr_flutter`), charts (`fl_chart`).
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
│   ├── config/env.dart            # Build-time config (Supabase URL/key, OAuth id, FCM sender id)
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
    ├── events/                    # list, detail, registration, QR check-in, calendar sync, venue map
    ├── calendar/                  # My Calendar: live Google Calendar GET + table_calendar UI
    ├── announcements/ + community/ # announcements feed + officer publish sheet
    ├── analytics/                 # officer-only charts (growth, event performance)
    ├── partnerships/              # partner directory, sponsorships, meetings, communications
    ├── profile/                   # personal info, skills, GitHub stats, event history
    └── notifications/             # in-app notification inbox, live via Supabase Realtime, pulsing unread badge
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

### Architecture & ERD Documentation

Full system architecture diagrams, flowcharts, ERD, and table reference are in [`docs/`](docs/):

| File | Description |
|---|---|
| [`GoCollab-Architecture-and-Schema.pdf`](docs/GoCollab-Architecture-and-Schema.pdf) | Printable PDF (diagrams + schema tables) |
| [`GoCollab-Architecture-and-Schema.html`](docs/GoCollab-Architecture-and-Schema.html) | Self-contained HTML with Mermaid diagrams |
| [`GoCollab-Architecture-and-Schema.md`](docs/GoCollab-Architecture-and-Schema.md) | Markdown source (GitHub renders Mermaid) |

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
     "FIREBASE_SENDER_ID": ""
   }
   ```

   `env.json` is gitignored. The Supabase URL/publishable key already default to the live GoCollab project (a publishable/anon key is safe to ship — every table is protected by RLS), so **the app builds and runs out of the box** even if you leave the rest blank. Google Sign-In degrades gracefully (friendly "not configured" state, see [`Env.hasGoogleSignIn`](lib/core/config/env.dart)) instead of crashing when the client id is empty. Event and partner maps use OpenStreetMap in-app (`flutter_map`) from latitude/longitude stored in Supabase; no Maps API key is required. Tapping a preview opens the same coordinates in Google Maps / the browser.

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

## GitHub REST API Integration

GoCollab loads public GitHub profile data over HTTP (no GitHub OAuth app or API key).

| Item | Detail |
|---|---|
| **API** | [GitHub REST API](https://docs.github.com/en/rest/users/users) |
| **Endpoint** | `GET https://api.github.com/users/{username}` |
| **HTTP method** | GET only (this endpoint does not use POST) |
| **Client** | `package:http` in [`lib/features/profile/data/datasources/github_datasource.dart`](lib/features/profile/data/datasources/github_datasource.dart) |
| **JSON fields** | `login`, `name`, `avatar_url`, `bio`, `public_repos`, `followers`, `following`, `html_url` |
| **Parsing** | `GithubStats.fromGithubJson` in [`lib/features/profile/domain/entities/github_stats.dart`](lib/features/profile/domain/entities/github_stats.dart) |
| **UI** | Profile tab — avatar, name, bio, repo/follower/following counts, link to GitHub |
| **Cache** | Successful responses are stored in Supabase `github_profiles` so later opens do not re-hit GitHub until the user taps refresh |

**Flow:** Edit Profile → save a GitHub username → `http.get` → parse JSON → Riverpod invalidates `cachedGithubProfileProvider` → Profile card updates. Opening Profile with a username and no cache also triggers a live GET.

**Error handling:** invalid username format, HTTP 404 (user not found), 403 (rate limit), non-200, invalid JSON, timeout, and network failures. The Profile card shows a spinner while loading and a retry/snackbar on failure.

## Google Calendar API Integration

GoCollab integrates the **Google Calendar API v3** to allow members to synchronize community events with their personal Google Calendar. This is a real, production-quality integration using the official REST API — not a mock or simulated implementation.

| Item | Detail |
|---|---|
| **API** | [Google Calendar API v3](https://developers.google.com/calendar/api/v3/reference) |
| **Base URL** | `https://www.googleapis.com/calendar/v3` |
| **Authentication** | OAuth 2.0 via Supabase Google sign-in with `calendar.events` scope; tokens cached in `GoogleTokenStorage` |
| **Client** | `package:http` in [`lib/core/services/google_calendar_service.dart`](lib/core/services/google_calendar_service.dart) |

### HTTP Methods Implemented

| Method | Endpoint | Purpose |
|---|---|---|
| **GET** | `/calendars/primary/events/{eventId}` | Check if a synced event still exists on the user's Google Calendar |
| **GET** | `/calendars/primary/events?timeMin=...&timeMax=...&orderBy=startTime&singleEvents=true` | **My Calendar** — list events in a date range for the calendar screen |
| **GET** | `/calendars/primary/events?timeMin=...&orderBy=startTime` | List upcoming events (legacy helper, 90-day window) |
| **POST** | `/calendars/primary/events` | Create a new Google Calendar event when the user taps "Add to Google Calendar" |
| **PATCH** | `/calendars/primary/events/{eventId}` | Update the calendar event when GoCollab event details change |
| **DELETE** | `/calendars/primary/events/{eventId}` | Remove the calendar event when the user taps "Remove" |

### Architecture

```
Event Detail Screen — Add/Update/Remove (UI)
  → GcalActionsController (Riverpod StateNotifier)
    → GcalRepository (orchestrates API + DB)
      → GoogleCalendarService (REST API client — GET/POST/PATCH/DELETE)
      → GcalDataSource (Supabase gcal_event_sync table — stores event ID mapping)

My Calendar Screen (UI)
  → myCalendarEventsProvider (Riverpod FutureProvider)
    → MyCalendarRepository
      → MyCalendarRemoteDataSource
        → GoogleCalendarService.listEventsInRange (GET primary/events)
        → GcalDataSource.listUserGcalMappings (GoCollab vs personal detection)
```

### My Calendar Screen

The **My Calendar** screen (`/my-calendar`) displays the authenticated user's **live** Google Calendar data — no mock or hardcoded events.

| Item | Detail |
|---|---|
| **Route** | `/my-calendar` (Home quick action, Events app-bar icon) |
| **HTTP** | `GET https://www.googleapis.com/calendar/v3/calendars/primary/events` |
| **Query params** | `timeMin`, `timeMax` (focused month), `singleEvents=true`, `orderBy=startTime`, `maxResults=250` |
| **Auth** | Reuses `GoogleCalendarService` token resolution (Supabase `providerToken` + `GoogleTokenStorage`) |
| **UI** | [`table_calendar`](https://pub.dev/packages/table_calendar) month grid + day event list |
| **GoCollab badge** | Events synced via `gcal_event_sync` or whose description contains `GoCollab Event` show a blue **GoCollab** label; tapping opens the GoCollab event detail when mapped |

**JSON fields parsed** (per item in `items[]`):

| Field | Dart model |
|---|---|
| `id` | `GoogleCalendarEvent.id` |
| `summary` | `GoogleCalendarEvent.title` |
| `start.dateTime` / `start.date` | `GoogleCalendarEvent.startAt`, `isAllDay` |
| `end.dateTime` / `end.date` | `GoogleCalendarEvent.endAt` |
| `location` | `GoogleCalendarEvent.location` |
| `description` | Used to detect GoCollab-created entries |

**UI states:** loading spinner, connect-calendar prompt (missing OAuth token), network/API error with retry, empty day list, populated day list with title / time / location.

### Event sync (Add to Google Calendar)

- **Add to Google Calendar**: When a member is registered for an event, a sync card appears with an "Add to Google Calendar" button. Creates the event via POST and stores the mapping.
- **Sync status indicator**: The card shows whether the event is already synced (green checkmark) or not.
- **Update**: If event details change, the user can tap "Update" to PATCH the calendar event.
- **Remove**: Tap "Remove" to DELETE the calendar event (with confirmation dialog). Keeps the GoCollab registration.
- **Duplicate prevention**: Before creating, checks the mapping table and verifies the event still exists on Google Calendar (GET). Prevents duplicate entries.
- **Optional**: Calendar access is entirely optional. GoCollab works fully without it. Users who deny calendar permission see a graceful error.

### Error Handling

- Authentication errors (denied/expired OAuth) — user is prompted to sign in again
- HTTP 401 — automatic sign-out and retry prompt
- HTTP 404 — stale mapping cleaned up automatically
- Network errors — surfaced via snackbar
- API errors — status code + response body logged, user-friendly message shown
- Loading states — spinner on all async operations

### Setup

1. Enable the **Google Calendar API** in [Google Cloud Console](https://console.cloud.google.com/apis/library/calendar-json.googleapis.com) for your project.
2. The same OAuth Client ID used for Google Sign-In is reused by the `google_sign_in` package for calendar scope.
3. Apply the migration `supabase/migrations/20260819190000_gcal_sync.sql` to create the `gcal_event_sync` table.
4. No additional environment variables are needed beyond `GOOGLE_WEB_CLIENT_ID`.

### Database Table

The `gcal_event_sync` table stores the per-user mapping:

```sql
gcal_event_sync (
  user_id   uuid  → auth.users(id),
  event_id  uuid  → events(id),
  gcal_event_id text,
  synced_at timestamptz,
  UNIQUE (user_id, event_id)
)
```

Row Level Security ensures each user can only access their own mappings.

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
- Google Sign-In and FCM degrade gracefully but require the external setup steps above for full functionality.
- Android release builds sign with the debug keystore by default (see [Building for Release](#building-for-release)).


