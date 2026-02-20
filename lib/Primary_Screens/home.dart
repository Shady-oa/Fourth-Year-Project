import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/AuthScreens/login.dart';
import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Components/quick_actions.dart';
import 'package:final_project/Components/them_toggle.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/cloudinary_service.dart';
import 'package:final_project/Primary_Screens/Savings/financial_service.dart';
import 'package:final_project/SecondaryScreens/all_transactions.dart';
import 'package:final_project/SecondaryScreens/report_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Currency formatting utility (local copy — full methods)
class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0', 'en_US');
  static final NumberFormat _decimalFmt = NumberFormat('#,##0.00', 'en_US');

  /// Whole-number format:  1234 → "Ksh 1,234"
  static String format(double amount) {
    final abs = amount.abs();
    final s = _formatter.format(abs.round());
    return amount < 0 ? '-Ksh $s' : 'Ksh $s';
  }

  /// Two-decimal format:  1234.5 → "Ksh 1,234.50"
  static String formatDecimal(double amount) {
    final abs = amount.abs();
    final s = _decimalFmt.format(abs);
    return amount < 0 ? '-Ksh $s' : 'Ksh $s';
  }

  static String compact(double amount) {
    final abs = amount.abs();
    String s;
    if (abs >= 1000000) {
      s = 'Ksh ${(abs / 1000000).toStringAsFixed(1)}M';
    } else if (abs >= 1000) {
      s = 'Ksh ${(abs / 1000).toStringAsFixed(1)}K';
    } else {
      s = format(abs);
    }
    return amount < 0 ? '-$s' : s;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String keyTransactions = 'transactions';
  static const String keyBudgets = 'budgets';
  static const String keySavings = 'savings';
  static const String keyTotalIncome = 'total_income';
  static const String keyStreakCount = 'streak_count';
  static const String keyLastSaveDate = 'last_save_date';
  static const String keyStreakLevel = 'streak_level';

  final cloudinary = CloudinaryService(
    backendUrl: 'https://fourth-year-backend.onrender.com',
  );
  final userUid = FirebaseAuth.instance.currentUser!.uid;
  final usersDB = FirebaseFirestore.instance.collection('users');
  String? username;
  String? profileImage;
  StreamSubscription? userSubscription;

  List<Map<String, dynamic>> transactions = [];
  List<Budget> budgets = [];
  List<Saving> savings = [];

  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  // displayedSavingsAmount: principal only (no fee) — for the statistics card.
  double displayedSavingsAmount = 0.0;
  // balance is stored directly from FinancialService to avoid re-derivation.
  double _balance = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
    refreshData();
  }

  @override
  void dispose() {
    userSubscription?.cancel();
    super.dispose();
  }

  void loadUserData() async {
    userSubscription = usersDB.doc(userUid).snapshots().listen((snapshots) {
      if (snapshots.exists) {
        final userData = snapshots.data() as Map<String, dynamic>;
        setState(() {
          username = userData['username'] ?? '';
          profileImage = userData['profileUrl'] ?? '';
        });
      }
    });
  }

  Future<void> refreshData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    final txString = prefs.getString(keyTransactions) ?? '[]';
    transactions = List<Map<String, dynamic>>.from(json.decode(txString));

    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    budgets = budgetStrings.map((s) => Budget.fromMap(json.decode(s))).toList();

    final savingsStrings = prefs.getStringList(keySavings) ?? [];
    savings = savingsStrings
        .map((s) => Saving.fromMap(json.decode(s)))
        .toList();

    totalIncome = prefs.getDouble(keyTotalIncome) ?? 0.0;

    // Use centralized financial calculation.
    final summary = FinancialService.recalculateFromPrefs(prefs);
    totalIncome = summary.totalIncome;
    totalExpenses = summary.totalExpenses;
    displayedSavingsAmount = summary.displayedSavingsAmount;
    _balance = summary.balance;

    checkSavingsDeadlines();
    setState(() => isLoading = false);
  }

  // calculateStats() removed — centralized in FinancialService.recalculateFromPrefs().

  Future<void> saveTransaction(
    String title,
    double amount,
    String type, {
    double transactionCost = 0.0,
    String reason = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final newTx = {
      'title': title,
      'amount': amount,
      'type': type,
      'transactionCost': transactionCost,
      'reason': reason,
      'date': DateTime.now().toIso8601String(),
    };
    transactions.insert(0, newTx);
    await prefs.setString(keyTransactions, json.encode(transactions));
    // Recalculate using centralized service so all totals stay in sync.
    final summary = FinancialService.recalculateFromPrefs(prefs);
    totalIncome = summary.totalIncome;
    totalExpenses = summary.totalExpenses;
    displayedSavingsAmount = summary.displayedSavingsAmount;
    _balance = summary.balance;
    setState(() {});
    showTransactionToast(type, amount, transactionCost: transactionCost);
  }

  void showTransactionToast(
    String type,
    double amount, {
    double transactionCost = 0.0,
  }) {
    final isIncome = type == 'income';
    final icon = isIncome ? '💰' : '💸';
    final action = isIncome ? 'Income Added' : 'Expense Recorded';
    final totalDeducted = amount + transactionCost;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    transactionCost > 0
                        ? '$action: ${CurrencyFormatter.format(totalDeducted)} (incl. ${CurrencyFormatter.format(transactionCost)} fee)'
                        : '$action: ${CurrencyFormatter.format(amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: isIncome ? brandGreen : Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 150,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool isTransactionLinkedToAchievedGoal(Map<String, dynamic> tx) {
    if (tx['type'] != 'savings_deduction' &&
        tx['type'] != 'savings_withdrawal') {
      return false;
    }
    final title = tx['title'] ?? '';
    for (var saving in savings) {
      if (title.contains(saving.name) && saving.achieved) return true;
    }
    return false;
  }

  bool isTransactionLinkedToCheckedBudget(Map<String, dynamic> tx) {
    if (tx['type'] != 'budget_finalized') return false;
    final budgetId = tx['budgetId'];
    if (budgetId == null) return false;
    for (var budget in budgets) {
      if (budget.id == budgetId && budget.isChecked) return true;
    }
    return false;
  }

  // ── Top 5 expenses ──────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get top5Expenses {
    final expenses = transactions
        .where(
          (tx) => tx['type'] == 'expense' || tx['type'] == 'budget_finalized',
        )
        .toList();
    expenses.sort((a, b) {
      final aTotal =
          (double.tryParse(a['amount'].toString()) ?? 0) +
          (double.tryParse(a['transactionCost']?.toString() ?? '0') ?? 0);
      final bTotal =
          (double.tryParse(b['amount'].toString()) ?? 0) +
          (double.tryParse(b['transactionCost']?.toString() ?? '0') ?? 0);
      return bTotal.compareTo(aTotal);
    });
    return expenses.take(5).toList();
  }

  Future<void> onSavingsTransactionAdded(
    String title,
    double amount,
    String type,
  ) async {
    await saveTransaction(title, amount, type);
    await updateStreak();
    await refreshData();
  }

  Future<void> onBudgetTransactionAdded(
    String title,
    double amount,
    String type,
  ) async {
    await saveTransaction(title, amount, type);
    await refreshData();
  }

  Future<void> onBudgetExpenseDeleted(String title, double amount) async {
    transactions.removeWhere(
      (tx) =>
          tx['title'] == title &&
          double.tryParse(tx['amount'].toString()) == amount &&
          tx['type'] == 'budget_expense',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyTransactions, json.encode(transactions));
    await refreshData();
  }

  String getStreakLevel(int count) {
    if (count == 0) return 'Base';
    if (count < 7) return 'Bronze';
    if (count < 30) return 'Silver';
    if (count < 90) return 'Gold';
    if (count < 180) return 'Platinum';
    return 'Diamond';
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    int streakCount = prefs.getInt(keyStreakCount) ?? 0;
    String lastSaveDateStr = prefs.getString(keyLastSaveDate) ?? '';

    if (lastSaveDateStr == todayStr) return;

    if (lastSaveDateStr.isNotEmpty) {
      final lastDate = DateFormat('yyyy-MM-dd').parse(lastSaveDateStr);
      final difference = now.difference(lastDate).inDays;
      streakCount = difference == 1 ? streakCount + 1 : 1;
    } else {
      streakCount = 1;
    }

    String streakLevel = getStreakLevel(streakCount);
    await prefs.setInt(keyStreakCount, streakCount);
    await prefs.setString(keyStreakLevel, streakLevel);
    await prefs.setString(keyLastSaveDate, todayStr);

    if (streakCount % 7 == 0) {
      sendNotification(
        '🔥 Streak Milestone!',
        'Amazing! You\'ve maintained a $streakCount day savings streak at $streakLevel level!',
      );
    }
  }

  void checkSavingsDeadlines() {
    for (var saving in savings) {
      if (saving.achieved) continue;
      final daysRemaining = saving.deadline.difference(DateTime.now()).inDays;
      if (daysRemaining < 0) {
        sendNotification(
          '⚠️ Savings Goal Overdue',
          'Your ${saving.name} goal is ${daysRemaining.abs()} days overdue. Current: ${CurrencyFormatter.format(saving.savedAmount)} / ${CurrencyFormatter.format(saving.targetAmount)}',
        );
      } else if (daysRemaining <= 3 && daysRemaining > 0) {
        sendNotification(
          '⏰ Savings Deadline Approaching',
          'Your ${saving.name} goal is due in $daysRemaining days. Current: ${CurrencyFormatter.format(saving.savedAmount)} / ${CurrencyFormatter.format(saving.targetAmount)}',
        );
      }
    }
  }

  Future<void> sendNotification(String title, String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .collection('notifications')
          .add({
            'title': title,
            'message': message,
            'createdAt': FieldValue.serverTimestamp(),
            'isRead': false,
          });
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // ── Add Income Dialog ──────────────────────────────────────────────────────────
  void showAddIncomeDialog() {
    final amountCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Income'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Source (e.g. Salary)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Amount (Ksh)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Reason (required)',
                  border: OutlineInputBorder(),
                  helperText: 'e.g. Monthly salary, freelance payment',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text) ?? 0;
              final reason = reasonCtrl.text.trim();
              if (amt > 0 && titleCtrl.text.isNotEmpty && reason.isNotEmpty) {
                Navigator.pop(context);
                _showTransactionConfirmation(
                  type: 'income',
                  title: titleCtrl.text.trim(),
                  amount: amt,
                  transactionCost: 0,
                  reason: reason,
                  onConfirm: () async {
                    final prefs = await SharedPreferences.getInstance();
                    totalIncome += amt;
                    await prefs.setDouble(keyTotalIncome, totalIncome);
                    await saveTransaction(
                      titleCtrl.text,
                      amt,
                      'income',
                      reason: reason,
                    );
                    refreshData();
                  },
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please fill all fields (amount, source & reason)',
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Continue ›'),
          ),
        ],
      ),
    );
  }

  // ── Add Expense Dialog ──────────────────────────────────────────────────────────
  void showGeneralExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final txCostCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'What was it for?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amtCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Amount (Ksh)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: txCostCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Transaction Cost (Ksh)',
                  border: OutlineInputBorder(),
                  helperText: 'e.g. M-Pesa fee (enter 0 if none)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Reason (required)',
                  border: OutlineInputBorder(),
                  helperText: 'e.g. Groceries for the week',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text) ?? 0;
              final txCost = double.tryParse(txCostCtrl.text) ?? 0;
              final reason = reasonCtrl.text.trim();

              if (amt <= 0 || titleCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a name and valid amount'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              if (txCostCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter transaction cost (0 if none)'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a reason'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              _showTransactionConfirmation(
                type: 'expense',
                title: titleCtrl.text.trim(),
                amount: amt,
                transactionCost: txCost,
                reason: reason,
                onConfirm: () async {
                  await saveTransaction(
                    titleCtrl.text,
                    amt,
                    'expense',
                    transactionCost: txCost,
                    reason: reason,
                  );
                  refreshData();
                },
              );
            },
            child: const Text('Continue ›'),
          ),
        ],
      ),
    );
  }

  // ── Transaction Confirmation Bottom Sheet ───────────────────────────────────
  //
  // Called after the input dialog is dismissed.  Shows a full summary for the
  // user to review before the transaction is written to SharedPreferences.
  // onConfirm is called ONLY when the user taps "Confirm & Save".
  void _showTransactionConfirmation({
    required String type,
    required String title,
    required double amount,
    required double transactionCost,
    required String reason,
    required Future<void> Function() onConfirm,
  }) {
    final isIncome = type == 'income';
    final total = amount + transactionCost;
    final newBalance = isIncome ? _balance + amount : _balance - total;
    final balanceChange = isIncome ? amount : -total;
    final balancePositive = balanceChange >= 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isIncome ? brandGreen : errorColor).withOpacity(
                          0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isIncome
                            ? Icons.arrow_circle_down_rounded
                            : Icons.arrow_circle_up_rounded,
                        color: isIncome ? brandGreen : errorColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirm Transaction',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isIncome ? 'Income' : 'Expense',
                          style: TextStyle(
                            color: isIncome ? brandGreen : errorColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Detail rows
                _confirmRow('Description', title),
                _confirmRow('Amount', CurrencyFormatter.formatDecimal(amount)),
                if (!isIncome && transactionCost > 0)
                  _confirmRow(
                    'Transaction Fee',
                    CurrencyFormatter.formatDecimal(transactionCost),
                  ),
                if (!isIncome && transactionCost > 0)
                  _confirmRow(
                    'Total Deducted',
                    CurrencyFormatter.formatDecimal(total),
                    highlight: true,
                  ),
                _confirmRow('Reason', reason),
                _confirmRow(
                  'Date',
                  DateFormat('d MMM yyyy, h:mm a').format(DateTime.now()),
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Balance impact
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (balancePositive ? brandGreen : errorColor)
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (balancePositive ? brandGreen : errorColor)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Balance After Transaction',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatDecimal(newBalance),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: newBalance < 0 ? errorColor : brandGreen,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: (balancePositive ? brandGreen : errorColor)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${balancePositive ? '+' : ''} ${CurrencyFormatter.formatDecimal(balanceChange)}',
                          style: TextStyle(
                            color: balancePositive ? brandGreen : errorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Go Back'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isIncome ? brandGreen : errorColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                setSheetState(() => isSaving = true);
                                await onConfirm();
                                if (ctx.mounted) Navigator.pop(ctx);
                              },
                        child: isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Confirm & Save',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _confirmRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                fontSize: highlight ? 15 : 13,
                color: highlight ? errorColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void pickAndUploadImage() async {
    File? image = await cloudinary.pickImage();
    if (image != null) {
      String? url = await cloudinary.uploadFile(image);
      if (url != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userUid)
              .update({'profileUrl': url});
          if (mounted) {
            showCustomToast(
              context: context,
              message: 'Profile image changed successfully!',
              backgroundColor: accentColor,
              icon: Icons.check_circle_outline_rounded,
            );
          }
        } catch (e) {
          if (mounted) {
            showCustomToast(
              context: context,
              message: 'An error occurred, please try again',
              backgroundColor: errorColor,
              icon: Icons.error,
            );
          }
        }
      }
    }
  }

  void showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: paddingAllMedium,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: paddingAllLarge,
                  decoration: BoxDecoration(
                    borderRadius: radiusLarge,
                    color: brandGreen,
                    boxShadow: [
                      BoxShadow(
                        color: brandGreen.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                (profileImage == null || profileImage!.isEmpty)
                                ? const AssetImage('assets/image/icon.png')
                                      as ImageProvider
                                : NetworkImage(profileImage!),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                pickAndUploadImage();
                              },
                              child: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.add_a_photo,
                                  size: 16,
                                  color: brandGreen,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username ?? 'Penny User',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Kisii, Kenya',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 16),
                _buildModernSettingsCard(
                  context: context,
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value:
                        Provider.of<ThemeProvider>(
                          context,
                          listen: true,
                        ).currentTheme.brightness ==
                        Brightness.dark,
                    onChanged: (_) {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).toggleTheme();
                    },
                    activeTrackColor: brandGreen.withOpacity(0.4),
                    activeThumbColor: brandGreen,
                  ),
                  onTap: () => Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggleTheme(),
                ),
                _buildModernSettingsCard(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'About Penny Wise',
                  onTap: () {
                    Navigator.pop(context);
                    showCustomToast(
                      context: context,
                      message:
                          'Penny Wise helps you track your expenses and budgets.',
                      backgroundColor: brandGreen,
                      icon: Icons.info_outline_rounded,
                    );
                  },
                ),
                _buildModernSettingsCard(
                  context: context,
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: () {
                    Navigator.pop(context);
                    showCustomToast(
                      context: context,
                      message: 'Logged out successfully!',
                      backgroundColor: accentColor,
                      icon: Icons.check_circle_outline_rounded,
                    );
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Login(showSignupPage: () {}),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernSettingsCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: radiusMedium,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: radiusMedium,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: radiusMedium,
              ),
              child: Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String greetings() {
      final int hour = DateTime.now().hour;
      if (hour < 12) return 'Good Morning';
      if (hour < 17) return 'Good Afternoon';
      return 'Good Evening';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: GestureDetector(
          onTap: showProfileBottomSheet,
          child: Row(
            children: [
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundImage: (profileImage == null)
                    ? const AssetImage('assets/image/icon.png')
                    : NetworkImage(profileImage!) as ImageProvider,
              ),
            ],
          ),
        ),
        title: GestureDetector(
          onTap: showProfileBottomSheet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greetings(),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                username ?? 'Penny User',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: paddingAllTiny,
            child: Row(children: [const ThemeToggleIcon(), NotificationIcon()]),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: paddingAllMedium,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildBalanceCard(),
                    sizedBoxHeightLarge,
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    sizedBoxHeightSmall,
                    buildQuickActions(),
                    sizedBoxHeightLarge,
                    buildTop5ExpensesSection(),
                    sizedBoxHeightLarge,
                  ],
                ),
              ),
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REDESIGNED BALANCE CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget buildBalanceCard() {
    // _balance comes directly from FinancialService — never re-derived locally.
    final balance = _balance;
    final isNegative = balance < 0;
    // Use displayedSavingsAmount (principal only, no fee) for the stats card.
    final savingsTotal = displayedSavingsAmount;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isNegative
              ? [errorColor, errorColor.withOpacity(0.8)]
              : [accentColor, accentColor.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isNegative ? errorColor : accentColor).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Total Balance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Main amount
                Text(
                  CurrencyFormatter.format(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                // Divider
                Divider(color: Colors.white.withOpacity(0.2), height: 1),
                const SizedBox(height: 16),
                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _balanceStat(
                        'Income',
                        totalIncome,
                        Icons.arrow_circle_down_rounded,
                      ),
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _balanceStat(
                        'Expenses',
                        totalExpenses,
                        Icons.arrow_circle_up_rounded,
                        center: true,
                      ),
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Expanded(
                      child: _balanceStat(
                        'Savings',
                        savingsTotal,
                        Icons.savings_outlined,
                        center: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceStat(
    String label,
    double amount,
    IconData icon, {
    bool center = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: center ? 0 : 0),
      child: Column(
        crossAxisAlignment: center
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: center
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.compact(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  QUICK ACTIONS (updated — removed old ones, added View All Reports)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        QuickActionCard(
          icon: Icons.add,
          label: 'Add Income',
          onTap: showAddIncomeDialog,
        ),
        QuickActionCard(
          icon: Icons.remove,
          label: 'Add Expense',
          onTap: showGeneralExpenseDialog,
        ),
        QuickActionCard(
          icon: Icons.receipt_long,
          label: 'All Trans',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TransactionsPage()),
            );
            refreshData();
          },
        ),
        QuickActionCard(
          icon: Icons.bar_chart_rounded,
          label: 'Reports',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReportPage()),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TOP 5 EXPENSES SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget buildTop5ExpensesSection() {
    final top = top5Expenses;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top 5 Expenses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportPage()),
                );
              },
              icon: const Icon(Icons.open_in_new, size: 14),
              label: const Text('View All Reports'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (top.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(15),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 32,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(width: 12),
                Text(
                  'No expenses yet. Add some transactions!',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...top.asMap().entries.map((entry) {
            final idx = entry.key;
            final tx = entry.value;
            final amount = double.tryParse(tx['amount'].toString()) ?? 0.0;
            final fee =
                double.tryParse(tx['transactionCost']?.toString() ?? '0') ??
                0.0;
            final total = amount + fee;

            final rankColors = [
              Colors.amber.shade400,
              Colors.grey.shade400,
              Colors.brown.shade300,
              errorColor.withOpacity(0.7),
              errorColor.withOpacity(0.5),
            ];

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: rankColors[idx].withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          color: rankColors[idx],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['title'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ((tx['reason'] ?? '').toString().isNotEmpty)
                          Text(
                            tx['reason'].toString(),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 0,
                    child: Text(
                      '- ${CurrencyFormatter.format(total)}',
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: errorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

// ─── Models ────────────────────────────────────────────────────────────────────
class Budget {
  String name, id;
  double total;
  List<Expense> expenses;
  bool isChecked;
  DateTime? checkedDate;
  DateTime createdDate;

  Budget({
    String? id,
    required this.name,
    required this.total,
    List<Expense>? expenses,
    this.isChecked = false,
    this.checkedDate,
    DateTime? createdDate,
  }) : expenses = expenses ?? [],
       id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdDate = createdDate ?? DateTime.now();

  double get totalSpent => expenses.fold(0.0, (s, e) => s + e.amount);
  double get amountLeft => total - totalSpent;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'total': total,
    'expenses': expenses.map((e) => e.toMap()).toList(),
    'isChecked': isChecked,
    'checkedDate': checkedDate?.toIso8601String(),
    'createdDate': createdDate.toIso8601String(),
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: map['name'],
    total: (map['total'] as num).toDouble(),
    expenses:
        (map['expenses'] as List?)?.map((e) => Expense.fromMap(e)).toList() ??
        [],
    isChecked: map['isChecked'] ?? map['checked'] ?? false,
    checkedDate: map['checkedDate'] != null
        ? DateTime.parse(map['checkedDate'])
        : null,
    createdDate: map['createdDate'] != null
        ? DateTime.parse(map['createdDate'])
        : DateTime.now(),
  );
}

class Expense {
  String name, id;
  double amount;
  DateTime createdDate;

  Expense({
    String? id,
    required this.name,
    required this.amount,
    DateTime? createdDate,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdDate = createdDate ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'amount': amount,
    'createdDate': createdDate.toIso8601String(),
  };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    name: map['name'],
    amount: (map['amount'] as num).toDouble(),
    createdDate: map['createdDate'] != null
        ? DateTime.parse(map['createdDate'])
        : DateTime.now(),
  );
}

class Saving {
  String name;
  double savedAmount, targetAmount;
  DateTime deadline;
  bool achieved;
  String walletType;
  String? walletName;
  DateTime lastUpdated;

  Saving({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    this.achieved = false,
    required this.walletType,
    this.walletName,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  double get balance => targetAmount - savedAmount;

  Map<String, dynamic> toMap() => {
    'name': name,
    'savedAmount': savedAmount,
    'targetAmount': targetAmount,
    'deadline': deadline.toIso8601String(),
    'achieved': achieved,
    'walletType': walletType,
    'walletName': walletName,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory Saving.fromMap(Map<String, dynamic> map) => Saving(
    name: map['name'] ?? 'Unnamed',
    savedAmount: map['savedAmount'] is String
        ? double.tryParse(map['savedAmount']) ?? 0.0
        : (map['savedAmount'] as num?)?.toDouble() ?? 0.0,
    targetAmount: map['targetAmount'] is String
        ? double.tryParse(map['targetAmount']) ?? 0.0
        : (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
    deadline: map['deadline'] != null
        ? DateTime.parse(map['deadline'])
        : DateTime.now().add(const Duration(days: 30)),
    achieved: map['achieved'] ?? false,
    walletType: map['walletType'] ?? 'M-Pesa',
    walletName: map['walletName'],
    lastUpdated: map['lastUpdated'] != null
        ? DateTime.parse(map['lastUpdated'])
        : DateTime.now(),
  );
}
