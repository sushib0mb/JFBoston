// lib/models/food_booth.dart
import 'dish.dart';

class FoodBooth {
  final String name;
  final String image;
  final String description;
  final String? allergy;
  final String boothLocation;
  final String genre;
  final String logoPath;
  final String boothImagePath;
  final bool isVegan;
  final String mapPageFoodLocation;
  final List<String> payments;
  final List<String> allergens;
  final List<Dish> dishes;

  const FoodBooth({
    required this.mapPageFoodLocation,
    required this.name,
    required this.image,
    required this.description,
    this.allergy,
    required this.boothLocation,
    required this.genre,
    required this.logoPath,
    required this.boothImagePath,
    required this.isVegan,
    required this.payments,
    required this.allergens,
    this.dishes = const [],
  });
}
