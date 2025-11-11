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
      backgroundColor: const Color(0xff052224),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Center(
                        child: Text(
                          "Savings",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xffDFF7E2),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 30,
                        width: 30,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffDFF7E2),
                        ),
                        child: const Icon(
                          Icons.notifications_none,
                          color: Color(0xff093030),
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
                        children: const [
                          Text(
                            "Balance",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "\$1,187.40",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: const Color(0xffDFF7E2),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Total Target",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "\$7,783.00",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
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
                            color: const Color(0xffDFF7E2),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xff00D09E),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "\$7,783.00",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: Color(0xffDFF7E2),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: const Text(
                        "18% of savings saved",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: Color(0xffDFF7E2),
                        ),
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
                  color: Color(0xff093030),
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
                          physics: NeverScrollableScrollPhysics(),
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
                              color: const Color(0xff00D09E),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(
                              child: Text(
                                "Add More",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff093030),
                                ),
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
              color: isSelected ? Colors.blue : const Color(0xFF1A4D4A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Flexible(child: Icon(icon, color: Colors.white, size: 40)), 
            ),
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: Text(
            label,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: const TextStyle(color: Colors.white),
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
          backgroundColor: Color(0xFF0E1D2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "New Category",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                TextField(
                  onChanged: (value) {
                    newCategory = value;
                  },
                  decoration: InputDecoration(
                    hintText: "Write...",
                    filled: true,
                    fillColor: Color(0xFF124152),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    if (newCategory.isNotEmpty) {
                      _addCategory(newCategory);
                    }
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7A87),
                  ),
                  child: Text("Save"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
