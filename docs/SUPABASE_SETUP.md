# Supabase setup

The app runs fully on **mock data** with zero setup. Follow this only when you
want to connect a real backend. Nothing here touches your existing sensor
database — the app uses its own project(s).

## 0. Two projects, on purpose

| Project | Holds | App flag |
|---|---|---|
| **App project** | `users`, `reports`, `medication_reminders`, `notifications`, `emergency_alerts`, `weekly_trends` | `useSupabaseAppData` |
| **Sensor project** (your existing one) | `sensor_logs` / `device_readings` / `device_sensor_data` / `fall_events` | `useSupabaseSensorData` |

You can also point both at the **same** project if you prefer — just reuse the
same URL/key in both places in `lib/core/app_config.dart`.

## 1. Create the app project

1. Go to <https://supabase.com/dashboard> → **New project**. Pick a name, a
   strong database password, and a region close to you.
2. Wait for it to finish provisioning (~2 min).

## 2. Create the schema

1. Open **SQL Editor** → **New query**.
2. Paste the entire contents of [`../supabase/schema.sql`](../supabase/schema.sql)
   and click **Run**. It is idempotent, so re-running it is safe.
3. Under **Table editor** you should now see all ten tables.

## 3. Turn on email auth

1. **Authentication → Providers → Email**: enable it.
2. For quick testing, **Authentication → Providers → Email → Confirm email**:
   turn **off** email confirmation so signups log in immediately.

## 4. Copy your keys

**Project settings → API**:

- **Project URL** → `supabaseUrl`
- **anon public** key → `supabaseAnonKey`

(The `anon` key is public and safe to ship; Row Level Security protects the
data. Never put the **service_role** key in the app.)

## 5. Wire it into the app

Open `lib/core/app_config.dart` and edit the top section:

```dart
static const bool useSupabaseAppData = true;            // <- was false
static const String supabaseUrl     = 'https://xxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOi...';
```

Hot-restart. Signup/login, profile, reminders, reports and notifications now
persist to Supabase.

## 6. (Optional) Connect the live sensor stream

Point the sensor section at your **existing** project and flip its flag:

```dart
static const bool useSupabaseSensorData = true;
static const String sensorSupabaseUrl     = 'https://your-sensor.supabase.co';
static const String sensorSupabaseAnonKey = 'eyJhbGciOi...';
static const String sensorTable           = 'sensor_logs'; // or device_readings
```

The app subscribes to the newest row via Supabase Realtime. Make sure Realtime
is enabled for that table (**Database → Replication**).

## 7. (Optional) Gemini AI, key kept off the device

Recommended: deploy an Edge Function proxy so the Gemini key never ships.

```bash
supabase functions deploy gemini-proxy
supabase secrets set GEMINI_API_KEY=your_gemini_key
```

Then set in `app_config.dart`:

```dart
static const bool useGeminiAi   = true;
static const String geminiProxyUrl = 'https://<project>.functions.supabase.co/gemini-proxy';
```

Until then, the app returns clearly-labelled mock AI summaries so every screen
still works.
