import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  _BudgetsPageState createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
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
        title: const Text("Add New Budget"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: "Category"),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Budgeted Amount"),
            ),
            const SizedBox(height: 16),
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
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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
            child: const Text("Add"),
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
      backgroundColor: const Color(0xff052224),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Center(
                        child: Text(
                          "Budgets",
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
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Budget",
                          style: TextStyle(color: Colors.white)),
                      SizedBox(height: 4),
                      Text(
                        "\$${totalBudget.toStringAsFixed(2)}",
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
                    color: Color(0xffDFF7E2),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Expense",
                          style: TextStyle(color: Colors.white)),
                      SizedBox(height: 4),
                      Text(
                        "\$${totalExpenses.toStringAsFixed(2)}",
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
            ),
            SizedBox(height: 10),
            // Budgets Section
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView.builder(
                    itemCount: budgets.length,
                    itemBuilder: (context, index) {
                      final budget = budgets[index];
                      return GestureDetector(
                        onTap: () => navigateToExpenses(budget['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xff1A4D4A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                budget['category'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Amount: \$${budget['amount']}",
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "End Date: ${budget['endDate']}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
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
                    backgroundColor: const Color(0xff00D09E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 12,
                    ),
                  ),
                  onPressed: addBudget,
                  child: const Text(
                    "Add Expense",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff093030),
                    ),
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
        title: const Text("Add Expense"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Amount"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff052224),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    "${budgetDetails['Category']} Budget",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xffDFF7E2),
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
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Budget",
                          style: TextStyle(color: Colors.white)),
                      SizedBox(height: 4),
                      Text(
                        "\$${budgetDetails['Total amount']}",
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
                    color: Color(0xffDFF7E2),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Expense",
                          style: TextStyle(color: Colors.white)),
                      SizedBox(height: 4),
                      Text(
                        " \$${totalExpenses.toStringAsFixed(2)}",
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
            ),
            SizedBox(height: 10),
            // Budget Details Section
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                            final formattedDate = DateFormat.yMMMd()
                                .format(date); // Format the Date
                            final formattedTime =
                                DateFormat.Hm().format(date); // Format the Time

                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Color(0xff0E3E3E),
                                borderRadius: BorderRadius.circular(8.0),
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
                                          style: TextStyle(
                                            fontSize: 18.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  formattedDate,
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                                SizedBox(height: 4.0),
                                                Text(
                                                  formattedTime,
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.white70,
                                                  ),
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
                                    padding: EdgeInsets.only(
                                        left:
                                            8.0), // Add padding for space between amount and text
                                    child: Text(
                                      "\$${expense['amount']}",
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 19),
                        child: Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff00D09E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 12,
                              ),
                            ),
                            onPressed: addExpense,
                            child: const Text(
                              "Add Expense",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff093030),
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
}
