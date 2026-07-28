# GoCollab

**GoCollab** is a production-oriented Flutter mobile application built exclusively for **Google Developer Groups on Campus (GDGoC) Philippines**. It centralizes community management - announcements, career opportunities, event management, member engagement analytics, and partnership management - into a single, role-aware Material Design 3 experience.

This project aligns with **SDG 17 - Partnerships for the Goals**, using technology to strengthen collaboration between the student community, its officers, and external partner organizations.

 Built with Flutter + Riverpod on the client and Supabase (PostgreSQL, Auth, Storage, Realtime) on the backend, following Clean Architecture and the Repository pattern throughout.

---

## Table of Contents

1. [Feature Overview](#feature-overview)
2. [Tech Stack](#tech-stack)
3. [Architecture](#architecture)
4. [Project Structure](#project-structure)

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
| **Notifications inbox** | Realtime in-app feed (announcements, event reminders, registrations, career opportunities, partnership updates), pulsing unread badge, mark-as-read | Same |
| **Profile** | Personal info, skills, GitHub stats, certificates, event history, saved opportunities | Same |

## Tech Stack

- **Frontend:** Flutter (stable channel, Dart ≥ 3.9), Material Design 3, [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) for state management, [`go_router`](https://pub.dev/packages/go_router) for declarative/role-based navigation.
- **Backend:** [Supabase](https://supabase.com) — PostgreSQL, GoTrue Auth, Storage, and Realtime (the in-app notifications inbox streams live via `.stream()` on the `notifications` table) — accessed through `supabase_flutter`.
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
    └── notifications/             # in-app notification inbox, live via Supabase Realtime, pulsing unread badge
```

Each feature folder mirrors the `presentation / domain / data` split described above.


