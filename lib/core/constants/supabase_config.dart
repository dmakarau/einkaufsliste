// TODO: Replace with your actual Supabase project credentials.
// Find them in: Supabase dashboard → Project Settings → API
//
// Recommended: pass them via --dart-define at build time rather than
// committing real keys here, e.g.:
//   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
//               --dart-define=SUPABASE_ANON_KEY=eyJ...
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}
