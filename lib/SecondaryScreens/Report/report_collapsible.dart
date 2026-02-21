import 'package:flutter/material.dart';

// ─── Collapsible Section ──────────────────────────────────────────────────────
class ReportCollapsible extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const ReportCollapsible({
    super.key,
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(
                expanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.grey.shade500,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          child: expanded ? child : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
