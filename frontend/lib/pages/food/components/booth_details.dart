import 'package:flutter/material.dart';
import '../../../models/food_booth.dart';
import '../../../models/dish.dart';

class BoothDetails extends StatelessWidget {
  final FoodBooth booth;
  final VoidCallback onClose;
  final List<String> selectedAllergens;

  const BoothDetails({
    required this.booth,
    required this.onClose,
    required this.selectedAllergens,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred Background with clickable area to close
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.white.withOpacity(0.02)),
          ),
        ),
        // Main Content with Logo Overlay
        Stack(
          children: [
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.6,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Main scrollable content
                    Column(
                      children: [
                        // Top image
                        Container(
                          height: 186,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(25),
                              topRight: Radius.circular(25),
                            ),
                            image: DecorationImage(
                              image: NetworkImage(booth.boothImagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(25),
                                topRight: Radius.circular(25),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  booth.name,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    color: Colors.white,
                                    fontWeight: FontWeight.normal,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 5,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Food Booth: ${booth.boothLocation}",
                                  style: const TextStyle(
                                    fontSize: 23,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w300,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 5,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        // Scrollable content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _buildSection(
                                  "Payment",
                                  _buildPaymentOptions(booth.payments),
                                ),
                                const SizedBox(height: 10),
                                _buildSection(
                                  "Vegetarian",
                                  _buildVeganism(booth.isVegan),
                                ),
                                const SizedBox(height: 2),
                                _buildSection(
                                  "Dishes",
                                  _buildDishesSection(
                                    booth.dishes,
                                    selectedAllergens,
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Close button floating on top
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: onClose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildDishesSection(
    List<Dish> dishes,
    List<String> selectedAllergens,
  ) {
    return Column(
      children:
          dishes
              .map(
                (dish) =>
                    DishCard(dish: dish, selectedAllergens: selectedAllergens),
              )
              .toList(),
    );
  }

  Widget _buildPaymentOptions(List<String> payments) {
    final items = [
      _buildPaymentItem(
        "Venmo",
        "assets/payments/venmo.png",
        payments.contains("Venmo"),
      ),
      _buildPaymentItem(
        "Zelle",
        "assets/payments/zelle.png",
        payments.contains("Zelle"),
      ),
      _buildPaymentItem(
        "Cash",
        "assets/payments/cash.png",
        payments.contains("Cash"),
      ),
      _buildPaymentItem(
        "Credit",
        "assets/payments/credit_card.png",
        payments.contains("Credit Card"),
      ),
      _buildPaymentItem(
        "PayPal",
        "assets/payments/paypal.png",
        payments.contains("PayPal"),
      ),
      _buildPaymentItem(
        "Apple",
        "assets/payments/apple_pay.png",
        payments.contains("Apple"),
      ),
    ];

    // Split into 2 equal rows (3 items each)
    final row1 = items.sublist(0, 3);
    final row2 = items.sublist(3, 6);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: row1),
        SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: row2),
      ],
    );
  }

  Widget _buildPaymentItem(String label, String assetPath, bool isAccepted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              assetPath,
              width: 30,
              height: 30,
              color: isAccepted ? null : Colors.grey.withOpacity(0.5),
              colorBlendMode: BlendMode.modulate,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.normal,
            color: isAccepted ? Colors.black : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildVeganism(bool isVegan) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                "assets/vegan.png",
                width: 30,
                height: 30,
                color: isVegan ? null : Colors.grey.withOpacity(0.5),
                colorBlendMode: BlendMode.modulate,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isVegan ? "Yes" : "None",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: isVegan ? Colors.black : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

class DishCard extends StatefulWidget {
  final Dish dish;
  final List<String> selectedAllergens;

  const DishCard({
    required this.dish,
    required this.selectedAllergens,
    super.key,
  });

  @override
  State<DishCard> createState() => _DishCardState();
}

class _DishCardState extends State<DishCard> {
  bool _showAllergenDetails = false;

  // Map allergen names to their corresponding icon paths
  final Map<String, String> _allergenIcons = {
    "Egg": "assets/allergens/egg.png",
    "Wheat": "assets/allergens/wheat.png",
    "Peanut": "assets/allergens/peanut.png",
    "Milk": "assets/allergens/milk.png",
    "Soy": "assets/allergens/soy.png",
    "Tree Nuts": "assets/allergens/tree_nut.png",
    "Fish": "assets/allergens/fish.png",
    "Shellfish": "assets/allergens/shellfish.png",
    "Sesame": "assets/allergens/sesame.png",
  };
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dish image and badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    widget.dish.imagePath,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // ⚠ Allergen warning badge
                if (widget.dish.allergens.any(
                  (a) => widget.selectedAllergens.contains(a),
                ))
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "⚠ Selected Allergen",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // 🌱 Vegan badge
                if (widget.dish.isVegan)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "Vegetarian",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Name and price bar
                Positioned(
                  bottom: 0,
                  right: 0,
                  left: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            widget.dish.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Dish description & allergen dropdown
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.dish.description,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  if (widget.dish.allergens.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _showAllergenDetails = !_showAllergenDetails;
                            });
                          },
                          child: Row(
                            children: [
                              const Text(
                                "Contains allergens",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7A4E2C),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                _showAllergenDetails
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                size: 18,
                                color: Color.fromARGB(255, 151, 73, 0),
                              ),
                            ],
                          ),
                        ),
                        if (_showAllergenDetails) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                widget.dish.allergens.map((allergen) {
                                  final iconPath =
                                      _allergenIcons[allergen] ??
                                      "assets/allergens/default.png";
                                  return SizedBox(
                                    width: 70,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color:
                                                widget.selectedAllergens
                                                        .contains(allergen)
                                                    ? Colors.red.withOpacity(
                                                      0.15,
                                                    )
                                                    : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.25,
                                                ),
                                                blurRadius: 10,
                                                spreadRadius: 0,
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Image.asset(
                                              iconPath,
                                              width: 30,
                                              height: 30,
                                              color: Color.fromARGB(
                                                255,
                                                107,
                                                53,
                                                1,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          allergen,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color.fromARGB(
                                              255,
                                              107,
                                              53,
                                              1,
                                            ),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
