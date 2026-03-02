import 'package:flutter/material.dart';
import 'package:supabase/supabase.dart';

class DbImageService extends ChangeNotifier {
  final SupabaseClient _supabase;

  final String bucketName = 'images';

  final Map<String, List<String>> _folderUrls = {};
  final Map<String, bool> _loadingStates = {};
  final Map<String, String?> _errorStates = {};

  DbImageService(this._supabase);

  // Helper methods to read the state for a specific folder
  List<String> getUrlsFor(String folderPath) => _folderUrls[folderPath] ?? [];
  bool isLoading(String folderPath) => _loadingStates[folderPath] ?? false;
  String? getErrorFor(String folderPath) => _errorStates[folderPath];

  Future<void> fetchFolder(String folderPath) async {
    // If we already have the URLs, don't fetch again.
    if ((_folderUrls.containsKey(folderPath) &&
        _folderUrls[folderPath]!.isNotEmpty)) {
      return;
    }

    _loadingStates[folderPath] = true;
    _errorStates[folderPath] = null;
    notifyListeners();

    try {
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

      _folderUrls[folderPath] = urls;
    } catch (e) {
      _errorStates[folderPath] = e.toString();
    } finally {
      _loadingStates[folderPath] = false;
      notifyListeners();
    }
  }

  // Allow admins to force-refresh the list if they just uploaded a new icon
  Future<void> refreshIcons(String folderPath) async {
    _folderUrls.remove(folderPath);
    await fetchFolder(folderPath);
  }
}
