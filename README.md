# Hudle

> **Gather. Plan. Achieve.**

A cross-platform Flutter app for collaborative task management. Built around **Groups** (the central unit), **Tasks** (first-class with priority/status/subtasks/attachments), and **Announcements** (admin-curated, with polls).

## Status

🚧 **Phase 1 — Foundation** scaffolded. See [HUDLE_DEV_BRIEF_V2.md](HUDLE_DEV_BRIEF_V2.md) for the full 12-week roadmap.

| Phase | Status |
|---|---|
| 1. Foundation (theme, auth, router, groups list) | 🟡 Scaffolded |
| 2. Core task engine | ⬜ Pending |
| 3. Announcements & polls | ⬜ Pending |
| 4. Search, notifications, admin | ⬜ Pending |
| 5. Polish & launch | ⬜ Pending |

## Stack

- **Framework:** Flutter (Android + iOS)
- **State:** Riverpod (code-gen)
- **Routing:** go_router
- **Backend:** Supabase (Postgres + Storage + Realtime + RLS)
- **Auth & Push:** Firebase (Google Sign-In + FCM)
- **Architecture:** feature-first

## Getting Started

```bash
# 1. Install Flutter (macOS)
brew install --cask flutter
flutter doctor

# 2. Install dependencies
flutter pub get

# 3. Configure environment
cp .env.example .env
# fill in SUPABASE_URL, SUPABASE_ANON_KEY, etc.

# 4. Generate Riverpod / Freezed code
dart run build_runner build --delete-conflicting-outputs

# 5. Run
flutter run
```

## Project Structure

```
lib/
├── main.dart              # Entry, Supabase + Firebase init
├── app.dart               # MaterialApp.router
├── core/
│   ├── constants/         # Colors, UI tokens, env
│   ├── theme/             # Ember & Ink theme + typography
│   ├── router/            # go_router with auth guards
│   ├── services/          # Supabase, notifications
│   └── widgets/           # PriorityBadge, HudleButton, AvatarStack, ...
└── features/
    ├── auth/              # Login, signup, profile setup
    ├── groups/            # List, detail, settings
    ├── tasks/             # Board, detail, create/edit
    ├── announcements/     # Feed, approval queue
    ├── dashboard/         # Aggregated home
    ├── calendar/          # Monthly/weekly views
    ├── search/            # Full-text search
    └── notifications/     # In-app notification centre
```

## Theme — Ember & Ink

Burnt orange embers over deep ink surfaces.
- **Primary:** `#E8612C` (Ember Orange)
- **Accent:** `#F59E3A` (Amber Gold)
- **Base:** `#1A1A2E` (Deep Ink Navy)

## License

Private — all rights reserved.
