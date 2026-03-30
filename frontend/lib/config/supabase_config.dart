import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final SupabaseClient supabase = SupabaseClient(
  dotenv.env['SUPABASE_URL']!,
  dotenv.env['SUPABASE_ANON_KEY']!,
);
