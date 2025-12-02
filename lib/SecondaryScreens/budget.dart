import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Constants/typograpy.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Budget extends StatefulWidget {
  const Budget({super.key});

  @override
  _BudgetState createState() => _BudgetState();
}

class _BudgetState extends State<Budget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? currentUser;
  List<Map<String, dynamic>> budgets = [];
  double totalBudget = 0.0;
  double totalExpenses = 0.0;

  @override
  void initState() {
    super.initState();
    loadCurrentUser();
  }

  // Load the currently signed-in user
  void loadCurrentUser() {
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      fetchBudgets();
      calculateTotals();
    } else {
      debugPrint("No user is signed in.");
    }
  }

  // Fetch budgets from Firestore
  void fetchBudgets() async {
    final budgetsSnapshot = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('Budgets')
        .get();

    setState(() {
      budgets = budgetsSnapshot.docs
          .map((doc) => {
                "id": doc.id,
                "category": doc['Category'],
                "amount": doc['Total amount'],
                "endDate": doc['end date']
              })
          .toList();
    });

    // Recalculate totals after fetching budgets
    calculateTotals();
  }

  // Calculate the totals for budgets and expenses
  Future<void> calculateTotals() async {
    if (currentUser == null) return;

    double budgetSum = 0.0;
    double expensesSum = 0.0;

    // Fetch all budgets
    final budgetsSnapshot = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('Budgets')
        .get();

    for (var budgetDoc in budgetsSnapshot.docs) {
      budgetSum += budgetDoc['Total amount'];

      // Fetch expenses for each budget
      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('Budgets')
          .doc(budgetDoc.id)
          .collection('Expenses')
          .get();

      for (var expenseDoc in expensesSnapshot.docs) {
        expensesSum += expenseDoc['amount'];
      }
    }

    // Update the state with calculated totals
    setState(() {
      totalBudget = budgetSum;
      totalExpenses = expensesSum;
    });
  }

  // Add a new budget
  void addBudget() async {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();
    DateTime? selectedDate;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primaryBg,
        title: Text("Add New Budget", style: kTextTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category"),
              style: kTextTheme.bodyMedium,
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Budgeted Amount"),
              style: kTextTheme.bodyMedium,
            ),
            const SizedBox(height: spacerMedium),
            TextButton(
              onPressed: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedDate = pickedDate;
                  });
                }
              },
              child: Text(
                selectedDate == null
                    ? "Select End Date"
                    : "Selected: ${selectedDate?.toLocal()}".split(' ')[0],
                style: kTextTheme.bodyMedium?.copyWith(color: brandGreen),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel", style: kTextTheme.bodyMedium),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandGreen),
            onPressed: () async {
              if (categoryController.text.isNotEmpty &&
                  amountController.text.isNotEmpty &&
                  selectedDate != null) {
                final newBudget = {
                  "Category": categoryController.text,
                  "Total amount": double.parse(amountController.text),
                  "end date": selectedDate!.toIso8601String(),
                };

                await _firestore
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('Budgets')
                    .add(newBudget);

                fetchBudgets(); // Refresh the budgets
                Navigator.pop(context);
              }
            },
            child: Text("Add",
                style: kTextTheme.bodyMedium?.copyWith(color: primaryText)),
          ),
        ],
      ),
    );
  }

  // Navigate to daily expenses page
  void navigateToExpenses(String budgetId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetDetailsPage(budgetId: budgetId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(top: spacerMedium, left: spacerMedium, right: spacerMedium),
              child: Column(
                children: [
                  Row(
                    children: [
                      Center(
                        child: Text(
                          "Budgets",
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
                      )
                    ],
                  ),
                                    const SizedBox(height: spacerSmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacerMedium, vertical: spacerSmall),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Budget", style: kTextTheme.bodyLarge),
                      const SizedBox(height: spacerTiny),
                      Text(
                        "\$${totalBudget.toStringAsFixed(2)}",
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
                      Text("Total Expense", style: kTextTheme.bodyLarge),
                      const SizedBox(height: spacerTiny),
                      Text(
                        "\$${totalExpenses.toStringAsFixed(2)}",
                        style: kTextTheme.headlineMedium
                            ?.copyWith(color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
                              const SizedBox(height: spacerSmall),
            // Budgets Section
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
                child: Padding(
                  padding: paddingAllMedium,
                  child: ListView.builder(
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      return GestureDetector(
                        onTap: () => navigateToExpenses(budget['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: spacerMedium),
                          padding: paddingAllMedium,
                          decoration: BoxDecoration(
                            color: primaryText.withOpacity(0.8),
                            borderRadius: radiusMedium,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget['category'],
                                style: kTextTheme.titleLarge
                                    ?.copyWith(color: primaryBg),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Amount: \$${budget['amount']}",
                                style: kTextTheme.bodyMedium
                                    ?.copyWith(color: primaryBg),
                              ),
                              Text(
                                "End Date: ${budget['endDate']}",
                                style: kTextTheme.bodyMedium
                                    ?.copyWith(color: primaryBg.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Add More Button
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 19),
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50.0,
                      vertical: spacerMedium,
                    ),
                  ),
                  onPressed: addBudget,
                  child: Text(
                    "Add Budget",
                    style: kTextTheme.bodyMedium?.copyWith(color: primaryText),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetDetailsPage extends StatefulWidget {
  final String budgetId;

  const BudgetDetailsPage({required this.budgetId, super.key});

  @override
  _BudgetDetailsPageState createState() => _BudgetDetailsPageState();
}

class _BudgetDetailsPageState extends State<BudgetDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String budgetId;
  Map<String, dynamic> budgetDetails = {};
  List<Map<String, dynamic>> expenses = [];
  double totalExpenses = 0;

  @override
  void initState() {
    super.initState();
    budgetId = widget.budgetId;
    fetchBudgetDetails();
  }

  // Fetch budget details and expenses
  void fetchBudgetDetails() async {
    final budgetSnapshot = await _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('Budgets')
        .doc(budgetId)
        .get();

    final expensesSnapshot = await _firestore
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('Budgets')
        .doc(budgetId)
        .collection('Expenses')
        .get();

    double expensesTotal = 0;
    for (var doc in expensesSnapshot.docs) {
      expensesTotal += doc['amount'];
    }

    setState(() {
      budgetDetails = {
        "Category": budgetSnapshot['Category'],
        "Total amount": budgetSnapshot['Total amount'],
        "end date": budgetSnapshot['end date'],
      };
      expenses = expensesSnapshot.docs
          .map((doc) => {
                "id": doc.id,
                "description": doc['description'],
                "amount": doc['amount'],
                "date": doc['date'],
              })
          .toList();
      totalExpenses = expensesTotal;
    });
  }

  // Add a new expense
  void addExpense() async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primaryBg,
        title: Text("Add Expense", style: kTextTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              style: kTextTheme.bodyMedium,
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
              style: kTextTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel", style: kTextTheme.bodyMedium),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandGreen),
            onPressed: () async {
              if (descriptionController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                final newExpense = {
                  "description": descriptionController.text,
                  "amount": double.parse(amountController.text),
                  "date": DateTime.now().toIso8601String(),
                };

                await _firestore
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('Budgets')
                    .doc(budgetId)
                    .collection('Expenses')
                    .add(newExpense);

                fetchBudgetDetails(); // Refresh expenses and total
                Navigator.pop(context);
              }
            },
            child: Text("Add",
                style: kTextTheme.bodyMedium?.copyWith(color: primaryText)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacerMedium, vertical: spacerMedium),
              child: Row(
                children: [
                  Text(
                    "${budgetDetails['Category']} Budget",
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
                      Icons.notifications_none,
                      color: primaryBg,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacerMedium, vertical: spacerSmall),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Budget", style: kTextTheme.bodyLarge),
                      const SizedBox(height: spacerTiny),
                      Text(
                        "\$${budgetDetails['Total amount']}",
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
                      Text("Total Expense", style: kTextTheme.bodyLarge),
                      const SizedBox(height: spacerTiny),
                      Text(
                        " \$${totalExpenses.toStringAsFixed(2)}",
                        style: kTextTheme.headlineMedium
                            ?.copyWith(color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
                              const SizedBox(height: spacerSmall),
            // Budget Details Section
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
                child: Padding(
                  padding: paddingAllMedium,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];

                            // Parse the string to DateTime before formatting
                            final date = DateTime.parse(expense['date']);
                            final formattedDate =
                                DateFormat.yMMMd().format(date); // Format the Date
                            final formattedTime =
                                DateFormat.Hm().format(date); // Format the Time

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: spacerSmall),
                              padding: paddingAllMedium,
                              decoration: BoxDecoration(
                                color: primaryText.withOpacity(0.8),
                                borderRadius: radiusSmall,
                              ),
                              child: Row(
                                children: [
                                  // Column for description, date, and time
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          expense['description'],
                                          style: kTextTheme.titleLarge
                                              ?.copyWith(color: primaryBg),
                                        ),
                                        const SizedBox(height: spacerSmall),
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  formattedDate,
                                                  style: kTextTheme.bodySmall
                                                      ?.copyWith(
                                                          color: primaryBg
                                                              .withOpacity(0.7)),
                                                ),
                                                const SizedBox(height: spacerTiny),
                                                Text(
                                                  formattedTime,
                                                  style: kTextTheme.bodySmall
                                                      ?.copyWith(
                                                          color: primaryBg
                                                              .withOpacity(0.7)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Amount aligned to the far right
                                  Padding(
                                    padding: const EdgeInsets.only(left: spacerSmall),
                                    child: Text(
                                      "\$${expense['amount']}",
                                      style: kTextTheme.bodyMedium
                                          ?.copyWith(color: primaryBg.withOpacity(0.7)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: spacerSmall, bottom: 19.0),
                        child: Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 12,
                              ),
                            ),
                            onPressed: addExpense,
                            child: Text(
                              "Add Expense",
                              style: kTextTheme.bodyMedium
                                  ?.copyWith(color: primaryText),
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
}
