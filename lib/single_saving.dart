import 'package:final_project/constants.dart';
import 'package:flutter/material.dart';

class SingleSaving extends StatelessWidget {
  const SingleSaving({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                bottom: 50,
                right: 20,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back, color: primaryText),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "Travel",
                    style: kTextTheme.headlineSmall,
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
                      Icons.notifications_none_outlined,
                      color: primaryBg,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
                  ),
                  color: primaryText,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 45,
                    left: 50,
                    right: 50,
                    bottom: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Section
                      SizedBox(
                        height: 160,
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Goal",
                                  style: kTextTheme.bodySmall
                                      ?.copyWith(color: primaryBg),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "\$1,900.00",
                                  style: kTextTheme.headlineMedium
                                      ?.copyWith(color: primaryBg),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Amount Saved",
                                  style: kTextTheme.bodySmall
                                      ?.copyWith(color: primaryBg),
                                ),
                                Text(
                                  "\$654.00",
                                  style: kTextTheme.headlineMedium
                                      ?.copyWith(color: primaryBg),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: brandGreen,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(50),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.flight,
                                      color: primaryText,
                                      size: 80,
                                    ),
                                    Text(
                                      "Travel",
                                      style: kTextTheme.bodyLarge
                                          ?.copyWith(color: primaryText),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Progress Bar Section
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 10,
                              decoration: BoxDecoration(
                                color: primaryBg.withOpacity(0.2),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(5),
                                ),
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
                            "\$1,900.00",
                            style: kTextTheme.bodyMedium
                                ?.copyWith(color: primaryBg),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          "30% Of The Goal Saved",
                          style: kTextTheme.bodyMedium
                              ?.copyWith(color: primaryBg),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "Transactions",
                        style:
                            kTextTheme.bodyLarge?.copyWith(color: primaryBg),
                      ),
                      // Scrollable List of Deposits

                      //main content
                      Expanded(
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return depositList();
                          },
                        ),
                      ),

                      // Fixed Add More Button
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 10),
                          child: GestureDetector(
                            onTap: () {
                              addDialog(context);
                            },
                            child: Container(
                              height: 36,
                              width: 169,
                              decoration: const BoxDecoration(
                                color: brandGreen,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(30),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "Add Savings",
                                  style: kTextTheme.bodyMedium
                                      ?.copyWith(color: primaryText),
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

  // Deposit List Item Widget
  static Widget depositList() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          Container(
            height: 53,
            width: 57,
            decoration: const BoxDecoration(
              color: brandGreen,
              borderRadius: BorderRadius.all(Radius.circular(15)),
            ),
            child: const Icon(Icons.flight, size: 15, color: primaryText),
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Travel Deposit",
                style: kTextTheme.bodyMedium?.copyWith(color: primaryBg),
              ),
              Row(
                children: [
                  Text(
                    "19:00",
                    style: kTextTheme.bodySmall?.copyWith(color: Colors.blue),
                  ),
                  Text(
                    " - ",
                    style: kTextTheme.bodySmall?.copyWith(color: Colors.blue),
                  ),
                  Text(
                    "April 12",
                    style: kTextTheme.bodySmall?.copyWith(color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            "\$217.00",
            style: kTextTheme.bodyMedium?.copyWith(color: primaryBg),
          ),
        ],
      ),
    );
  }

  void addDialog(BuildContext context) {
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
                    hintStyle:
                        kTextTheme.bodyMedium?.copyWith(color: primaryText.withOpacity(0.5)),
                  ),
                  style: kTextTheme.bodyMedium,
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
                  child: Text("Cancel", style: kTextTheme.bodyMedium),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
