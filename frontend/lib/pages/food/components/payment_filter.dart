import 'dart:ui';
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
    const payments = ["Apple Pay", "Credit Card", "Cash", "Venmo", "Zelle", "PayPal"];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Adjust spacing based on width
        final double spacing = width > 600 ? 20 : 12;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: payments.map((method) {
            final isSelected = selectedPayments.contains(method);
            return _ShadcnPaymentItem(
              method: method,
              isSelected: isSelected,
              onTap: () => onPaymentSelected(method, !isSelected),
              parentWidth: width,
            );
          }).toList(),
        );
      },
    );
  }
}

class _ShadcnPaymentItem extends StatelessWidget {
  final String method;
  final bool isSelected;
  final VoidCallback onTap;
  final double parentWidth;

  const _ShadcnPaymentItem({
    required this.method,
    required this.isSelected,
    required this.onTap,
    required this.parentWidth,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = parentWidth > 600;
    final double boxSize = isTablet ? 70 : 54;
    final double iconSize = isTablet ? 32 : 24;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF4F4F5) : Colors.transparent,
              borderRadius: BorderRadius.circular(12), // Shadcn Radius
              border: Border.all(
                color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE4E4E7),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/payments/${method.toLowerCase().replaceAll(' ', '_')}.png',
                width: iconSize,
                height: iconSize,
                color: isSelected ? null : const Color(0xFFA1A1AA),
                colorBlendMode: isSelected ? null : BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            method.replaceAll(' ', '\n'), // Dynamic break
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 14 : 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF18181B) : const Color(0xFFA1A1AA),
              height: 1.1,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}