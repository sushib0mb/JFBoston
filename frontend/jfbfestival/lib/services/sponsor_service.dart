import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';
import '../data/sponsor_data.dart';

class SponsorService extends ChangeNotifier {
  final SupabaseClient _supabase;

  List<Sponsor> sponsors = [];
  bool isLoading = false;
  String? errorMessage;

  SponsorService(this._supabase) {
    fetchSponsors();
  }

  Future<void> fetchSponsors() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final List<dynamic> response = await _supabase
          .from('sponsors')
          .select()
          .order('id', ascending: true);

      sponsors =
          response
              .map((data) => Sponsor.fromSupabase(data as Map<String, dynamic>))
              .toList();
    } catch (e) {
      print("Error fetching sponsors: $e");
      errorMessage = "Could not load sponsors";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
