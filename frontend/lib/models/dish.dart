class Dish {
  final String name;
  final String imagePath;
  final List<String> allergens;
  final bool isVegetarian;
  final int boothId;

  Dish({
    required this.name,
    this.imagePath = '',
    required this.allergens,
    required this.isVegetarian,
    required this.boothId,
  });
}
