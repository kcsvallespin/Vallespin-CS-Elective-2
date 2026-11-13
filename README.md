# my_flutter_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Authentication (backend-auth)

The app requires sign-in before showing the shop. Two Supabase Auth
providers are supported:

1. **Email / password**: Supabase's built-in provider.
2. **GitHub (OAuth)**: the additional third-party provider.

### Supabase setup for GitHub

1. On GitHub, go to Settings > Developer settings > OAuth Apps > New OAuth App.
   - Homepage URL: your app URL (e.g. `http://localhost:3000`)
   - Authorization callback URL: `https://sbdptpmrtoztuovpjheq.supabase.co/auth/v1/callback`
2. Copy the Client ID and generate a Client Secret.
3. In Supabase: Authentication > Sign In / Providers > GitHub, enable it and
   paste the Client ID and Secret.
4. In Supabase: Authentication > URL Configuration > Redirect URLs, add
   - `io.supabase.reniacc://login-callback/` (Android / iOS)
   - `http://localhost:3000/**` (web, when run with `--web-port 3000`)

### Run

```
flutter run --dart-define=SUPABASE_ANON_KEY=your-publishable-key
flutter run -d chrome --web-port 3000 --dart-define=SUPABASE_ANON_KEY=your-publishable-key
```
