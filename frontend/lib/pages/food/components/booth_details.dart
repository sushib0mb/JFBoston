/// ────────────────────────────────────────────────────────────────────────────
/// BOOTH DETAILS COMPONENT
/// ────────────────────────────────────────────────────────────────────────────
/// A high-fidelity modal following Shadcn UI principles.
/// - Integrated custom payment, vegan, and allergen assets.
/// - Refined typography and "flat" card design.
/// - Optimized for clarity with expandable dish details.
/// ────────────────────────────────────────────────────────────────────────────

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
        // Backdrop Overlay
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
        ),

        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.80,
            constraints: const BoxConstraints(maxWidth: 550, maxHeight: 850),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Accepted Payments"),
                        const SizedBox(height: 16),
                        _buildPaymentRow(booth.payments),
                        
                        const SizedBox(height: 32),
                        _buildSectionHeader("Vegetarian Status"),
                        const SizedBox(height: 16),
                        _buildVeganStatus(booth.isVegan),

                        const SizedBox(height: 32),
                        _buildSectionHeader("Menu Items"),
                        const SizedBox(height: 16),
                        _buildDishesSection(booth.dishes, selectedAllergens),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(booth.boothImagePath),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booth.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Food Booth: ${booth.boothLocation}",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black26,
              padding: const EdgeInsets.all(8),
            ),
            onPressed: onClose,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Colors.grey,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildPaymentRow(List<String> payments) {
    final Map<String, String> assetMap = {
      "Venmo": "assets/payments/venmo.png",
      "Zelle": "assets/payments/zelle.png",
      "Cash": "assets/payments/cash.png",
      "Credit Card": "assets/payments/credit_card.png",
      "PayPal": "assets/payments/paypal.png",
      "Apple": "assets/payments/apple_pay.png",
    };

    final entries = assetMap.entries.toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.8,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final bool isAccepted = payments.contains(entry.key);
        return Opacity(
          opacity: isAccepted ? 1.0 : 0.3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Image.asset(entry.value, width: 28, height: 28, fit: BoxFit.contain),
                const SizedBox(width: 10),
                Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVeganStatus(bool isVegan) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isVegan ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isVegan ? Colors.green.withOpacity(0.1) : Colors.black12),
      ),
      child: Row(
        children: [
          Image.asset("assets/vegan.png", width: 24, height: 24, 
            color: isVegan ? null : Colors.grey),
          const SizedBox(width: 12),
          Text(
            isVegan ? "Vegetarian Options Available" : "No Vegetarian Options",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isVegan ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishesSection(List<Dish> dishes, List<String> selectedAllergens) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dishes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => 
          DishCard(dish: dishes[index], selectedAllergens: selectedAllergens),
    );
  }
}

class DishCard extends StatefulWidget {
  final Dish dish;
  final List<String> selectedAllergens;
  const DishCard({required this.dish, required this.selectedAllergens, super.key});

  @override
  State<DishCard> createState() => _DishCardState();
}

class _DishCardState extends State<DishCard> {
  bool _expanded = false;

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
    final bool hasAlert = widget.dish.allergens.any((a) => widget.selectedAllergens.contains(a));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAlert ? Colors.red.withOpacity(0.4) : Colors.black.withOpacity(0.08),
          width: hasAlert ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(widget.dish.imagePath, width: 64, height: 64, fit: BoxFit.cover),
            ),
            title: Text(widget.dish.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(widget.dish.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Icon(
              hasAlert ? Icons.warning_rounded : Icons.keyboard_arrow_down,
              color: hasAlert ? Colors.red : Colors.grey,
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.withOpacity(0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.dish.allergens.isNotEmpty) ...[
                    const Text("ALLERGENS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: widget.dish.allergens.map((allergen) {
                        final isSelected = widget.selectedAllergens.contains(allergen);
                        return Column(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.red.withOpacity(0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isSelected ? Colors.red : Colors.black12),
                              ),
                              child: Image.asset(_allergenIcons[allergen] ?? "assets/allergens/default.png"),
                            ),
                            const SizedBox(height: 4),
                            Text(allergen, style: TextStyle(fontSize: 10, color: isSelected ? Colors.red : Colors.black87)),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}