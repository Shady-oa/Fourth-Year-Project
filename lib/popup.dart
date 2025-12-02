import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';

class Save extends StatelessWidget {
  const Save({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      appBar: AppBar(
        title: Text("Savings",
            style: kTextTheme.headlineSmall?.copyWith(color: primaryBg)),
        backgroundColor: primaryText,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _showAddCategoryDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: brandGreen,
          ),
          child: Text("Add Category",
              style: kTextTheme.bodyMedium?.copyWith(color: primaryText)),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: primaryBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "New Category",
                  style: kTextTheme.headlineSmall,
                ),
                const SizedBox(height: 15),
                TextField(
                  decoration: InputDecoration(
                    hintText: "Write...",
                    filled: true,
                    fillColor: primaryText.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: TextStyle(color: primaryText.withOpacity(0.5)),
                  ),
                  style: const TextStyle(color: primaryText),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    // Save action
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Save",
                      style:
                          kTextTheme.bodyMedium?.copyWith(color: primaryText)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryText.withOpacity(0.1),
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Cancel",
                      style: kTextTheme.bodyMedium
                          ?.copyWith(color: primaryText)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
