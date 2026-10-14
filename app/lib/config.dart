class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://munjmpzbpwfwybnppfqp.supabase.co',
  );

  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_WYR-gU7-1LKh9lWa4oGVCA_sS2rjNEf',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11bmptcHpicHdmd3libnBwZnFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE5NDcyOTksImV4cCI6MjEwNzUyMzI5OX0.CkeVJmr81uub6LkDLoB_rlVoo4QSW9eU-ccmvIZBnhw',
  );
}
