import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

class IconService extends ChangeNotifier {
  final SupabaseClient _supabase;

  List<String> iconUrls = [];
  bool isLoading = false;
  String? errorMessage;

  IconService(this._supabase) {
    fetchIcons();
  }

  Future<void> fetchIcons() async {
    // If we already have the URLs, don't fetch again.
    if (iconUrls.isNotEmpty) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Define your bucket and folder
      const String bucketName = 'images';
      const String folderPath = 'performanceIcons';

      final List<FileObject> files = await _supabase.storage
          .from(bucketName)
          .list(path: folderPath);

      // Filter and generate public URLs
      final List<String> urls =
          files
              .where(
                (file) => file.name.isNotEmpty && !file.name.startsWith('.'),
              )
              .map(
                (file) => _supabase.storage
                    .from(bucketName)
                    .getPublicUrl('$folderPath/${file.name}'),
              )
              .toList();

      iconUrls = urls;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Allow admins to force-refresh the list if they just uploaded a new icon
  Future<void> refreshIcons() async {
    iconUrls.clear();
    await fetchIcons();
  }
}
