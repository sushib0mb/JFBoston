// lib/models/food_booth.dart
import 'dish.dart';

class FoodBooth {
  final String name;
  final String image;
  final String boothLocation;
  final String genre;
  final String logoPath;
  final String boothImagePath;
  final String mapPageFoodLocation;
  final List<String> payments;
  final List<String> allergens;
  final List<Dish> dishes;
  final String location;

  bool get isVegetarian => dishes.any((d) => d.isVegetarian);

  FoodBooth({
    required this.name,
    required this.image,
    required this.boothLocation,
    required this.genre,
    required this.logoPath,
    required this.boothImagePath,
    required this.mapPageFoodLocation,
    required this.payments,
    required this.allergens,
    required this.dishes,
    required this.location,
  });
}
