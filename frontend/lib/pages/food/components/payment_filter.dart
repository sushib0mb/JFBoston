import 'package:flutter/material.dart';

class PaymentFilterRow extends StatelessWidget {
  final Set<String> selectedPayments;
  final void Function(String, bool) onPaymentSelected;

  const PaymentFilterRow({
    required this.selectedPayments,
    required this.onPaymentSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // detect tablet
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet     = screenWidth >= 600;

    final payments = [
      "Apple Pay",
      "Credit Card",
      "Cash",
      "Venmo",
      "Zelle",
      "PayPal",
    
    ];

    final half = (payments.length / 2).ceil();
    final firstRowPayments  = payments.sublist(0, half);
    final secondRowPayments = payments.sublist(half);

    // spacing between items
    final rowSpacing = isTablet ? 24.0 : 16.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: firstRowPayments.map((method) {
            final selected = selectedPayments.contains(method);
            return _PaymentFilterItem(
              method: method,
              isSelected: selected,
              onTap: () => onPaymentSelected(method, !selected),
              isTablet: isTablet,
            );
          }).toList(),
        ),
        SizedBox(height: rowSpacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: secondRowPayments.map((method) {
            final selected = selectedPayments.contains(method);
            return _PaymentFilterItem(
              method: method,
              isSelected: selected,
              onTap: () => onPaymentSelected(method, !selected),
              isTablet: isTablet,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PaymentFilterItem extends StatelessWidget {
  final String method;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isTablet;

  const _PaymentFilterItem({
    required this.method,
    required this.isSelected,
    required this.onTap,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    // scaled sizes
    final double containerSize = isTablet ? 60 : 40;
    final double iconSize      = isTablet ? 60 : 44;
    final double borderRadius  = containerSize / 2;
    final double fontSize      = isTablet ? 25 : 16;
    final double labelHeight   = isTablet ? 70 : 40;
    final double verticalGap   = isTablet ? 8 : 4;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // icon background
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
              border: Border.all(
                color: isSelected
                    ? const Color.fromARGB(255, 255, 217, 0)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/payments/${method.toLowerCase().replaceAll(' ', '_')}.png',
                width: iconSize,
                height: iconSize,
                color: isSelected ? null : Colors.grey.withOpacity(0.5),
                colorBlendMode: BlendMode.modulate,
              ),
            ),
          ),

          SizedBox(height: verticalGap),

          // label
          SizedBox(
            height: labelHeight,
            child: Padding(
              padding: EdgeInsets.only(bottom: verticalGap),
              child: Text(
                // break long labels
                method == "Credit Card"
                    ? "Credit\nCard"
                    : method == "Apple Pay"
                        ? "Apple\nPay"
                        : method,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  color: isSelected ? Colors.black : Colors.grey[400],
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}