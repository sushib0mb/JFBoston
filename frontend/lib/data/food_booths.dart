import 'package:flutter/foundation.dart';
import 'package:supabase/supabase.dart';
import 'dart:async';
import '../models/food_booth.dart';
import '../models/dish.dart';

// Global list to store food booths data (kept for backward compat)
final List<FoodBooth> foodBooths = [];

class FoodService extends ChangeNotifier {
  final SupabaseClient _supabaseClient;
  StreamSubscription? _foodBoothsSubscription;
  StreamSubscription? _dishesSubscription;

  FoodService(this._supabaseClient);

  // Initialize and start listening for changes
  Future<void> initialize() async {
    await fetchInitialData();
    _setupRealtimeSubscriptions();
  }

  // Fetch initial data
  Future<void> fetchInitialData() async {
    try {
      final fetchedBooths = await getFoodBooths();
      foodBooths.clear();
      foodBooths.addAll(fetchedBooths);
      foodBooths.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      print('Error fetching initial food booths data: $e');
    }
  }

  // Set up real-time subscriptions
  void _setupRealtimeSubscriptions() {
    // Create a single channel to handle all database changes
    final channel = _supabaseClient.channel('food-updates');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'food_booths',
          callback: (payload) {
            fetchInitialData();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dishes',
          callback: (payload) {
            fetchInitialData();
          },
        )
        .subscribe();
  }

  // Get all food booths with their dishes
  // In your FoodService class
  Future<List<FoodBooth>> getFoodBooths() async {
    try {
      // Fetch all food booths
      final foodBoothsResponse = await _supabaseClient
          .from('food_booths')
          .select()
          .order('name');

      final dishesResponse = await _supabaseClient.from('dishes').select();

      // Map dishes response to Dish objects
      final Map<dynamic, List<Dish>> dishesByBooth = {};

      for (final dishData in dishesResponse) {
        final allergens = dishData['allergens'];
        List<String> allergensList = [];
        if (allergens != null) {
          if (allergens is String) {
            allergensList = allergens.split(',').map((s) => s.trim()).toList();
          } else if (allergens is List) {
            allergensList = List<String>.from(allergens);
          }
        }

        final dish = Dish(
          name: dishData['name'],
          description: dishData['description'] ?? '',
          imagePath: dishData['image_path'] ?? '',
          allergens: allergensList,
          isVegan: dishData['is_vegan'] ?? false,
          boothId: dishData['booth_id'],
        );

        final boothId = dishData['booth_id'];
        if (boothId != null) {
          dishesByBooth[boothId] ??= [];
          dishesByBooth[boothId]!.add(dish);
        }
      }

      // Map food booths response to FoodBooth objects
      final List<FoodBooth> booths =
          foodBoothsResponse.map<FoodBooth>((boothData) {
            final boothId = boothData['id'];

            try {
              final boothAllergens = boothData['allergens'];
              List<String> boothAllergensList = [];
              if (boothAllergens != null) {
                if (boothAllergens is String) {
                  boothAllergensList =
                      boothAllergens.split('|').map((s) => s.trim()).toList();
                } else if (boothAllergens is List) {
                  boothAllergensList = List<String>.from(boothAllergens);
                }
              }

              return FoodBooth(
                name: boothData['name'],
                image: boothData['image'] ?? '',
                description: boothData['description'] ?? '',
                boothLocation: boothData['booth_location'] ?? '',
                genre: boothData['genre'] ?? '',
                logoPath: boothData['logo_path'] ?? '',
                boothImagePath: boothData['booth_image_path'] ?? '',
                mapPageFoodLocation: boothData['map_page_food_location'] ?? '',
                payments:
                    boothData['payments'] != null &&
                            boothData['payments'] is String
                        ? (boothData['payments'] as String)
                            .split('|')
                            .map((s) => s.trim())
                            .toList()
                        : [],
                allergens: boothAllergensList,
                dishes: dishesByBooth[boothId] ?? [],
                location: boothData['location'] ?? 'Commons',
              );
            } catch (e) {
              rethrow;
            }
          }).toList();

      return booths;
    } catch (e) {
      print(e);
      return [];
    }
  }

  @override
  void dispose() {
    _foodBoothsSubscription?.cancel();
    _dishesSubscription?.cancel();
    super.dispose();
  }
}

void initFoodBoothsService(SupabaseClient supabaseClient) {
  final foodService = FoodService(supabaseClient);
  foodService.initialize();
}
