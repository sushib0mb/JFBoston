import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/food_booths.dart';
import '../../models/food_booth.dart';
import 'components/payment_filter.dart';
import 'components/vegetarian_filter.dart';
import 'components/allergy_filter.dart';
import 'components/booth_details.dart';
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

class _AnimatedBoothDetailWrapperState extends State<AnimatedBoothDetailWrapper>
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
  String selectedLocation = 'Commons';
  List<FoodBooth> filteredBooths = foodBooths;
  Set<String> selectedPayments = {};
  bool? vegetarianOnly = false;
  Set<String> excludedAllergens = {};
  List<FoodBooth> safeBooths = [];
  List<FoodBooth> unsafeBoothsWithAllergens = [];
  Set<String> selectedAllergens = {};
  List<FoodBooth> safeVegetarianBooths = [];
  List<FoodBooth> nonVegetarianBooths = [];
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-apply filters whenever FoodService notifies (data loaded/updated)
    Provider.of<FoodService>(context);
    if (foodBooths.isNotEmpty && filteredBooths.isEmpty) {
      _applyFilters();
    }
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
      filteredBooths =
          currentMapLetter != null
              ? foodBooths
                  .where((b) => b.mapPageFoodLocation == currentMapLetter)
                  .toList()
              : List<FoodBooth>.from(foodBooths);
    });
  }

  // ── Section title helpers ──
  String get safeSectionTitle {
    if (vegetarianOnly! && selectedAllergens.isNotEmpty) {
      return '✅ Vegetarian & Allergen-Safe Options';
    } else if (vegetarianOnly!) {
      return '✅ Vegetarian Options';
    } else if (selectedAllergens.isNotEmpty) {
      return '✅ Allergen-Safe Options';
    }
    return '✅ All Options';
  }

  String get unsafeSectionTitle {
    if (vegetarianOnly! && selectedAllergens.isNotEmpty) {
      return '⚠️ Contains Allergens Or Not Vegetarian';
    } else if (vegetarianOnly!) {
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
              SizedBox(height: topInset + (_isSearching ? 134 : 84)),
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
            Positioned(
              top: topInset + 80,
              left: 0,
              right: 0,
              child: CustomSearchBar(
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
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [_buildAllBoothsSection(), const SizedBox(height: 40)],
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
    if (selectedLocation == 'Downtown') {
      return Column(
        children: [
          const SizedBox(height: 40),
          Image.asset("assets/JFBDowntownPoster.png"),
          const SizedBox(height: 20),
          Text(
            "We've got Japanese sake and food available at Downtown Crossing! Come stop by and enjoy authentic Japanese flavors along with great music 🎶",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),
        ],
      );
    }

    final bool showSplitSections =
        safeBooths.isNotEmpty || unsafeBoothsWithAllergens.isNotEmpty;

    final bool noActiveFilters =
        selectedLocation == 'Commons' &&
        selectedPayments.isEmpty &&
        selectedAllergens.isEmpty &&
        (vegetarianOnly != true) &&
        _searchController.text.isEmpty;

    final List<FoodBooth> boothsToShow =
        showSplitSections
            ? [...safeBooths, ...unsafeBoothsWithAllergens]
            : (filteredBooths.isEmpty && noActiveFilters
                ? (List<FoodBooth>.from(foodBooths)
                  ..sort((a, b) => a.name.compareTo(b.name)))
                : filteredBooths);

    // Empty state
    if (boothsToShow.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.search_off,
            size: 60,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 20),
          Text(
            'No food booths found',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Try different search terms or filters',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 40),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        // Safe booths
        if (showSplitSections && safeBooths.isNotEmpty) ...[
          Text(
            safeSectionTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 30),
          _buildBoothGrid(safeBooths),
        ],

        // Unsafe booths
        if (showSplitSections && unsafeBoothsWithAllergens.isNotEmpty) ...[
          const SizedBox(height: 30),
          Text(
            unsafeSectionTitle,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
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
    return Column(
      children: [
        for (int i = 0; i < booths.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: _buildBoothCard(booths[i], faded),
          ),
      ],
    );
  }

  Widget _buildBoothCard(FoodBooth booth, bool faded) {
    return GestureDetector(
      onTap: () => _showBoothDetails(context, booth),
      child: Opacity(
        opacity: faded ? 0.5 : 1.0,
        child: Container(
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
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Image.network(
                      booth.boothImagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          booth.genre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Text + Logo Section
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left column: logo
                    if (booth.logoPath.isNotEmpty)
                      Container(
                        // 1. Increased the container footprint
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(right: 12),
                        // 2. Reduced padding so the logo has more room to breathe
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          // Scaled the radius slightly to match the larger size
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                        // 3. Using ClipRRect so the image corners match the container corners
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            booth.logoPath,
                            // 4. BoxFit.contain is safest for logos to prevent cropping,
                            // but since we increased the Container size, the logo will naturally be larger.
                            fit: BoxFit.contain,
                            errorBuilder:
                                (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    // Right column: name, location, payments
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booth.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  booth.boothLocation,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (booth.payments.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: booth.payments
                                  .map((p) => _buildMiniTag(Icons.payments_outlined, p))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: Colors.black54),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.black87),
          ),
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
      builder:
          (ctx) => Container(
            margin: const EdgeInsets.only(
              top: 16,
            ), // fixed margin, no screen size
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
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);

          return FadeTransition(
            opacity: curved,
            child: Stack(
              children: [
                // Dismiss on background tap
                GestureDetector(
                  onTap: () => Navigator.of(ctx).maybePop(),
                  child: Container(
                    color: Colors.black.withValues(alpha: curved.value * 0.5),
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
                          horizontal: isTablet ? 30 : 24,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 24 : 16,
                          vertical: isTablet ? 16 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10),
                          ],
                        ),
                        child: StatefulBuilder(
                          builder:
                              (context, setModalState) => _buildFilterContent(
                                isTablet,
                                ctx,
                                setModalState,
                              ),
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
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(fontSize: isTablet ? 24 : 20),
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
                SizedBox(height: isTablet ? 16 : 10),
                Center(child: _buildSectionTitle('Payment')),
                SizedBox(height: isTablet ? 20 : 16),
                PaymentFilterRow(
                  selectedPayments: selectedPayments,
                  onPaymentSelected: (method, isSel) {
                    setModalState(
                      () =>
                          isSel
                              ? selectedPayments.add(method)
                              : selectedPayments.remove(method),
                    );
                  },
                ),
                SizedBox(height: isTablet ? 28 : 22),
                Center(child: _buildSectionTitle('Vegetarian')),
                SizedBox(height: isTablet ? 20 : 16),
                VegetarianFilterOption(
                  isVegetarian: vegetarianOnly ?? false,
                  onChanged: (v) => setModalState(() => vegetarianOnly = v),
                ),
                SizedBox(height: isTablet ? 28 : 22),
                Center(child: _buildSectionTitle('Allergens')),
                SizedBox(height: isTablet ? 20 : 16),
                AllergyFilterGrid(
                  selectedAllergens: selectedAllergens,
                  onAllergenSelected: (all, isSel) {
                    setModalState(
                      () =>
                          isSel
                              ? selectedAllergens.add(all)
                              : selectedAllergens.remove(all),
                    );
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
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 16 : 12,
                    horizontal: isTablet ? 32 : 24,
                  ),
                  elevation: isTablet ? 12 : 10,
                ).copyWith(
                  shadowColor: WidgetStateProperty.all(
                    Colors.black.withValues(alpha: 0.3),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    selectedPayments.clear();
                    vegetarianOnly = false;
                    selectedAllergens.clear();
                  });
                  setModalState(() {
                    selectedPayments.clear();
                    vegetarianOnly = false;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        elevation: 10,
      ).copyWith(
        shadowColor: WidgetStateProperty.all(
          Colors.redAccent.withValues(alpha: 0.5),
        ),
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
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            selectedLocation =
                selectedLocation == 'Commons' ? 'Downtown' : 'Commons';
            _applyFilters();
          });
        },
        icon: const Icon(Icons.swap_horiz, color: Colors.black87),
        label: Text(
          selectedLocation, // Displays the currently selected location
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
        ),
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
      safeVegetarianBooths = [];
      nonVegetarianBooths = [];
      filteredBooths = [];

      final searchQuery = _searchController.text.toLowerCase();

      final baseList =
          currentMapLetter != null
              ? foodBooths
                  .where((b) => b.mapPageFoodLocation == currentMapLetter)
                  .toList()
              : List<FoodBooth>.from(foodBooths);

      for (final booth in baseList) {
        // Location filter
        if (selectedLocation != 'All' && booth.location != selectedLocation)
          continue;

        // Search filter
        if (searchQuery.isNotEmpty) {
          final matches =
              booth.name.toLowerCase().contains(searchQuery) ||
              booth.boothLocation.toLowerCase().contains(searchQuery) ||
              booth.genre.toLowerCase().contains(searchQuery) ||
              booth.dishes.any(
                (d) => d.name.toLowerCase().contains(searchQuery),
              );
          if (!matches) continue;
        }

        // Payment filter
        if (selectedPayments.isNotEmpty &&
            !booth.payments.any((p) => selectedPayments.contains(p))) {
          continue;
        }

        // Cegetarian / allergen logic
        final hasVegetarianDish = booth.dishes.any((d) => d.isVegetarian);
        final allHaveAllergens = booth.dishes.every(
          (d) => d.allergens.any((a) => selectedAllergens.contains(a)),
        );
        final hasSafeDish = booth.dishes.any(
          (d) => !d.allergens.any((a) => selectedAllergens.contains(a)),
        );

        if (selectedAllergens.isNotEmpty && vegetarianOnly == true) {
          (hasVegetarianDish && hasSafeDish
                  ? safeBooths
                  : unsafeBoothsWithAllergens)
              .add(booth);
          continue;
        }
        if (selectedAllergens.isNotEmpty) {
          (allHaveAllergens ? unsafeBoothsWithAllergens : safeBooths).add(
            booth,
          );
          continue;
        }
        if (vegetarianOnly == true) {
          (hasVegetarianDish ? safeVegetarianBooths : nonVegetarianBooths).add(
            booth,
          );
          continue;
        }

        filteredBooths.add(booth);
      }

      // Assemble final list
      if (selectedAllergens.isNotEmpty) {
        filteredBooths = [...safeBooths];
      } else if (vegetarianOnly == true) {
        filteredBooths = [...safeVegetarianBooths];
      }

      // Sort all lists
      for (final list in [
        filteredBooths,
        safeBooths,
        unsafeBoothsWithAllergens,
        safeVegetarianBooths,
      ]) {
        list.sort((a, b) => a.name.compareTo(b.name));
      }
    });
  }
}
