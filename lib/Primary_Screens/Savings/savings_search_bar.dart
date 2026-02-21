import 'package:flutter/material.dart';

class SavingsSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SavingsSearchBar({
    super.key,
    required this.controller,
    required this.searchText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search goals…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }
}
