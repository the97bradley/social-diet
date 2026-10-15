# Social Diet

A Flutter + Supabase app for calories, workouts, custom lifestyle trackers, and a small social layer (friends, DMs, feed).

Create a tracker such as “workout 3 times a week” or “only 4 beers a week,” then share it with friends so everyone can log against the same goals.

## Stack

- Flutter app in `app/`
- Vercel API at [denver-porchfest1/social-diet](https://vercel.com/denver-porchfest1/social-diet/deployments) (`https://social-diet-denver-porchfest1.vercel.app`)
- Supabase project **Social Diet** (`munjmpzbpwfwybnppfqp`) for auth data and RLS
- SQL migrations in `supabase/migrations/`

## App surfaces

- **Today** — remaining calories, meals, workouts, tracker snapshots
- **Trackers** — create custom goal bundles and share them
- **Feed** — status, meal, and workout posts from you and friends
- **Friends** — search, requests, and direct messages
- **Profile** — name, bio, daily calorie goal

## Run the Flutter app

```bash
cd app
flutter pub get
flutter run -d chrome
```

The client defaults to the hosted Social Diet project and the Vercel API. Override with dart-defines:

```bash
flutter run \
  --dart-define=API_BASE_URL=https://social-diet-denver-porchfest1.vercel.app \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

**Create account** POSTs to the Vercel `/api/create-account` function (`admin.createUser` with `email_confirm`), then signs in. That skips the built-in SMTP cap (`over_email_send_rate_limit`, 2 emails/hour) that used to fail signup with `AuthApiException`.

## Schema

Apply the files in `supabase/migrations/` to a linked project. They create:

- `profiles` from `auth.users`
- `friendships`
- `conversations` / `messages` (friends-only DMs)
- `feed_posts` / `feed_likes`
- `food_logs` / `workouts`
- `trackers` / `tracker_goals` / `tracker_members` / `tracker_entries`

Row Level Security is on for every public table. Helper functions live in the unexposed `private` schema.

## Tests

```bash
cd app
flutter test
```
