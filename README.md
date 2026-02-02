# Japan Festival Boston

This repository contains the full-stack infrastructure for the Official Japan Festival Boston Mobile Application. This system is designed to provide real-time event information to over 40,000 attendees while giving organizers a secure administrative backend.

## 🏗 Repository Layout

/frontend: The attendee-facing app built with Flutter.

/backend: The C# .NET Minimal API used for administrative tasks (Schedule management, cascading delays, etc.).

/database: (Optional) SQL scripts for Supabase triggers and Row-Level Security policies.

## 🚀 Local Development

### 1. Backend (Admin API)

The backend acts as a gatekeeper for the Supabase database, handling logic-heavy operations like the "Schedule Shuffle."

1. Navigate to /backend.

2. Ensure your appsettings.json contains the correct SUPABASE_URL and SUPABASE_ANON_KEY.

3. Run dotnet run. The API will start at http://localhost:5000.

### 2. Mobile (Attendee App)

1. Navigate to /mobile.

2. Run flutter pub get.

3. Note for Emulators: Set the API base URL to http://10.0.2.2:5000 to connect to the local backend from an Android emulator.

## 🛠 Features & Logic

### Cascading Schedule Delay

The backend includes a custom algorithm to handle event delays. When a performance is delayed, an admin can trigger a "Shuffle" which automatically recalculates and updates the start times for all subsequent performances on that specific stage.

### User Analytics & Registration

Upon user signup via Supabase Auth, a PostgreSQL trigger automatically initializes a record in the public.profiles table. This allows the festival to track demographic analytics (age, nationality) securely.

## 📜 License

This project is developed for the Japan Festival Boston committee. All rights reserved.
