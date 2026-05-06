// TODO: Replace with your actual Supabase project credentials.
// Find them in: Supabase dashboard → Project Settings → API
//
// Recommended: pass them via --dart-define at build time rather than
// committing real keys here, e.g.:
//   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
//               --dart-define=SUPABASE_ANON_KEY=eyJ...
abstract final class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  // Web client ID from Google Cloud Console — required as serverClientId in
  // GoogleSignIn.instance.initialize(); also registered in Supabase → Google provider.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // iOS client ID from Google Cloud Console — passed as clientId in
  // GoogleSignIn.instance.initialize(). The same value is also present in
  // ios/Runner/GoogleService-Info.plist (CLIENT_ID), which the native SDK reads
  // directly. Kept here for visibility alongside the other Google credentials.
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );
}
