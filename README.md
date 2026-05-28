# Project Ynot

Micro-companionship app for nearby activities, built with:

- Flutter for the mobile app
- Supabase for backend data
- Firebase Phone Auth for sign-in
- Naver Maps for the Korean map experience
- Next.js for the private admin panel

## Current status

Sprint 1 base is in place:

- mobile app structure
- dark kawaii theme
- auth flow screens
- map screen with Naver Maps integration and desktop fallback
- activities list and creation flow
- activity detail screen
- admin panel dashboard scaffold
- Supabase schema and RLS foundation

## Where things live

- `apps/mobile` - Flutter mobile app
- `apps/admin` - Next.js admin panel
- `supabase/migrations` - PostgreSQL schema

## What you need to fill in

### 1. Mobile env file

Create `apps/mobile/.env` from `apps/mobile/.env.example` and fill:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `NAVER_MAP_CLIENT_ID`

If those values are missing, the app runs in demo mode.

### 2. Firebase

Firebase Phone Auth still needs the normal Firebase project files before it can run for real on Android.

### 3. Supabase

Run the migration in `supabase/migrations/20260528124000_initial.sql` in your Supabase project.

## Running the apps

### Flutter mobile

From `apps/mobile`:

```powershell
flutter pub get
flutter run
```

### Admin panel

From `apps/admin`:

```powershell
npm run dev
```

## Notes

- The mobile app currently uses demo auth if env keys are missing.
- The map uses the real Naver plugin on Android/iOS when the client id is present.
- Desktop/web show a stylized fallback map so the project stays previewable locally.
