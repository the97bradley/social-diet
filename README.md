# Social Diet

A Flutter + Supabase app for calories, workouts, custom lifestyle trackers, and a small social layer (friends, DMs, feed).

Create a tracker such as “workout 3 times a week” or “only 4 beers a week,” then share it with friends so everyone can log against the same goals.

## Stack

- Flutter app in `app/`
- Supabase project **Social Diet** (`munjmpzbpwfwybnppfqp`)
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

The client defaults to the hosted Social Diet project. Override with dart-defines:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

If sign-up returns a user but no session, turn off **Confirm email** in the Supabase Auth settings, or confirm the user and sign in.

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
