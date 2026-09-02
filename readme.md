<div align="center">

# 🩺 LifeLink

**Smart health monitoring, always on.**

Real-time vitals from a wearable ESP32 device, AI-powered health insights, fall detection, and one-tap emergency SOS — all in one Flutter app.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-^3.5.0-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase&logoColor=black)
![Gemini](https://img.shields.io/badge/AI-Gemini%202.5%20Flash-4285F4?logo=google&logoColor=white)
![License](https://img.shields.io/badge/License-Educational-lightgrey)

</div>

---

## 📖 Overview

**LifeLink** is a Flutter mobile application for continuous, real-time health monitoring. It pairs with an **ESP32-based wearable device** that streams biometric data — heart rate, blood-oxygen saturation (SpO₂), motion, and GPS location — to Firebase, where the app consumes it live. On top of raw monitoring, LifeLink layers **AI analysis** (Google Gemini 2.5 Flash) for both live vitals interpretation and medical-report summarization, plus safety features like **automatic fall detection** and **emergency SOS alerts**.

Built as a college / hackathon major project.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| ❤️ **Real-time Vitals** | Live heart rate (BPM) and SpO₂ streamed from the ESP32 via Firebase Realtime Database |
| 🗺️ **Live Location** | GPS coordinates from the wearable plotted on an in-app Google Map |
| 🤖 **AI Vitals Analysis** | Gemini 2.5 Flash interprets current vitals in plain language, with text-to-speech read-aloud |
| 📄 **AI Health Reports** | Upload a PDF medical report and receive a Gemini-generated summary in **English, Hindi, Marathi, or Kannada** — with TTS playback and PDF export |
| 🚨 **Fall Detection** | Automatic alert screen triggered when accelerometer G-force exceeds threshold |
| 🆘 **Emergency SOS** | One-tap alert written to Firebase with the user's emergency contact info |
| 📊 **Health Analytics** | `fl_chart` visualizations of recent heart rate & SpO₂ history and weekly trends |
| 💊 **Medication Reminders** | Schedule once / daily / weekly reminders backed by local push notifications |
| 👤 **Health Profile** | User profile (age, gender, height, weight, BMI, blood group, emergency contact) stored in Firestore |

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.x (Dart `^3.5.0`) |
| **State Management** | `provider` |
| **Authentication** | Firebase Auth |
| **Databases** | Firebase Realtime Database (live sensor data) + Cloud Firestore (profiles) |
| **AI** | Google Gemini 2.5 Flash (`google_generative_ai` + REST) |
| **Charts** | `fl_chart` |
| **Maps** | `google_maps_flutter` |
| **Notifications** | `flutter_local_notifications` |
| **Text-to-Speech** | `flutter_tts` |
| **Files / PDF** | `file_selector`, `pdf`, `open_filex`, `path_provider` |
| **Hardware** | ESP32 + MAX30102 (HR & SpO₂) + MPU6050 (accelerometer) + GPS module |

---

## 📁 Project Structure

```
lib/
├── main.dart               # App entry, MultiProvider + theme setup
├── firebase_options.dart   # Generated Firebase config
├── core/                   # App colors, text styles, routes
├── models/                 # Health data, user profile, notification, weekly trend
├── providers/              # Auth, Health, Profile, History, WeeklyTrend, Notification, Report
├── services/               # firebase_service, auth_service, notification_service
├── screens/
│   ├── landing/            # Onboarding landing screen
│   ├── auth/               # Login / signup (+ auth wrapper)
│   ├── home/               # Dashboard: vitals cards, live map, AI analysis
│   ├── analytics/          # Heart rate & SpO₂ charts
│   ├── health_report/      # AI PDF report summarization
│   ├── reminder/           # Medication reminders
│   ├── emergency/          # Emergency SOS screen
│   ├── fall_alert/         # Fall detection alert screen
│   ├── notifications/      # In-app notifications list
│   ├── profile/            # User health profile
│   └── main_shell.dart     # Bottom-nav shell (Home, Reminder, Analytics, Report, Profile)
└── widgets/                # Reusable UI components
```

---

## 🔌 Data Flow & Firebase Schema

The ESP32 firmware reads sensors and pushes data to Firebase; the app subscribes to real-time streams.

**Realtime Database**
- `/sensorData/{pushKey}` — `{ heartRate, spo2, spo2Valid, timestamp, acceleration: {x, y, z, total}, gps: {latitude, longitude, satellites} }` (app reads the latest / last 20 entries)
- `/sensorData/fall_detected` — fall-detection flag
- `/weekly_trends` — Mon–Sun averages (heart rate, SpO₂, stress, hydration)
- `/emergency_alerts/{pushKey}` — SOS events

**Cloud Firestore**
- `/users/{uid}` — name, email, age, gender, height, weight, bmi, blood_group, emergency_contact

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `^3.5.0`
- A Firebase project (Auth, Realtime Database, Firestore enabled)
- A Google Gemini API key
- (Optional) ESP32 wearable running the LifeLink firmware

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yashpattar09/lifelink.git
   cd lifelink
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Run `flutterfire configure` (regenerates `lib/firebase_options.dart`), or
   - Manually add `android/app/google-services.json` (and iOS `GoogleService-Info.plist`).

4. **Deploy the Gemini proxy** (keeps the Gemini key off the client)
   ```bash
   supabase functions deploy gemini-proxy
   supabase secrets set GEMINI_API_KEY=your_new_gemini_key
   ```
   The Flutter app calls this Edge Function; the key lives only as a Supabase secret.

5. **Add the remaining key**
   - Add your **Google Maps API key** to `android/app/src/main/AndroidManifest.xml` for the live-location map.

6. **Run**
   ```bash
   flutter run
   ```

> 🔒 **Security note:** The Gemini API key is **never** shipped in the app — it lives server-side in the `gemini-proxy` Supabase Edge Function (`supabase/functions/gemini-proxy/`). Never commit real keys. The Supabase `anonKey` in `lib/core/supabase_config.dart` is a public key protected by Row Level Security and is safe to ship.

---

<div align="center">

*Built for health, designed for life.* ❤️

</div>
