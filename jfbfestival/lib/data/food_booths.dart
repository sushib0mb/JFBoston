import 'package:supabase/supabase.dart';
import 'dart:async';
import '../models/food_booth.dart';
import '../models/dish.dart';

// Global list to store food booths data
final List<FoodBooth> foodBooths = [];

class FoodService {
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
        // Ensure allergens is a list, whether it's a string or already a list
        final allergens = dishData['allergens'];
        List<String> allergensList = [];
        if (allergens != null) {
          if (allergens is String) {
            // If it's a string, split by commas
            allergensList = allergens.split(',').map((s) => s.trim()).toList();
          } else if (allergens is List) {
            // If it's already a list, use it directly
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
              // Ensure booth allergens is a list (same as for dishes)
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
                // allergy: boothData['allergy'],
                boothLocation: boothData['booth_location'] ?? '',
                genre: boothData['genre'] ?? '',
                logoPath: boothData['logo_path'] ?? '',
                boothImagePath: boothData['booth_image_path'] ?? '',
                isVegan: boothData['is_vegan'] ?? false,
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

  void dispose() {
    _foodBoothsSubscription?.cancel();
    _dishesSubscription?.cancel();
  }
}

void initFoodBoothsService(SupabaseClient supabaseClient) {
  final foodService = FoodService(supabaseClient);
  foodService.initialize();
}

// final List<FoodBooth> foodBooths = [
//   FoodBooth(
//     name: "Miraku Boston",
//     image: "assets/foodLogo/miraku_boston.png",
//     description: "Zangi, sweets",
//     allergy: "Contains gluten",
//     boothLocation: "B",
//     mapPageFoodLocation: "B",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/miraku_boston.png",
//     dishImagePath: "assets/food/zangi.jpg",
//     isVegan: true,
//     payments: ["Cash", "Venmo"],
//     allergens: ["Wheat"],
//     dishes: [
//       Dish(
//         name: "Zangi (Hokkaido-style Fried Chicken)",
//         description: "Crispy fried chicken pieces marinated in special sauce",
//         price: 8.99,
//         allergens: ["Wheat", "Soy", "Egg", "Sesame"],
//         imagePath: "assets/food/zangi.jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Cheescake",
//         description: "Soft, creamy, and fluffy dessert, very tasty",
//         price: 5.99,
//         allergens: ["Wheat", "Egg", "Milk"],
//         imagePath: "assets/food/cheescake.jpg",
//         isVegan: true,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Cafe Itadaki",
//     image: "assets/foodLogo/cafe_itadaki.jpg",
//     description: "Takoyaki, fried chicken, snacks, Ramune",
//     allergy: "Contains wheat, soy",
//     boothLocation: "C",
//     mapPageFoodLocation: "C",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/cafe_itadaki.jpg",
//     dishImagePath: "assets/food/itadaki_takoyaki.jpg",
//     isVegan: true,
//     payments: ["Cash"],
//     allergens: ["Wheat", "Soy"],
//     dishes: [
//       Dish(
//         name: "Takoyaki",
//         description: "Octopus balls topped with sauce, mayo, and bonito flakes",
//         price: 7.99,
//         allergens: ["Wheat", "Soy", "Fish", "Egg"],
//         imagePath: "assets/food/16. Takoyaki.jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Karaage",
//         description: "Japanese-style fried chicken",
//         price: 8.99,
//         allergens: ["Wheat", "Soy"],
//         imagePath: "assets/food/zangi.jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Ramune Soda",
//         description: "Japanese marble soda in various flavors",
//         price: 3.99,
//         allergens: [],
//         imagePath: "assets/food/Ramune.jpg",
//         isVegan: true,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Tori Jiro",
//     image: "assets/food/tori_jori.jpg",
//     description: "Yakitori, grilled skewers, dessert, drinks",
//     allergy: "Contains soy",
//     boothLocation: "B",
//     mapPageFoodLocation: "B",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/tori_jori_logo.jpg",
//     dishImagePath: "assets/food/tori_jori.jpg",
//     isVegan: true,
//     payments: ["Cash"],
//     allergens: ["Soy"],
//     dishes: [
//       Dish(
//         name: "Chicken Yakitori",
//         description: "Grilled chicken skewers with tare sauce",
//         price: 6.99,
//         allergens: ["Soy"],
//         imagePath: "assets/food/Chicken Yakitori.jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Vegetable Skewers",
//         description: "Grilled seasonal vegetables with salt",
//         price: 5.99,
//         allergens: [],
//         imagePath: "assets/food/Vegan_yakitori.jpeg",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Dorayaki",
//         description: "Japanese pancake with sweet red bean filling",
//         price: 4.99,
//         allergens: ["Wheat", "Egg"],
//         imagePath: "assets/food/dorayaki.jpg",
//         isVegan: false,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Tokyo Teriyaki Chicken",
//     image: "assets/food/TeriyakiDon.png",
//     description: "Teriyaki Chicken Bowl, Matcha Dessert and Boba Tea",
//     allergy: "Contains soy, dairy",
//     boothLocation: "C",
//     mapPageFoodLocation: "C",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/Bosso.jpg",
//     dishImagePath: "assets/food/TeriyakiDon.png",
//     isVegan: false,
//     payments: ["Cash"],
//     allergens: ["Soy", "Milk"],
//     dishes: [
//       Dish(
//         name: "Teriyaki Chicken Bowl",
//         description: "Grilled chicken with teriyaki sauce over rice",
//         price: 10.99,
//         allergens: ["Soy"],
//         imagePath: "assets/food/tokyo_teriyaki.jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Matcha Ice Cream",
//         description: "Green tea flavored ice cream",
//         price: 4.99,
//         allergens: ["Milk"],
//         imagePath: "assets/food/Matcha.webp",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Boba Milk Tea",
//         description: "Sweet milk tea with tapioca pearls",
//         price: 5.99,
//         allergens: ["Milk"],
//         imagePath: "assets/food/Milktea.webp",
//         isVegan: false,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Akita Rice Smoothie",
//     image: "assets/akita_smoothie.png",
//     description: "AKITA RICE SMOOTHIE Berry, Amazake",
//     allergy: "Contains soy",
//     boothLocation: "B",
//     mapPageFoodLocation: "B",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/Akita.png",
//     dishImagePath: "assets/food/akitaRiceSmoothie.jpg",
//     isVegan: false,
//     payments: ["Cash", "Venmo"],
//     allergens: ["Soy"],
//     dishes: [
//       Dish(
//         name: "AKITA RICE SMOOTHIE Berry",
//         description: "Creamy smoothie with a touch of Berries",
//         price: 4.99,
//         allergens: ["Soy"],
//         imagePath: "assets/food/Berry.jpeg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Amazake",
//         description: "Creamy sweet sake smoothie",
//         price: 6.99,
//         allergens: ["Soy"],
//         imagePath: "assets/food/amazake.jpg",
//         isVegan: false,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Beard Papa's",
//     image: "assets/food/beard_papa.jpg",
//     description: "Cream puffs and boba tea",
//     allergy: "Contains dairy, wheat",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Bakery",
//     logoPath: "assets/foodLogo/beard_papaIcon.jpg",
//     dishImagePath: "assets/food/beard_papa.jpg",
//     isVegan: false,
//     payments: ["Cash", "Zelle", "Credit Card"],
//     allergens: ["Egg", "Milk", "Wheat"],
//     dishes: [
//       Dish(
//         name: "Vanilla Cream Puff",
//         description: "Crispy shell filled with vanilla custard cream",
//         price: 4.99,
//         allergens: ["Milk", "Wheat", "Egg"],
//         imagePath: "assets/food/vanilla_cream_puff.png",
//         isVegan: false,
//       ),

//       Dish(
//         name: "Milk Tea",
//         description: "Classic milk tea with tapioca pearls",
//         price: 5.99,
//         allergens: ["Milk"],
//         imagePath: "assets/food/Milktea.webp",
//         isVegan: false,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Wakazo Gyoza",
//     image: "assets/food/wakazo_gyoza.jpg",
//     description: "Gyoza, water, soft drinks",
//     allergy: "Contains wheat",
//     boothLocation: "B",
//     mapPageFoodLocation: "B",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/WakazoIcon.png",
//     dishImagePath: "assets/food/wakazo_gyoza.jpg",
//     isVegan: false,
//     payments: ["Cash", "Venmo", "PayPal"],
//     allergens: ["Wheat", "Soy"],
//     dishes: [
//       Dish(
//         name: "Pan-fried Gyoza (6 pcs)",
//         description: "Japanese dumplings filled with pork and vegetables",
//         price: 7.99,
//         allergens: ["Wheat", "Soy"],
//         imagePath: "assets/food/wakazo_gyoza.jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Vegetable Gyoza (6 pcs)",
//         description: "Dumplings filled with cabbage, carrots, and mushrooms",
//         price: 7.49,
//         allergens: ["Wheat", "Soy"],
//         imagePath: "assets/food/veggie_gyoza.png",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Bottled Water",
//         description: "500ml bottled water",
//         price: 2.00,
//         allergens: [],
//         imagePath: "assets/food/WATER.jpg",
//         isVegan: true,
//       ),
//     ],
//   ),

//   FoodBooth(
//     name: "Ichiban Kimchi",
//     image: "assets/food/8. Ichiban Kimchi.jpg",
//     description: "Kimchi, reference:",
//     allergy: "Contains soy",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Korean",
//     logoPath: "assets/foodLogo/Ichiban.jpg",
//     dishImagePath: "assets/food/8. Ichiban Kimchi.jpg",
//     isVegan: true,
//     payments: ["Cash", "Zelle", "Credit Card"],
//     allergens: ["Soy"],
//     dishes: [
//       Dish(
//         name: "Mochi Kimchi",
//         description: "chewy texture of the mochi are addictively delicious",
//         price: 8.99,
//         allergens: ["Soy", "Wheat", "Fish", "Shellfish", "Sesame"],
//         imagePath: "assets/food/8. Ichiban Kimchi.jpg",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Potato Butter Kimchi",
//         description: "The richness of the butter and the umami of the kimchi",
//         price: 7.99,
//         allergens: ["Soy", "Wheat", "Fish", "Shellfish", "Sesame"],
//         imagePath: "assets/food/Butter Kimchi.png",
//         isVegan: true,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Japan Onigiri Akitaya",
//     image: "assets/food/18. A) Akitaya.jpg",
//     description: "Rice ball (onigiri)",
//     allergy: "Contains soy, seaweed",
//     boothLocation: "A2-2",
//     mapPageFoodLocation: "B",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/akitayalogo.png",
//     dishImagePath: "assets/food/18. A) Akitaya.jpg",
//     isVegan: true,
//     payments: ["Cash", "Venmo", "PayPal"],
//     allergens: ["Soy"],
//     dishes: [
//       Dish(
//         name: "Umeboshi Onigiri",
//         description: "Rice ball with pickled plum filling",
//         price: 3.99,
//         allergens: [],
//         imagePath: "assets/food/ume.jpg",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Seaweed Onigiri",
//         description: "Rice ball filled with seasoned seaweed",
//         price: 3.99,
//         allergens: ["Soy"],
//         imagePath: "assets/food/onini.jpg",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Tuna Mayo Onigiri",
//         description: "Rice ball with tuna and mayonnaise filling",
//         price: 4.50,
//         allergens: ["Fish", "Egg", "Soy"],
//         imagePath: "assets/food/tunatuna.jpg",
//         isVegan: false,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Ramen Nikkou",
//     image: "assets/food/ramen.jpg",
//     description: "Kottreri Paitan Ramen",
//     allergy: "Contains wheat, soy, sesame",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Ramen",
//     logoPath: "assets/foodLogo/ramen_nikkou.png",
//     dishImagePath: "assets/food/11. Nikko Ramen.jpg",
//     isVegan: false,
//     payments: ["Cash", "Venmo"],
//     allergens: ["Wheat", "Soy", "Sesame"],
//     dishes: [
//       Dish(
//         name: "Kottreri Paitan Ramen",
//         description: "Rich and creamy chicken ramen",
//         price: 13.00,
//         allergens: ["Wheat", "Soy", "Sesame"],
//         imagePath: "assets/food/11. Nikko Ramen.jpg",
//         isVegan: false,
//       ),
//     ],
//   ),

//   FoodBooth(
//     name: "Umai Beef Bowl",
//     image: "assets/foodLogo/umai.png",
//     description: "Japanese beef rice bowls",
//     allergy: "Contains soy",
//     boothLocation: "C",
//     mapPageFoodLocation: "C",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/umai.png",
//     dishImagePath: "assets/food/UmaiGyudon.jpg",
//     isVegan: false,
//     payments: ["Cash", "Zelle", "Venmo"],
//     allergens: ["Soy"],
//     dishes: [
//       Dish(
//         name: "Beef Bowl",
//         description: "Japanese style beef rice bowl",
//         price: 10.00,
//         allergens: ["Soy"],
//         imagePath: "assets/food/UmaiGyudonPopup.jpg",
//         isVegan: false,
//       ),
//     ],
//   ),
//   // Hokkaido Ramen Santouka (北海道らーめん山頭火)
//   FoodBooth(
//     name: "Hokkaido Ramen Santouka",
//     image: "assets/food/Santouka.jpg",
//     description: "Hokkaido style ramen and snacks",
//     allergy:
//         "Contains egg, wheat, milk, soy, fish, sesame, peanut, tree nuts, shellfish",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Ramen",
//     logoPath: "assets/foodLogo/santouka.jpeg",
//     dishImagePath: "assets/food/Santouka.jpg",
//     isVegan: false,
//     payments: ["Credit Card"],
//     allergens: [
//       "Egg",
//       "Wheat",
//       "Milk",
//       "Soy",
//       "Fish",
//       "Sesame",
//       "Peanut",
//       "Tree Nut",
//       "Shellfish",
//     ],
//     dishes: [
//       Dish(
//         name: "Ramen",
//         description: "Hokkaido style ramen",
//         price: 14.00,
//         allergens: ["Egg", "Wheat", "Milk", "Soy", "Fish", "Sesame"],
//         imagePath: "assets/food/Santouka.jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Potato Stick",
//         description: "Crispy potato snack",
//         price: 4.00,
//         allergens: ["Egg", "Wheat", "Peanut", "Milk"],
//         imagePath: "assets/food/potato.jpg",
//         isVegan: false,
//       ),
//     ],
//   ),

//   FoodBooth(
//     name: "Kevin's Bread",
//     image: "assets/food/Kevins Bread.jpg",
//     description: "Japanese style breads",
//     allergy: "Contains egg, wheat, milk",
//     boothLocation: "B",
//     mapPageFoodLocation: "B",
//     genre: "Bakery",
//     logoPath: "assets/foodLogo/kevin_bread.jpg",
//     dishImagePath: "assets/food/Kevins Bread.jpg",
//     isVegan: false,
//     payments: ["Cash", "Venmo"],
//     allergens: ["Egg", "Wheat", "Milk"],
//     dishes: [
//       Dish(
//         name: "Curry Pan",
//         description: "Japanese curry bread",
//         price: 5.50,
//         allergens: ["Egg", "Wheat", "Milk"],
//         imagePath: "assets/food/curry_bread.jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Sakura An Pan",
//         description: "Sweet bread with cherry blossom filling",
//         price: 5.00,
//         allergens: ["Egg", "Wheat", "Milk"],
//         imagePath: "assets/food/sakura.jpg",
//         isVegan: false,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "IBARAKI's Yaki-Onigiri",
//     image: "assets/food/17. Yaki Onigiri.jpg",
//     description: "Grilled rice balls",
//     allergy: "Contains soy, wheat",
//     boothLocation: "B",
//     mapPageFoodLocation: "B",
//     genre: "Japanese",
//     logoPath: "assets/food/17. Yaki Onigiri.jpg",
//     dishImagePath: "assets/food/17. Yaki Onigiri.jpg",
//     isVegan: true, // All items marked Yes for vegetarian
//     payments: ["Cash", "Venmo"],
//     allergens: ["Soy", "Wheat"],
//     dishes: [
//       Dish(
//         name: "Yaki-Onigiri (Soy Sauce)",
//         description: "Grilled rice ball with soy sauce flavor",
//         price: 4.50,
//         allergens: ["Soy"],
//         imagePath: "assets/food/Yakiyaki.jpg",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Yaki-Onigiri (Miso)",
//         description: "Grilled rice ball with miso flavor",
//         price: 4.50,
//         allergens: ["Wheat", "Soy"],
//         imagePath: "assets/food/yakini.jpg",
//         isVegan: true,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Lady M Cake Boutique",
//     image: "assets/food/signature_mille_crepes.jpg",
//     description:
//         "Signature Mille Crepes, Green Tea Mille Crepes, Pistachio Mille Crepes",
//     allergy: "Contains Egg, Wheat, Milk, Tree Nuts",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Bakery",
//     logoPath: "assets/foodLogo/Lady_M.jpeg",
//     dishImagePath: "\assets/food/signature_mille_crepes.jpg",
//     isVegan: true,
//     payments: ["Cash", "Credit"],
//     allergens: ["Egg", "Wheat", "Milk", "Tree Nuts"],
//     dishes: [
//       Dish(
//         name: "Signature Mille Crepes",
//         description:
//             "Twenty layers of thin handmade crepes with light pastry cream",
//         price: 9.50,
//         allergens: ["Egg", "Wheat", "Milk", "Treenut"],
//         imagePath: "assets/food/signature_mille_crepes.jpg",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Green Tea Mille Crepes",
//         description:
//             "Twenty layers of thin handmade crepes with matcha green tea cream",
//         price: 9.99,
//         allergens: ["Egg", "Wheat", "Milk", "Tree Nut"],
//         imagePath: "assets/food/green_tea_cheescake.png",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Pistachio Mille Crepes",
//         description:
//             "Twenty layers of thin handmade crepes with pistachio cream",
//         price: 10.50,
//         allergens: ["Egg", "Wheat", "Milk", "Tree Nuts"],
//         imagePath: "assets/food/Pispis.jpg",
//         isVegan: true,
//       ),
//     ],
//   ),

//   FoodBooth(
//     name: "Yawaragi International",
//     image: "assets/food/Konpeito.webp",
//     description: "Traditional Japanese sweets and green tea",
//     allergy: "N/A",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Japanese Confectionery",
//     logoPath: "assets/foodLogo/WagashiLogo.png",
//     dishImagePath: "assets/food/Konpeito.webp",
//     isVegan: true,
//     payments: ["Cash", "Venmo"],
//     allergens: [],
//     dishes: [
//       Dish(
//         name: "Nerikiri",
//         description: "Traditional Japanese sweet",
//         price: 5.00,
//         allergens: [],
//         imagePath: "assets/food/nerikiri.jpeg",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Higashi",
//         description: "Dry Japanese sweet",
//         price: 4.50,
//         allergens: [],
//         imagePath: "assets/food/Higashi.png",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Konpeito",
//         description: "Japanese sugar candy",
//         price: 3.50,
//         allergens: [],
//         imagePath: "assets/food/Konpeito.webp",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Green Tea",
//         description: "Traditional Japanese green tea",
//         price: 3.00,
//         allergens: [],
//         imagePath: "assets/food/greentea.jpg",
//         isVegan: true,
//       ),
//     ],
//   ),

//   FoodBooth(
//     name: "Yume wo Katare",
//     image: "assets/food/Yume.png",
//     description: "Japanese ramen",
//     allergy: "Contains wheat, fish",
//     boothLocation: "C",
//     mapPageFoodLocation: "C",
//     genre: "Ramen",
//     logoPath: "assets/foodLogo/YumeLogo.png",
//     dishImagePath: "assets/food/Yume.png",
//     isVegan: false,
//     payments: ["Cash", "Venmo"],
//     allergens: ["Wheat", "Fish"],
//     dishes: [
//       Dish(
//         name: "Ramen",
//         description: "Traditional Japanese ramen",
//         price: 12.00,
//         allergens: ["Wheat", "Fish"],
//         imagePath: "assets/food/Yume.png",
//         isVegan: false,
//       ),
//     ],
//   ),

//   FoodBooth(
//     name: "Sakabayashi Sushi Tavern",
//     image: "assets/food/Sakabayashi.png",
//     description: "Japanese bento boxes and snacks",
//     allergy: "Contains egg, fish",
//     boothLocation: "C",
//     mapPageFoodLocation: "C",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/sakabayashi.png",
//     dishImagePath: "assets/food/Sakabayashi.png",
//     isVegan: false,
//     payments: ["Cash", "Credit Card"],
//     allergens: ["Egg", "Fish"],
//     dishes: [
//       Dish(
//         name: "Karaage and Salmon Bento",
//         description: "Fried chicken and salmon bento box",
//         price: 12.50,
//         allergens: ["Egg", "Fish"],
//         imagePath: "assets/food/Salmon.jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Salmon Onigiri",
//         description: "Rice ball with salmon filling",
//         price: 5.00,
//         allergens: ["Fish"],
//         imagePath: "assets/food/Sakabayashi.png",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Takoyaki",
//         description: "Octopus balls",
//         price: 6.50,
//         allergens: ["Egg"],
//         imagePath: "assets/food/16. Takoyaki.jpg",
//         isVegan: false,
//       ),
//     ],
//   ),

//   FoodBooth(
//     name: "Bosso Ramen Tavern",
//     image: "assets/food/Teriyakiki.png",
//     description: "Japanese chicken dishes",
//     allergy: "Contains wheat, soy",
//     boothLocation: "TBD",
//     mapPageFoodLocation: "C",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/Bosso.png",
//     dishImagePath: "assets/food/Teriyakiki.png",
//     isVegan: false,
//     payments: ["Cash", "Venmo"],
//     allergens: ["Wheat", "Soy"],
//     dishes: [
//       Dish(
//         name: "Chicken Teriyaki",
//         description: "Grilled chicken with teriyaki sauce",
//         price: 10.50,
//         allergens: ["Wheat", "Soy"],
//         imagePath: "assets/food/Teriyakiki.png",
//         isVegan: false,
//       ),
//     ],
//   ),

//   FoodBooth(
//     name: "ROYCE' Chocolate",
//     image: "assets/food/2.3. Royce.jpg",
//     description: "Premium Japanese chocolates",
//     allergy: "Contains milk, soy, tree nuts, wheat",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Dessert",
//     logoPath: "assets/foodLogo/Royce.jpeg",
//     dishImagePath: "assets/food/2.3. Royce.jpg",
//     isVegan: false,
//     payments: ["Cash", "Debit/Credit Card", "Apple Pay", "Google Pay"],
//     allergens: ["Milk", "Soy", "Tree Nuts", "Wheat"],
//     dishes: [
//       Dish(
//         name: "NAMA CHOCOLATE",
//         description: "Premium fresh chocolate",
//         price: 12.00,
//         allergens: ["Milk", "Soy", "Tree Nuts"],
//         imagePath: "assets/food/Nama.png",
//         isVegan: false,
//       ),
//       Dish(
//         name: "BAR CHOCOLATE",
//         description: "Chocolate bar",
//         price: 8.00,
//         allergens: ["Wheat", "Milk", "Soy", "Tree Nuts"],
//         imagePath: "assets/food/Barstick.png",
//         isVegan: false,
//       ),
//       Dish(
//         name: "PURE CHOCOLATE/PRAFEUILLE CHOCOLATE",
//         description: "Pure chocolate",
//         price: 10.00,
//         allergens: ["Milk", "Soy", "Tree Nuts"],
//         imagePath: "assets/food/Strawberry.png",
//         isVegan: false,
//       ),
//       Dish(
//         name: "CHOCOLATE WAFERS",
//         description: "Chocolate coated wafers",
//         price: 7.50,
//         allergens: ["Wheat", "Milk", "Soy", "Tree Nuts"],
//         imagePath: "assets/food/ROYCE CHOCOLATE.png",
//         isVegan: false,
//       ),
//     ],
//   ),

//   FoodBooth(
//     name: "Pagu",
//     image: "assets/food/PaguFood.png",
//     description: "Japanese rice balls and noodles",
//     allergy: "Contains soy, fish, sesame, wheat",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/Pagu.png",
//     dishImagePath: "assets/food/PaguFood.png",
//     isVegan: false,
//     payments: ["Cash", "Venmo"],
//     allergens: ["Soy", "Fish", "Sesame", "Wheat"],
//     dishes: [
//       Dish(
//         name: "Salmon Teriyaki Onigiri",
//         description: "Rice ball with teriyaki salmon",
//         price: 6.00,
//         allergens: ["Soy", "Fish"],
//         imagePath: "assets/food/Salmon.jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Kombu Tsukudani Onigiri",
//         description: "Rice ball with seaweed",
//         price: 5.50,
//         allergens: ["Soy", "Sesame"],
//         imagePath: "assets/food/Konbu.png",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Soba Noodle Salad",
//         description: "Cold soba noodle salad",
//         price: 8.00,
//         allergens: ["Wheat", "Soy", "Sesame"],
//         imagePath: "assets/food/SaladSoba.png",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Ube Mochi",
//         description: "Purple yam mochi",
//         price: 5.00,
//         allergens: [],
//         imagePath: "assets/food/Ube Mochi.png",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Pina Colada Amazake",
//         description: "Sweet fermented rice drink",
//         price: 5.50,
//         allergens: [],
//         imagePath: "assets/food/PineSake.png",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Sparkling Tea",
//         description: "Refreshing sparkling tea",
//         price: 4.50,
//         allergens: [],
//         imagePath: "assets/food/Sparkling.png",
//         isVegan: true,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Babumura",
//     image: "assets/food/BabuBabu.png",
//     description: "Freshly made Okonomiyaki!",
//     allergy: "Contains Egg, Wheat, Soy",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/BabLogo.png",
//     dishImagePath: "assets/food/BabuBabu.png",
//     isVegan: false,
//     payments: ["Debit/Credit Card"],
//     allergens: ["Egg", "Wheat", "Soy"],
//     dishes: [
//       Dish(
//         name: "Okonomiyaki",
//         description: "Freshly made okonomiyaki",
//         price: 12.00,
//         allergens: ["Egg", "Wheat", "Soy"],
//         imagePath: "assets/food/BabuBabu.png",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Wagyu Okonomiyaki",
//         description: "Okonomiyaki with Wagyu",
//         price: 8.00,
//         allergens: ["Egg", "Wheat", "Soy"],
//         imagePath: "assets/food/BABBAB.jpg",
//         isVegan: false,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Osaka En-nosauke Shouten",
//     image: "assets/food/RamenOishi.png",
//     description: "Kodawari Ramen from Osaka!",
//     allergy: "Contains Wheat, Soy, Fish, Sesame",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/RAMENRAMEN.png",
//     dishImagePath: "assets/food/RamenOishi.png",
//     isVegan: false,
//     payments: ["Cash"],
//     allergens: ["Egg", "Wheat", "Soy"],
//     dishes: [
//       Dish(
//         name: "Tori Paitan Ramen",
//         description: "Ramen with Chicken",
//         price: 12.00,
//         allergens: ["Wheat", "Soy", "Fish", "Sesame"],
//         imagePath: "assets/food/BabuBabu.png",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Cha-shu onigiri",
//         description: "Riceball with Pork Meat",
//         price: 8.00,
//         allergens: ["Wheat", "Soy", "Sesame"],
//         imagePath: "assets/food/Chashu.png",
//         isVegan: false,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Nagomi",
//     image: "assets/food/warabimochi.jpg",
//     description: "Soft warabimochi!",
//     allergy: "Contains Soy",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/nagomi.jpg",
//     dishImagePath: "assets/food/warabimochi.jpg",
//     isVegan: true,
//     payments: ["Cash"],
//     allergens: ["Soy"],
//     dishes: [
//       Dish(
//         name: "Roasted soybean Warabimochi",
//         description: "Roasted soybean flour flavored soft mochi!",
//         price: 12.00,
//         allergens: ["Soy"],
//         imagePath: "assets/food/mochi1.webp",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Matcha Roasted Black Soybean Warabimochi",
//         description: "Matcha flavored roasted black soybean mochi!",
//         price: 8.00,
//         allergens: ["Soy"],
//         imagePath: "assets/food/mochi2.jpg",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Brown Sugar Warabimochi",
//         description: "Brown sugar flavored soft mochi!",
//         price: 8.00,
//         allergens: [],
//         imagePath: "assets/food/mochi3.jpg",
//         isVegan: true,
//       ),
//     ],
//   ),
//   FoodBooth(
//     name: "Nagomi Bento",
//     image: "assets/foodLogo/7. Nagomi Bento .jpg",
//     description: "Japanese bento boxes and drinks",
//     allergy: "Contains egg, soy",
//     boothLocation: "A",
//     mapPageFoodLocation: "A",
//     genre: "Japanese",
//     logoPath: "assets/foodLogo/nagomi_bento.jpg",
//     dishImagePath: "assets/food/7. Nagomi Bento .jpg",
//     isVegan: false, // Mixed vegan options
//     payments: ["Cash", "Credit Card"],
//     allergens: ["Egg", "Soy"],
//     dishes: [
//       Dish(
//         name: "Nagomi Gyudon",
//         description: "Beef rice bowl",
//         price: 11.00,
//         allergens: ["Egg", "Soy"],
//         imagePath: "assets/food/7. Nagomi Bento .jpg",
//         isVegan: false,
//       ),
//       Dish(
//         name: "Matcha Lemonade",
//         description: "Refreshing matcha lemonade",
//         price: 4.50,
//         allergens: [],
//         imagePath: "assets/food/MatchaLemon.jpeg",
//         isVegan: true,
//       ),
//       Dish(
//         name: "Barley Tea",
//         description: "Traditional Japanese barley tea",
//         price: 3.50,
//         allergens: [],
//         imagePath: "assets/food/barley.jpg",
//         isVegan: true,
//       ),
//     ],
//   ),
// ];
