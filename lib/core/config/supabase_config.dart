class SupabaseConfig {
  // Add your Supabase credentials here
  // You can get these from your Supabase project settings
  static const String supabaseUrl = 'https://pajbygbwbjabxiiwqrxm.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhamJ5Z2J3YmphYnhpaXdxcnhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NzY4MzgsImV4cCI6MjA4NDE1MjgzOH0.Raz_C0Ye-LI3NxsZd_nWbGCyRBRyAE2Zc6I3TOngLQQ';
  
  // Database table names
  static const String usersTable = 'profiles';
  static const String batchesTable = 'batches';
  static const String dailyRecordsTable = 'daily_records';
  
  // Auth settings
  static const int sessionTimeoutMinutes = 60;
}
