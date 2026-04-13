import 'package:flutter/material.dart';
import 'components/payment_filter.dart';
import 'components/vegan_filter.dart';
import 'components/allergy_filter.dart';
import 'components/booth_details.dart';
import '../../data/food_booths.dart';
import '../../models/food_booth.dart';
import 'components/top_action_buttons.dart';
import 'components/search_bar.dart';

// ─────────────────────────────────────────────
// Animated wrapper for booth detail bottom sheet
// ─────────────────────────────────────────────
class AnimatedBoothDetailWrapper extends StatefulWidget {
  final FoodBooth booth;
  final VoidCallback onClose;
  final List<String> selectedAllergens;

  const AnimatedBoothDetailWrapper({
    super.key,
    required this.booth,
    required this.onClose,
    required this.selectedAllergens,
  });

  @override
  State<AnimatedBoothDetailWrapper> createState() =>
      _AnimatedBoothDetailWrapperState();
}

class _AnimatedBoothDetailWrapperState
    extends State<AnimatedBoothDetailWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: BoothDetails(
          booth: widget.booth,
          onClose: widget.onClose,
          selectedAllergens: widget.selectedAllergens,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Main Food Page
// ─────────────────────────────────────────────
class FoodPage extends StatefulWidget {
  final String? selectedMapLetter;

  const FoodPage({this.selectedMapLetter, super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  // ── State variables ──
  String selectedLocation = 'All';
  List<FoodBooth> filteredBooths = foodBooths;
  Set<String> selectedPayments = {};
  bool? veganOnly = false;
  Set<String> excludedAllergens = {};
  List<FoodBooth> safeBooths = [];
  List<FoodBooth> unsafeBoothsWithAllergens = [];
  Set<String> selectedAllergens = {};
  List<FoodBooth> safeVeganBooths = [];
  List<FoodBooth> nonVeganBooths = [];
  bool _isFilterPopupOpen = false;
  String? currentMapLetter;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ── Lifecycle ──
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    currentMapLetter = widget.selectedMapLetter;
    _applyInitialMapFilter();
    filteredBooths.sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  void didUpdateWidget(FoodPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMapLetter != oldWidget.selectedMapLetter) {
      currentMapLetter = widget.selectedMapLetter;
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ── Helpers ──
  void _onSearchChanged() => _applyFilters();

  void _applyInitialMapFilter() {
    setState(() {
      filteredBooths = currentMapLetter != null
          ? foodBooths
              .where((b) => b.mapPageFoodLocation == currentMapLetter)
              .toList()
          : List<FoodBooth>.from(foodBooths);
    });
  }

  // ── Section title helpers ──
  String get safeSectionTitle {
    if (veganOnly! && selectedAllergens.isNotEmpty) {
      return '✅ Vegetarian & Allergen-Safe Options';
    } else if (veganOnly!) {
      return '✅ Vegetarian Options';
    } else if (selectedAllergens.isNotEmpty) {
      return '✅ Allergen-Safe Options';
    }
    return '✅ All Options';
  }

  String get unsafeSectionTitle {
    if (veganOnly! && selectedAllergens.isNotEmpty) {
      return '⚠️ Contains Allergens Or Not Vegetarian';
    } else if (veganOnly!) {
      return '⚠️ Not Vegetarian';
    } else if (selectedAllergens.isNotEmpty) {
      return '⚠️ May Contain Allergens';
    }
    return '⚠️ Other Booths';
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          Column(
            children: [
              // Safe-area + header space using fixed padding
              SizedBox(height: topInset + 80),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: _buildMainContent(),
                ),
              ),
            ],
          ),
          _buildLocationToggle(),
          TopActionButtons(
            isSearching: _isSearching,
            onSearchPressed: () {
              setState(() => _isSearching = true);
              _searchFocusNode.requestFocus();
            },
            onFilterPressed: () {
              if (!_isFilterPopupOpen) _showFilterPopup();
            },
          ),
          if (_isSearching)
            CustomSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              topPadding: topInset + 80,
              onChanged: (_) => setState(() {}),
              onCancel: () {
                setState(() {
                  _searchController.clear();
                  _isSearching = false;
                });
                _searchFocusNode.unfocus();
              },
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Background gradient
  // ─────────────────────────────────────────────
  Widget _buildBackgroundGradient() {
    return Container(color: const Color(0xFFECE0CF));
  }

  // ─────────────────────────────────────────────
  // Main scrollable content
  // ─────────────────────────────────────────────
  Widget _buildMainContent() {
    final isWide = MediaQuery.of(context).size.width > 1200;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 1300 : double.infinity),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                _buildAllBoothsSection(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Booths section (safe / unsafe split)
  // ─────────────────────────────────────────────
  Widget _buildAllBoothsSection() {
    final bool showSplitSections =
        safeBooths.isNotEmpty || unsafeBoothsWithAllergens.isNotEmpty;

    final List<FoodBooth> boothsToShow = showSplitSections
        ? [...safeBooths, ...unsafeBoothsWithAllergens]
        : filteredBooths;

    // Empty state
    if (boothsToShow.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.search_off,
              size: 60, color: Theme.of(context).disabledColor),
          const SizedBox(height: 20),
          Text(
            'No food booths found',
            style: Theme.of(context)
                .textTheme
                .titleLarge!
                .copyWith(color: Theme.of(context).disabledColor),
          ),
          const SizedBox(height: 10),
          Text(
            'Try different search terms or filters',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: Theme.of(context).disabledColor),
          ),
          const SizedBox(height: 40),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Map section label
        if (widget.selectedMapLetter != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Showing booths in section ${widget.selectedMapLetter}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // Safe booths
        if (showSplitSections && safeBooths.isNotEmpty) ...[
          Text(safeSectionTitle,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 30),
          _buildBoothGrid(safeBooths),
        ],

        // Unsafe booths
        if (showSplitSections && unsafeBoothsWithAllergens.isNotEmpty) ...[
          const SizedBox(height: 30),
          Text(unsafeSectionTitle,
              style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 30),
          _buildBoothGrid(unsafeBoothsWithAllergens, faded: true),
        ] else if (!showSplitSections) ...[
          _buildBoothGrid(filteredBooths),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Booth card grid
  // ─────────────────────────────────────────────
  Widget _buildBoothGrid(List<FoodBooth> booths, {bool faded = false}) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: booths.length,
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 400,
      mainAxisSpacing: 24,
      crossAxisSpacing: 24,
      mainAxisExtent: 340, // Fixed height for alignment
    ),
    itemBuilder: (context, index) => _buildBoothCard(booths[index], faded),
  );
}

Widget _buildBoothCard(FoodBooth booth, bool faded) {
  return GestureDetector(
    onTap: () => _showBoothDetails(context, booth),
    child: Opacity(
      opacity: faded ? 0.5 : 1.0,
      child: Container(
        // Shadcn Style: 1px border instead of heavy shadow
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                children: [
                  Image.network(
                    booth.boothImagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  // Overlay Badge for Genre (Shadcn Badge style)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booth.genre,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Text Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booth.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        booth.boothLocation,
                        style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Horizontal list of tiny icons/tags for details
                  Row(
                    children: [
                      _buildMiniTag(Icons.payments_outlined, booth.payments.first),
                      const SizedBox(width: 8),
                      if (booth.dishes.any((d) => d.isVegan))
                        _buildMiniTag(Icons.eco_outlined, 'Vegetarian Opt'),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Shadcn-style mini tag
Widget _buildMiniTag(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        Icon(icon, size: 12, color: Colors.black87),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}
  // ─────────────────────────────────────────────
  // Booth detail bottom sheet
  // ─────────────────────────────────────────────
  void _showBoothDetails(BuildContext context, FoodBooth booth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.only(top: 16), // fixed margin, no screen size
        child: AnimatedBoothDetailWrapper(
          booth: booth,
          onClose: () => Navigator.of(ctx).pop(),
          selectedAllergens: selectedAllergens.toList(),
        ),
      ),
    ).then((_) {
      _applyFilters();
      _searchFocusNode.unfocus();
    });
  }

  // ─────────────────────────────────────────────
  // Filter popup
  // ─────────────────────────────────────────────
  void _showFilterPopup() {
    if (_isFilterPopupOpen) return;
    _isFilterPopupOpen = true;

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;

      final isTablet = MediaQuery.of(context).size.width >= 600;

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'FilterPopup',
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
        transitionBuilder: (ctx, anim, _, __) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOut);

          return FadeTransition(
            opacity: curved,
            child: Stack(
              children: [
                // Dismiss on background tap
                GestureDetector(
                  onTap: () => Navigator.of(ctx).maybePop(),
                  child: Container(
                    color: Colors.black
                        .withValues(alpha: curved.value * 0.5),
                  ),
                ),
                Center(
                  child: ScaleTransition(
                    scale: curved,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        // Fixed max constraints — no screen size dependency
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 500 : 400,
                          maxHeight: isTablet ? 700 : 600,
                        ),
                        margin: EdgeInsets.symmetric(
                            horizontal: isTablet ? 30 : 24),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                          vertical: isTablet ? 16 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26, blurRadius: 10),
                          ],
                        ),
                        child: StatefulBuilder(
                          builder: (context, setModalState) =>
                              _buildFilterContent(
                                  isTablet, ctx, setModalState),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).then((_) => _isFilterPopupOpen = false);
    });
  }

  // Filter popup content extracted for readability
  Widget _buildFilterContent(
    bool isTablet,
    BuildContext ctx,
    StateSetter setModalState,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 12 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontSize: isTablet ? 24 : 20),
              ),
              IconButton(
                icon: Icon(Icons.close, size: isTablet ? 28 : 24),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),

        // Scrollable filter options
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 12 : 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: isTablet ? 12 : 5),
                Center(child: _buildSectionTitle('Payment')),
                SizedBox(height: isTablet ? 16 : 10),
                PaymentFilterRow(
                  selectedPayments: selectedPayments,
                  onPaymentSelected: (method, isSel) {
                    setModalState(() => isSel
                        ? selectedPayments.add(method)
                        : selectedPayments.remove(method));
                  },
                ),
                SizedBox(height: isTablet ? 20 : 12),
                Center(child: _buildSectionTitle('Vegetarian')),
                SizedBox(height: isTablet ? 16 : 12),
                VeganFilterOption(
                  isVegan: veganOnly ?? false,
                  onChanged: (v) => setModalState(() => veganOnly = v),
                ),
                SizedBox(height: isTablet ? 20 : 10),
                Center(child: _buildSectionTitle('Allergens')),
                SizedBox(height: isTablet ? 16 : 8),
                AllergyFilterGrid(
                  selectedAllergens: selectedAllergens,
                  onAllergenSelected: (all, isSel) {
                    setModalState(() => isSel
                        ? selectedAllergens.add(all)
                        : selectedAllergens.remove(all));
                  },
                ),
                SizedBox(height: isTablet ? 24 : 16),
              ],
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
            vertical: isTablet ? 16 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Reset button — fixed padding
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 16 : 12,
                    horizontal: isTablet ? 32 : 24,
                  ),
                  elevation: isTablet ? 12 : 10,
                ).copyWith(
                  shadowColor: WidgetStateProperty.all(
                      Colors.black.withValues(alpha: 0.3)),
                ),
                onPressed: () {
                  setState(() {
                    selectedPayments.clear();
                    veganOnly = false;
                    selectedAllergens.clear();
                  });
                  setModalState(() {
                    selectedPayments.clear();
                    veganOnly = false;
                    selectedAllergens.clear();
                  });
                  _applyFilters();
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: isTablet ? 17 : 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              _buildApplyButton(
                onApply: _applyFilters,
                closeModal: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Section title pill widget
  // ─────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Container(
      width: isTablet ? 160 : 120,
      height: isTablet ? 40 : 30,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: isTablet ? 8 : 5,
          ),
        ],
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Apply filters button
  // ─────────────────────────────────────────────
  Widget _buildApplyButton({
    required VoidCallback onApply,
    required VoidCallback closeModal,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        elevation: 10,
      ).copyWith(
        shadowColor: WidgetStateProperty.all(
            Colors.redAccent.withValues(alpha: 0.5)),
      ),
      onPressed: () {
        onApply();
        closeModal();
      },
      child: const Text(
        'Apply Filters',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Location toggle button
  // ─────────────────────────────────────────────
  Widget _buildLocationToggle() {
    final topInset = MediaQuery.of(context).padding.top;

    return Positioned(
      left: 20,
      top: topInset + 15,
      child: PopupMenuButton<String>(
        initialValue: selectedLocation,
        onSelected: (value) {
          setState(() {
            selectedLocation = value;
            _applyFilters();
          });
        },
        offset: const Offset(0, 55),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        itemBuilder: (_) => [
          _buildLocationMenuItem('All', Icons.location_on, Colors.grey),
          _buildLocationMenuItem(
              'Commons', Icons.location_city, Colors.blue),
          _buildLocationMenuItem(
              'Downtown', Icons.location_city, Colors.orange),
        ],
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            selectedLocation == 'All'
                ? Icons.location_on
                : Icons.location_city,
            size: 24,
            color: selectedLocation == 'Commons'
                ? Colors.blue
                : selectedLocation == 'Downtown'
                    ? Colors.orange
                    : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildLocationMenuItem(
      String value, IconData icon, Color color) {
    final bool isSelected = selectedLocation == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.black87,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 18, color: color),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Filter logic
  // ─────────────────────────────────────────────
  void _applyFilters() {
    setState(() {
      safeBooths = [];
      unsafeBoothsWithAllergens = [];
      safeVeganBooths = [];
      nonVeganBooths = [];
      filteredBooths = [];

      final searchQuery = _searchController.text.toLowerCase();

      final baseList = currentMapLetter != null
          ? foodBooths
              .where((b) => b.mapPageFoodLocation == currentMapLetter)
              .toList()
          : List<FoodBooth>.from(foodBooths);

      for (final booth in baseList) {
        // Location filter
        if (selectedLocation != 'All' &&
            booth.location != selectedLocation) continue;

        // Search filter
        if (searchQuery.isNotEmpty) {
          final matches = booth.name.toLowerCase().contains(searchQuery) ||
              booth.boothLocation.toLowerCase().contains(searchQuery) ||
              booth.genre.toLowerCase().contains(searchQuery) ||
              booth.dishes.any((d) =>
                  d.name.toLowerCase().contains(searchQuery) ||
                  d.description.toLowerCase().contains(searchQuery));
          if (!matches) continue;
        }

        // Payment filter
        if (selectedPayments.isNotEmpty &&
            !booth.payments.any((p) => selectedPayments.contains(p))) {
          continue;
        }

        // Vegan / allergen logic
        final hasVeganDish = booth.dishes.any((d) => d.isVegan);
        final allHaveAllergens = booth.dishes.every(
            (d) => d.allergens.any((a) => selectedAllergens.contains(a)));
        final hasSafeDish = booth.dishes.any(
            (d) => !d.allergens.any((a) => selectedAllergens.contains(a)));

        if (selectedAllergens.isNotEmpty && veganOnly == true) {
          (hasVeganDish && hasSafeDish ? safeBooths : unsafeBoothsWithAllergens)
              .add(booth);
          continue;
        }
        if (selectedAllergens.isNotEmpty) {
          (allHaveAllergens ? unsafeBoothsWithAllergens : safeBooths)
              .add(booth);
          continue;
        }
        if (veganOnly == true) {
          (hasVeganDish ? safeVeganBooths : nonVeganBooths).add(booth);
          continue;
        }

        filteredBooths.add(booth);
      }

      // Assemble final list
      if (selectedAllergens.isNotEmpty) {
        filteredBooths = [...safeBooths];
      } else if (veganOnly == true) {
        filteredBooths = [...safeVeganBooths];
      }

      // Sort all lists
      for (final list in [
        filteredBooths,
        safeBooths,
        unsafeBoothsWithAllergens,
        safeVeganBooths,
      ]) {
        list.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }
}