import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';

class SavePage extends StatefulWidget {
  const SavePage({super.key});

  @override
  State<SavePage> createState() => _SavePageState();
}

class _SavePageState extends State<SavePage> {
  // List of categories
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.directions_car, 'label': 'Transport'},
    {'icon': Icons.medical_services, 'label': 'Medicine'},
    {'icon': Icons.local_grocery_store, 'label': 'Groceries'},
    {'icon': Icons.flight, 'label': 'Travel'},
    {'icon': Icons.school, 'label': 'Education'},
    {'icon': Icons.home, 'label': 'Rent'},
  ];

  // Function to add a new category
  void _addCategory(String label) {
    setState(() {
      _categories.add({'icon': Icons.category, 'label': label});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Center(
                        child: Text(
                          "Savings",
                          style: kTextTheme.headlineSmall,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 30,
                        width: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryText,
                        ),
                        child: const Icon(
                          Icons.notifications_none,
                          color: primaryBg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Balance",
                            style: kTextTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "\$1,187.40",
                            style: kTextTheme.headlineMedium,
                          ),
                        ],
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: primaryText,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Target",
                            style: kTextTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "\$7,783.00",
                            style: kTextTheme.headlineMedium
                                ?.copyWith(color: Colors.blue),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: primaryText.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: brandGreen,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "\$7,783.00",
                        style: kTextTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "18% of savings saved",
                        style: kTextTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            //main content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  color: primaryText,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 30,
                        ),
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          physics: const NeverScrollableScrollPhysics(),
                          children: _categories
                              .map(
                                (category) => buildCategoryItem(
                                  category['icon'],
                                  category['label'],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 19),
                        child: GestureDetector(
                          onTap: () {
                            addDialog(context);
                          },
                          child: Container(
                            height: 36,
                            width: 169,
                            decoration: BoxDecoration(
                              color: brandGreen,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                "Add More",
                                style: kTextTheme.bodyMedium
                                    ?.copyWith(color: primaryText),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryItem(
    IconData icon,
    String label, {
    bool isSelected = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/singlesaving');
          },
          child: Container(
            //height: 65,
            //width: 80,
            decoration: BoxDecoration(
              color: isSelected
                  ? brandGreen
                  : primaryText.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child:
                  Flexible(child: Icon(icon, color: primaryBg, size: 40)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: Text(
            label,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: kTextTheme.bodyMedium?.copyWith(color: primaryBg),
          ),
        ),
      ],
    );
  }

  void addDialog(BuildContext context) {
    String newCategory = "";

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
                  onChanged: (value) {
                    newCategory = value;
                  },
                  decoration: InputDecoration(
                    hintText: "Write...",
                    filled: true,
                    fillColor: primaryText.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle:
                        TextStyle(color: primaryText.withOpacity(0.5)),
                  ),
                  style: const TextStyle(color: primaryText),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    if (newCategory.isNotEmpty) {
                      _addCategory(newCategory);
                    }
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                  ),
                  child: Text("Save",
                      style:
                          kTextTheme.bodyMedium?.copyWith(color: primaryText)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
