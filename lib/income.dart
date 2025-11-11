import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Income extends StatelessWidget {
  const Income({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff052224),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                bottom: 20,
                right: 20,
              ),
              child: Row(
                children: [
                  const Text(
                    "Income",
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
                      Icons.notifications_none_outlined,
                      color: Color(0xff093030),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Total Income',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('incomes')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Calculating...',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      '\$0.00',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  // Safely calculate total income
                  double totalIncome = 0.0;
                  for (var doc in snapshot.data!.docs) {
                    // Ensure the document contains the 'amount' field
                    var data = doc.data() as Map<String, dynamic>?;
                    if (data != null &&
                        data.containsKey('amount') &&
                        data['amount'] != null) {
                      // Safely cast and add the amount to the total
                      totalIncome += (data['amount'] as num).toDouble();
                    }
                  }

                  return Text(
                    '\$${totalIncome.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 40),
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
                  padding: const EdgeInsets.only(
                    top: 45,
                    left: 50,
                    right: 50,
                    bottom: 10,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: double.infinity,
                          child: _buildIncomeList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 19),
                        child: GestureDetector(
                          onTap: () {
                            _showAddIncomeDialog(context);
                          },
                          child: Container(
                            height: 36,
                            width: 169,
                            decoration: const BoxDecoration(
                              color: Color(0xff00D09E),
                              borderRadius: BorderRadius.all(
                                Radius.circular(30),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                "Add Income",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff093030),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          "User not authenticated!",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('incomes')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No income transactions found.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final incomeDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: incomeDocs.length,
          itemBuilder: (context, index) {
            final data = incomeDocs[index];
            final description = data['description'] ?? 'No description';
            final amount = data['amount'] != null
                ? (data['amount'] as num).toStringAsFixed(2)
                : '0.00'; // Skip documents with no amount
            final timestamp = data['timestamp']?.toDate();

            final dateTimeString = timestamp != null
                ? "${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}"
                : "Unknown date";

            return ListTile(
              title: Text(
                description,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                dateTimeString,
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Text(
                "\$$amount",
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddIncomeDialog(BuildContext context) {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Income"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                ),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final description = descriptionController.text;
                final amount = double.tryParse(amountController.text);
                if (description.isEmpty || amount == null) {
                  Fluttertoast.showToast(
                    msg: "Please provide valid inputs!",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                  return;
                }

                await _addIncome(description, amount);
                Navigator.pop(context);
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addIncome(String description, double amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Fluttertoast.showToast(
          msg: "User not authenticated!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('incomes')
          .add({
        'description': description.isNotEmpty ? description : 'No description',
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Fluttertoast.showToast(
        msg: "Income added successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to add income: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
