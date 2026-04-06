import 'package:flutter/material.dart';
import 'components/payment_filter.dart';
import 'components/vegan_filter.dart';
import 'components/allergy_filter.dart';
import 'components/booth_details.dart';
import '../../data/food_booths.dart';
import '../../models/food_booth.dart';
import 'components/top_action_buttons.dart';
import 'components/search_bar.dart';

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

class FoodPage extends StatefulWidget {
  final String? selectedMapLetter;

  const FoodPage({this.selectedMapLetter, super.key});

  @override
  State<FoodPage> createState() => _FoodPageState();
}

class _FoodPageState extends State<FoodPage> {
  String selectedLocation = 'All';
  List<FoodBooth> filteredBooths = foodBooths;
  Set<String> selectedPayments = {};
  bool? veganOnly = false;
  Set<String> excludedAllergens = {};
  List<FoodBooth> safeBooths = [];
  List<FoodBooth> unsafeBoothsWithAllergens = [];
  Set<String> selectedAllergens = {};
  List<FoodBooth> safeVeganBooths = [], nonVeganBooths = [];
  bool _isFilterPopupOpen = false;
  String? currentMapLetter;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    currentMapLetter = widget.selectedMapLetter;
    _applyInitialMapFilter();
    filteredBooths.sort((a, b) => a.name.compareTo(b.name));
  }

  void _applyInitialMapFilter() {
    if (currentMapLetter != null) {
      setState(() {
        filteredBooths = foodBooths
            .where((booth) => booth.mapPageFoodLocation == currentMapLetter)
            .toList();
      });
    } else {
      setState(() {
        filteredBooths = foodBooths;
      });
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

  void _onSearchChanged() {
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final topPadding = MediaQuery.of(context).size.height * 0.082;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          Column(
            children: [
              SizedBox(
                height:
                    MediaQuery.of(context).padding.top +
                    topPadding +
                    MediaQuery.of(context).size.height * 0.015,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: _buildMainContent(screenWidth, screenHeight),
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
              topPadding:
                  MediaQuery.of(context).padding.top +
                  (MediaQuery.of(context).size.height * 0.085) +
                  32.5,
              onChanged: (value) {
                setState(() {});
              },
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

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B3775).withValues(alpha: 0.15),
            const Color(0xFFBF1D23).withValues(alpha: 0.15),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(double screenWidth, double screenHeight) {
    double maxWidth = screenWidth > 1200 ? 1300 : screenWidth * 0.95;
    double padding = screenWidth < 600 ? 16 : 24;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                _buildAllBoothsSection(screenWidth),
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String getSafeSectionTitle() {
    if (veganOnly! && selectedAllergens.isNotEmpty) {
      return "✅ Vegetarian & Allergen-Safe Options";
    } else if (veganOnly!) {
      return "✅ Vegetarian Options";
    } else if (selectedAllergens.isNotEmpty) {
      return "✅ Allergen-Safe Options";
    } else {
      return "✅ All Options";
    }
  }

  String getUnsafeSectionTitle() {
    if (veganOnly! && selectedAllergens.isNotEmpty) {
      return "⚠️ Contains Allergens Or Not Vegetarian";
    } else if (veganOnly!) {
      return "⚠️ Not Vegetarian";
    } else if (selectedAllergens.isNotEmpty) {
      return "⚠️ May Contain Allergens";
    } else {
      return "⚠️ Other Booths";
    }
  }

  Widget _buildAllBoothsSection(double screenWidth) {
    final bool showSplitSections =
        safeBooths.isNotEmpty || unsafeBoothsWithAllergens.isNotEmpty;
    final List<FoodBooth> boothsToShow = showSplitSections
        ? [...safeBooths, ...unsafeBoothsWithAllergens]
        : filteredBooths;

    if (boothsToShow.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.search_off, size: 60, color: Theme.of(context).disabledColor),
          const SizedBox(height: 20),
          Text(
            "No food booths found",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Try different search terms or filters",
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
        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
        if (widget.selectedMapLetter != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
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
        if (showSplitSections && safeBooths.isNotEmpty) ...[
          Text(
            getSafeSectionTitle(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 30),
          _buildBoothGrid(safeBooths, screenWidth),
        ],
        if (showSplitSections && unsafeBoothsWithAllergens.isNotEmpty) ...[
          const SizedBox(height: 30),
          Text(
            getUnsafeSectionTitle(),
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 30),
          _buildBoothGrid(unsafeBoothsWithAllergens, screenWidth, faded: true),
        ] else if (!showSplitSections) ...[
          _buildBoothGrid(filteredBooths, screenWidth),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBoothGrid(
    List<FoodBooth> booths,
    double screenWidth, {
    bool faded = false,
  }) {
    return Center(
      child: Wrap(
        spacing: 12,
        runSpacing: MediaQuery.of(context).size.height * 0.035,
        alignment: WrapAlignment.center,
        children: booths.map((booth) {
          return GestureDetector(
            onTap: () => _showBoothDetails(context, booth),
            child: Opacity(
              opacity: faded ? 0.5 : 1.0,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                padding: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.2,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        ),
                        image: DecorationImage(
                          image: NetworkImage(booth.boothImagePath),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      booth.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Food Booth: ${booth.boothLocation}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        booth.genre,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showBoothDetails(BuildContext context, FoodBooth booth) {
    final height = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.only(top: height * 0.02),
          child: AnimatedBoothDetailWrapper(
            booth: booth,
            onClose: () => Navigator.of(ctx).pop(),
            selectedAllergens: selectedAllergens.toList(),
          ),
        );
      },
    ).then((_) {
      _applyFilters();
      _searchFocusNode.unfocus();
    });
  }

  void _showFilterPopup() {
    if (_isFilterPopupOpen) return;
    _isFilterPopupOpen = true;

    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;

      final screenSize = MediaQuery.of(context).size;
      final isTablet = screenSize.width >= 600;
      final popupWidth = screenSize.width * (isTablet ? 0.8 : 0.85);
      final popupHeight = screenSize.height * (isTablet ? 0.85 : 0.785);

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'FilterPopup',
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, __, ___) => const SizedBox.shrink(),
        transitionBuilder: (context, anim, _, __) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);

          return FadeTransition(
            opacity: curved,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
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
                        width: popupWidth,
                        height: popupHeight,
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
                          builder: (context, setModalState) {
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Filters",
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .copyWith(
                                              fontSize: isTablet ? 24 : 20,
                                            ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.close,
                                          size: isTablet ? 28 : 24,
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                ),

                                // Scrollable body
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isTablet ? 24 : 16,
                                      vertical: isTablet ? 12 : 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(height: isTablet ? 12 : 5),
                                        Center(
                                          child: _buildSectionTitle("Payment"),
                                        ),
                                        SizedBox(height: isTablet ? 16 : 10),
                                        PaymentFilterRow(
                                          selectedPayments: selectedPayments,
                                          onPaymentSelected: (method, isSel) {
                                            setModalState(() {
                                              if (isSel)
                                                selectedPayments.add(method);
                                              else
                                                selectedPayments.remove(method);
                                            });
                                          },
                                        ),
                                        SizedBox(height: isTablet ? 20 : 12),
                                        Center(
                                          child: _buildSectionTitle("Vegetarian"),
                                        ),
                                        SizedBox(height: isTablet ? 16 : 12),
                                        VeganFilterOption(
                                          isVegan: veganOnly ?? false,
                                          onChanged: (v) => setModalState(
                                            () => veganOnly = v,
                                          ),
                                        ),
                                        SizedBox(height: isTablet ? 20 : 10),
                                        Center(
                                          child: _buildSectionTitle("Allergens"),
                                        ),
                                        SizedBox(height: isTablet ? 16 : 8),
                                        AllergyFilterGrid(
                                          selectedAllergens: selectedAllergens,
                                          onAllergenSelected: (all, isSel) {
                                            setModalState(() {
                                              if (isSel)
                                                selectedAllergens.add(all);
                                              else
                                                selectedAllergens.remove(all);
                                            });
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: screenSize.height *
                                                (isTablet ? 0.02 : 0.017),
                                            horizontal: screenSize.width *
                                                (isTablet ? 0.08 : 0.06),
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
                                            veganOnly = false;
                                            selectedAllergens.clear();
                                          });
                                          setModalState(() {
                                            selectedPayments.clear();
                                            veganOnly = false;
                                            selectedAllergens.clear();
                                          });
                                          _applyFilters();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          "Reset",
                                          style: TextStyle(
                                            fontSize: isTablet ? 17 : 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      _buildApplyButton(
                                        addedText: "Apply Filters",
                                        onApply: _applyFilters,
                                        closeModal: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ).then((_) {
        _isFilterPopupOpen = false;
      });
    });
  }

  Widget _buildSectionTitle(String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    final double horizontalPadding = isTablet ? 32.0 : 24.0;
    final double containerWidth = isTablet ? 160.0 : 120.0;
    final double containerHeight = isTablet ? 40.0 : 30.0;
    final double borderRadius = isTablet ? 30.0 : 25.0;
    final double blurRadius = isTablet ? 8.0 : 5.0;
    final double fontSize = isTablet ? 24.0 : 20.0;
    final double bottomSpacing = isTablet ? 4.0 : 2.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: containerWidth,
              height: containerHeight,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: blurRadius,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: bottomSpacing),
        ],
      ),
    );
  }

  Widget _buildApplyButton({
    required VoidCallback onApply,
    required VoidCallback closeModal,
    required String addedText,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.017,
          horizontal: MediaQuery.of(context).size.width * 0.06,
        ),
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
        "Apply Filters",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      safeBooths = [];
      unsafeBoothsWithAllergens = [];
      safeVeganBooths = [];
      nonVeganBooths = [];
      filteredBooths = [];

      final searchQuery = _searchController.text.toLowerCase();

      // 1) Start from the map-filtered list
      final baseList = (currentMapLetter != null)
          ? foodBooths
              .where((b) => b.mapPageFoodLocation == currentMapLetter)
              .toList()
          : List<FoodBooth>.from(foodBooths);

      // 2) Run through baseList
      for (var booth in baseList) {
        // Location filter
        if (selectedLocation != 'All' && booth.location != selectedLocation) {
          continue;
        }

        // Search filter
        if (searchQuery.isNotEmpty) {
          final matchesName = booth.name.toLowerCase().contains(searchQuery);
          final matchesLocation =
              booth.boothLocation.toLowerCase().contains(searchQuery);
          final matchesGenre =
              booth.genre.toLowerCase().contains(searchQuery);
          final matchesDish = booth.dishes.any(
            (d) =>
                d.name.toLowerCase().contains(searchQuery) ||
                d.description.toLowerCase().contains(searchQuery),
          );
          if (!matchesName && !matchesLocation && !matchesGenre && !matchesDish) {
            continue;
          }
        }

        // Payment filter
        if (selectedPayments.isNotEmpty &&
            !booth.payments.any((p) => selectedPayments.contains(p))) {
          continue;
        }

        // Vegan/allergen logic
        final hasVeganDish = booth.dishes.any((d) => d.isVegan);
        final allHaveAllergens = booth.dishes.every(
          (d) => d.allergens.any((a) => selectedAllergens.contains(a)),
        );
        final hasSafeDish = booth.dishes.any(
          (d) => !d.allergens.any((a) => selectedAllergens.contains(a)),
        );

        if (selectedAllergens.isNotEmpty && veganOnly == true) {
          if (hasVeganDish && hasSafeDish)
            safeBooths.add(booth);
          else
            unsafeBoothsWithAllergens.add(booth);
          continue;
        }
        if (selectedAllergens.isNotEmpty) {
          if (allHaveAllergens)
            unsafeBoothsWithAllergens.add(booth);
          else
            safeBooths.add(booth);
          continue;
        }
        if (veganOnly == true) {
          if (hasVeganDish)
            safeVeganBooths.add(booth);
          else
            nonVeganBooths.add(booth);
          continue;
        }

        filteredBooths.add(booth);
      }

      // 3) Assemble final filteredBooths list
      if (selectedAllergens.isNotEmpty && veganOnly == true) {
        filteredBooths = [...safeBooths];
      } else if (selectedAllergens.isNotEmpty) {
        filteredBooths = [...safeBooths];
      } else if (veganOnly == true) {
        filteredBooths = [...safeVeganBooths];
      }

      filteredBooths.sort((a, b) => a.name.compareTo(b.name));
      safeBooths.sort((a, b) => a.name.compareTo(b.name));
      unsafeBoothsWithAllergens.sort((a, b) => a.name.compareTo(b.name));
      safeVeganBooths.sort((a, b) => a.name.compareTo(b.name));
    });
  }
Widget _buildLocationToggle() {
  final topPadding = MediaQuery.of(context).padding.top;

  return Positioned(
    left: 20,
    top: topPadding + 15,
    child: PopupMenuButton<String>(
      initialValue: selectedLocation,
      onSelected: (String value) {
        setState(() {
          selectedLocation = value;
          _applyFilters();
        });
      },
      // ← Drop menu DOWN below button
      offset: const Offset(0, 55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      itemBuilder: (BuildContext context) => [
        _buildLocationMenuItem('All', Icons.location_on, Colors.grey),
        _buildLocationMenuItem('Commons', Icons.location_city, Colors.blue),
        _buildLocationMenuItem('Downtown', Icons.location_city, Colors.orange),
      ],
      // ← Same styling as search/hamburger buttons
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
              : selectedLocation == 'Commons'
                  ? Icons.location_city
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
    String value,
    IconData icon,
    Color color,
  ) {
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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
}