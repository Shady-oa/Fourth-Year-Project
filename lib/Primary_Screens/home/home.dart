import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Components/quick_actions.dart';
import 'package:final_project/Components/them_toggle.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/cloudinary_service.dart';
import 'package:final_project/Primary_Screens/Savings/financial_service.dart';
import 'package:final_project/Primary_Screens/home/add_expense_sheet.dart';
import 'package:final_project/Primary_Screens/home/add_income_sheet.dart';
import 'package:final_project/Primary_Screens/home/balance_card.dart';
import 'package:final_project/Primary_Screens/home/prefs_keys.dart';
import 'package:final_project/Primary_Screens/home/profile_sheet.dart';
import 'package:final_project/Primary_Screens/home/top5_expenses_section.dart';
import 'package:final_project/Primary_Screens/home/transaction_confirmation_sheet.dart';
import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_services.dart';
import 'package:final_project/SecondaryScreens/Report/report_page.dart';
import 'package:final_project/SecondaryScreens/Transactions/all_transactions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ── Services & Firebase ──────────────────────────────────────────────────────
  final cloudinary = CloudinaryService(
    backendUrl: 'https://fourth-year-backend.onrender.com',
  );
  final String userUid = FirebaseAuth.instance.currentUser!.uid;
  final usersDB = FirebaseFirestore.instance.collection('users');

  // ── User profile ─────────────────────────────────────────────────────────────
  String? username;
  String? profileImage;
  StreamSubscription? _userSubscription;

  // ── Financial state ───────────────────────────────────────────────────────────
  List<Map<String, dynamic>> transactions = [];

  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double displayedSavingsAmount = 0.0;
  double _balance = 0.0;
  bool isLoading = true;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _listenToUserData();
    refreshData();
    LocalNotificationStore.init();
    SmartNotificationService.runAllChecks();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────────
  void _listenToUserData() {
    _userSubscription = usersDB.doc(userUid).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          username = data['username'] ?? '';
          profileImage = data['profileUrl'] ?? '';
        });
      }
    });
  }

  Future<void> refreshData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    transactions = List<Map<String, dynamic>>.from(
      json.decode(prefs.getString(PrefsKeys.transactions) ?? '[]'),
    );

    final summary = FinancialService.recalculateFromPrefs(prefs);
    totalIncome = summary.totalIncome;
    totalExpenses = summary.totalExpenses;
    displayedSavingsAmount = summary.displayedSavingsAmount;
    _balance = summary.balance;

    setState(() => isLoading = false);
  }

  // ── Transaction helpers ───────────────────────────────────────────────────────
  Future<void> _saveTransaction(
    String title,
    double amount,
    String type, {
    double transactionCost = 0.0,
    String reason = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    transactions.insert(0, {
      'title': title,
      'amount': amount,
      'type': type,
      'transactionCost': transactionCost,
      'reason': reason,
      'date': DateTime.now().toIso8601String(),
    });
    await prefs.setString(PrefsKeys.transactions, json.encode(transactions));

    final summary = FinancialService.recalculateFromPrefs(prefs);
    totalIncome = summary.totalIncome;
    totalExpenses = summary.totalExpenses;
    displayedSavingsAmount = summary.displayedSavingsAmount;
    _balance = summary.balance;
    setState(() {});

    _showTransactionToast(type, amount, transactionCost: transactionCost);
  }

  void _showTransactionToast(
    String type,
    double amount, {
    double transactionCost = 0.0,
  }) {
    final isIncome = type == 'income';
    final action = isIncome ? 'Income Added' : 'Expense Recorded';
    final totalDeducted = amount + transactionCost;
    final msg = transactionCost > 0
        ? '$action: ${CurrencyFormatter.format(totalDeducted)} (incl. ${CurrencyFormatter.format(transactionCost)} fee)'
        : '$action: ${CurrencyFormatter.format(amount)}';
    if (isIncome) {
      AppToast.success(context, msg);
    } else {
      AppToast.error(context, msg);
    }
  }

  Future<void> onBudgetTransactionAdded(
    String title,
    double amount,
    String type,
  ) async {
    await _saveTransaction(title, amount, type);
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
    await prefs.setString(PrefsKeys.transactions, json.encode(transactions));
    await refreshData();
  }

  // ── Derived data ──────────────────────────────────────────────────────────────
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


  // ── Profile image upload ──────────────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    final image = await cloudinary.pickImage();
    if (image == null) return;
    final url = await cloudinary.uploadFile(image);
    if (url == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userUid).update({
        'profileUrl': url,
      });
      if (mounted) {
        AppToast.success(context, 'Profile image changed successfully!');
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'An error occurred, please try again');
      }
    }
  }

  // ── Sheet launchers ───────────────────────────────────────────────────────────
  void _openIncomeSheet() {
    showAddIncomeSheet(
      context,
      onContinue: ({required title, required amount, required reason}) {
        showTransactionConfirmation(
          context,
          type: 'income',
          title: title,
          amount: amount,
          transactionCost: 0,
          reason: reason,
          currentBalance: _balance,
          onConfirm: () async {
            final prefs = await SharedPreferences.getInstance();
            totalIncome += amount;
            await prefs.setDouble(PrefsKeys.totalIncome, totalIncome);
            await _saveTransaction(title, amount, 'income', reason: reason);
            await refreshData();
          },
        );
      },
    );
  }

  void _openExpenseSheet() {
    showAddExpenseSheet(
      context,
      onContinue:
          ({
            required title,
            required amount,
            required transactionCost,
            required reason,
          }) {
            showTransactionConfirmation(
              context,
              type: 'expense',
              title: title,
              amount: amount,
              transactionCost: transactionCost,
              reason: reason,
              currentBalance: _balance,
              onConfirm: () async {
                await _saveTransaction(
                  title,
                  amount,
                  'expense',
                  transactionCost: transactionCost,
                  reason: reason,
                );
                await refreshData();
              },
            );
          },
    );
  }

  void _openProfileSheet() {
    showProfileSheet(
      context,
      username: username,
      profileImage: profileImage,
      onPickImage: _pickAndUploadImage,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(context),
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
                    BalanceCard(
                      balance: _balance,
                      totalIncome: totalIncome,
                      totalExpenses: totalExpenses,
                      savingsTotal: displayedSavingsAmount,
                    ),
                    sizedBoxHeightLarge,
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    sizedBoxHeightSmall,
                    _buildQuickActions(),
                    sizedBoxHeightLarge,
                    Top5ExpensesSection(top5Expenses: top5Expenses),
                    sizedBoxHeightLarge,
                  ],
                ),
              ),
            ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    String greetings() {
      final hour = DateTime.now().hour;
      if (hour < 12) return 'Good Morning';
      if (hour < 17) return 'Good Afternoon';
      return 'Good Evening';
    }

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      leading: GestureDetector(
        onTap: _openProfileSheet,
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
        onTap: _openProfileSheet,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greetings(), style: Theme.of(context).textTheme.headlineSmall),
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
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        QuickActionCard(
          icon: Icons.add,
          label: 'Add Income',
          onTap: _openIncomeSheet,
        ),
        QuickActionCard(
          icon: Icons.remove,
          label: 'Add Expense',
          onTap: _openExpenseSheet,
        ),
        QuickActionCard(
          icon: Icons.receipt_long,
          label: 'All Trans',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionsPage()),
            );
            refreshData();
          },
        ),
        QuickActionCard(
          icon: Icons.bar_chart_rounded,
          label: 'Reports',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportPage()),
          ),
        ),
      ],
    );
  }
}
