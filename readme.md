<div align="center">

# LifeLink

**Smart health monitoring, always on.**

A Flutter health-monitoring app with a glass, iOS-inspired interface: live vitals,
AI health insights, fall detection, and one-tap emergency SOS. Built mock-first,
so it runs end-to-end with no backend, and swaps to Supabase + Gemini from a single
config file.

</div>

---

## Overview

LifeLink pairs with an ESP32 wearable that streams heart rate, blood-oxygen (SpO2),
motion, and GPS. On top of live monitoring it layers AI analysis (vitals + medical
reports), fall detection, and emergency alerts.

This build is a ground-up rewrite focused on a distinctive, professional interface —
a deep navy-to-frost palette, real backdrop-blur glassmorphism, hand-drawn iconography,
and motion instead of emoji. Every backend is behind a clean interface with a working
mock implementation, so the whole app is usable immediately and becomes "real" by
filling in credentials.

## Features

| Feature | Description |
|--------|-------------|
| Real-time vitals | Live heart rate and SpO2 with animated gauges and trend sparklines |
| Live location | Wearer position on an animated radar panel (no map key required) |
| AI vitals analysis | On-demand plain-language reading of current vitals, with text-to-speech |
| AI health reports | Upload a PDF and get a summary in English, Hindi, Marathi, or Kannada — TTS + PDF export |
| Fall detection | Full-screen alert with an auto-SOS countdown |
| Emergency SOS | Press-and-hold to alert your emergency contact with live location |
| Health analytics | Heart-rate and SpO2 line charts plus weekly trend bars (fl_chart) |
| Medication reminders | Once / daily / weekly schedules with next-due surfacing |
| Health profile | Age, gender, height, weight, BMI, blood group, emergency contact |
| Notification centre | In-app alerts for vitals, reminders, falls, SOS, and reports |

## Design system

- **Palette** — a single navy-to-frost ramp: `#021024`, `#052659`, `#5483B3`, `#7DA0CA`, `#C1E8FF`.
  Restrained safety accents (teal / amber / coral) appear only for critical states.
- **Glassmorphism** — real `BackdropFilter` blur, hairline strokes, top-light sheen, depth shadows.
- **Motion, not emoji** — drifting background orbs, spring-press feedback, animated rings,
  radar sweep, heartbeat pulses, and staggered screen entrances. No emoji anywhere.
- **Typography** — Manrope, tuned for a clean iOS feel.

## Tech stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x (Dart 3) |
| State | `provider` |
| Backend (optional) | Supabase (Auth, Postgres, Realtime) |
| AI (optional) | Google Gemini via a Supabase Edge Function proxy |
| Charts | `fl_chart` |
| Speech | `flutter_tts` |
| Files / PDF | `file_picker`, `pdf`, `printing` |
| Local storage | `shared_preferences` |

## Architecture

Everything the app talks to is an interface with two implementations — a **mock**
(default) and a **real** one — chosen in one place, `lib/services/service_locator.dart`,
based on flags in `lib/core/app_config.dart`.

```
UI (screens) -> Providers (ChangeNotifier) -> Services (interfaces)
                                               ├─ Mock*  (default, no network)
                                               └─ Supabase* / Gemini (flag-gated)
```

- `SensorSource` — live vitals. `MockSensorSource` streams believable random-walk
  data; `SupabaseSensorSource` subscribes to your sensor table via Realtime.
- `AiService` — `MockAiService` (context-aware, localized) or `GeminiAiService`.
- Repositories — Profile, Reminder, Notification, Report, Emergency (SharedPreferences
  mock vs Supabase).

Because it is mock-first, the app is fully explorable before any credentials exist.

## Getting started

Prerequisites: Flutter SDK (Dart 3), and Chrome or an Android device/emulator.

```bash
flutter pub get

# Web (fastest way to see the glass UI)
flutter run -d chrome

# Android
flutter run
```

**Demo login:** any email and any password of 4+ characters. The pre-filled
`demo@lifelink.health` works out of the box. Try the "Test fall alert" tile on the
dashboard to see the fall/SOS flow.

## Connecting a backend

The app ships in mock mode. To go live, see **[docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md)**:

1. Create a Supabase project and run **[supabase/schema.sql](supabase/schema.sql)**
   (recreates the full database and adds the app's reminder/notification tables,
   with RLS and triggers).
2. Paste your URL + anon key into `lib/core/app_config.dart` and flip
   `useSupabaseAppData` to `true`.
3. Optionally point the (separate) sensor project and enable `useSupabaseSensorData`,
   and deploy the Gemini proxy and enable `useGeminiAi`.

Nothing in the app touches your existing sensor database until you opt in.

## Project structure

```
lib/
├── main.dart                 # Providers, theme, routing, auth gate
├── core/                     # app_config (swap points), colors, gradients, theme, routes
├── models/                   # health_data, user_profile, reminder, notification, trend, report, alert
├── services/
│   ├── sensor/               # SensorSource: mock + supabase
│   ├── ai/                   # AiService: mock + gemini
│   ├── data/                 # profile/reminder/notification/report/emergency repositories
│   ├── auth_service.dart     # mock + supabase auth
│   ├── tts_service.dart      # read-aloud
│   └── service_locator.dart  # mock-vs-real wiring
├── providers/                # auth, health, profile, reminder, notification, report, trend, emergency
├── screens/                  # landing, auth, home, analytics, health_report, reminder,
│                             # emergency, fall_alert, notifications, profile, main_shell
└── widgets/                  # glass card/scaffold/nav/controls, vitals visuals, radar, brand mark
supabase/schema.sql           # full database DDL
docs/                         # SUPABASE_SETUP.md, ORIGINAL_SPEC.md
```

---

<div align="center">

Built for health, designed for life.

</div>
