import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/notification_icon.dart';
import 'package:final_project/Components/quick_actions.dart';
import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:final_project/Firebase/cloudinary_service.dart';
import 'package:final_project/Primary_Screens/Savings/financial_service.dart';
import 'package:final_project/Primary_Screens/home/add_expense_sheet.dart';
import 'package:final_project/Primary_Screens/home/add_income_sheet.dart';
import 'package:final_project/Primary_Screens/home/balance_card.dart';
import 'package:final_project/Primary_Screens/home/home_sync_service.dart';
import 'package:final_project/Primary_Screens/home/prefs_keys.dart';
import 'package:final_project/Primary_Screens/home/profile_sheet.dart';
import 'package:final_project/Primary_Screens/home/top5_expenses_section.dart';
import 'package:final_project/Primary_Screens/home/transaction_confirmation_sheet.dart';
import 'package:final_project/SecondaryScreens/Notifications/local_notification_store.dart';
import 'package:final_project/SecondaryScreens/Notifications/notification_services.dart';
import 'package:final_project/SecondaryScreens/Reminder/financial_reminder_page.dart';
import 'package:final_project/SecondaryScreens/Reminder/reminder_scheduler.dart';
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
  // ── Services ──────────────────────────────────────────────────────────────
  final cloudinary = CloudinaryService(
    backendUrl: 'https://fourth-year-backend.onrender.com',
  );
  final String userUid = FirebaseAuth.instance.currentUser!.uid;
  final usersDB = FirebaseFirestore.instance.collection('users');
  late final HomeSyncService _sync;

  // ── User profile ──────────────────────────────────────────────────────────
  String? username;
  String? profileImage;
  StreamSubscription? _userSubscription;
  Timer? _reminderTimer;

  // ── Financial state ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> transactions = [];
  double totalIncome = 0.0;
  double totalExpenses = 0.0;
  double displayedSavingsAmount = 0.0;
  double _balance = 0.0;
  bool isLoading = true;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _sync = HomeSyncService(uid: userUid);
    _listenToUserData();
    refreshData();
    LocalNotificationStore.init();
    SmartNotificationService.runAllChecks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReminderScheduler.runChecks(context);
    });
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) ReminderScheduler.runChecks(context);
    });
  }

  @override
  void dispose() {
    _reminderTimer?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────
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

  /// Step 1 — read from SharedPreferences immediately (offline-safe, instant).
  /// Step 2 — replay any pending Firestore writes in the background.
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

    // Replay any transactions that were saved offline — fire-and-forget.
    unawaited(_sync.syncPendingTransactions());
  }

  // ── Transaction write ─────────────────────────────────────────────────────
  /// Canonical write method for ALL home-page transactions (income & expense).
  ///
  /// Step 1 — build unified map and insert into SharedPreferences.
  ///           This works fully offline and is the source of truth for
  ///           FinancialService, SmartNotificationService, and all UI pages.
  /// Step 2 — queue the Firestore write so it persists across cold restarts.
  /// Step 3 — update UI state synchronously (no network wait).
  ///
  /// The Firestore write itself is replayed by syncPendingTransactions()
  /// which is called from refreshData() — the single sync entry point.
  Future<void> _saveTransaction(
    String title,
    double amount,
    String type, {
    double transactionCost = 0.0,
    String reason = '',
  }) async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    // Build unified map — same fields as every other writer.
    final txMap = buildTxMap(
      title: title,
      amount: amount,
      type: type,
      source: TxSource.home,
      transactionCost: transactionCost,
      reason: reason,
      refId: '', // home transactions have no associated goal/budget
      date: now,
    );

    // Step 1 — persist locally.
    transactions.insert(0, txMap);
    await prefs.setString(PrefsKeys.transactions, json.encode(transactions));

    // Step 2 — queue Firestore write before any sync attempt.
    await _sync.queueTransaction(
      title: title,
      amount: amount,
      type: type,
      source: TxSource.home,
      transactionCost: transactionCost,
      reason: reason,
      refId: '',
      date: now,
    );

    // Step 3 — refresh UI from SharedPreferences (never awaits network).
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
    final isIncome = type == TxType.income;
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

  // ── Callbacks for other pages ─────────────────────────────────────────────

  /// Called by BudgetDetailPage when a budget transaction is added.
  /// The budget page writes its own local + Firestore entry, so this method
  /// only needs to trigger a refreshData() to keep the home UI in sync.
  Future<void> onBudgetTransactionAdded(
    String title,
    double amount,
    String type,
  ) async {
    await refreshData();
  }

  /// Called when a budget expense is removed from SharedPreferences
  /// (e.g. the user unfinalized a budget).
  Future<void> onBudgetExpenseDeleted(String title, double amount) async {
    transactions.removeWhere(
      (tx) =>
          tx['title'] == title &&
          double.tryParse(tx['amount'].toString()) == amount &&
          tx['type'] == TxType.budgetExpense,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.transactions, json.encode(transactions));
    await refreshData();
  }

  // ── Derived data ──────────────────────────────────────────────────────────
  /// Today's top-5 expenses ranked by total (amount + fee).
  /// Reads 'date' from the unified schema — always present since buildTxMap
  /// writes both 'date' and 'createdAt' as ISO-8601 strings.
  List<Map<String, dynamic>> get top5Expenses {
    final now = DateTime.now();
    final expenses = transactions.where((tx) {
      // Include direct expenses and finalized budget transactions.
      final t = tx['type'] as String? ?? '';
      if (t != TxType.expense &&
          t != TxType.budget &&
          t != TxType.budgetFinalized) {
        return false;
      }
      // Use 'date' — always present in unified schema.
      // Fall back to 'createdAt' for any legacy records written before
      // the schema was standardised.
      final dateStr =
          (tx['date'] ?? tx['createdAt']) as String?;
      if (dateStr == null) return false;
      try {
        final d = DateTime.parse(dateStr);
        return d.year == now.year &&
            d.month == now.month &&
            d.day == now.day;
      } catch (_) {
        return false;
      }
    }).toList();

    expenses.sort((a, b) {
      final aTotal = (double.tryParse(a['amount'].toString()) ?? 0) +
          (double.tryParse(a['transactionCost']?.toString() ?? '0') ?? 0);
      final bTotal = (double.tryParse(b['amount'].toString()) ?? 0) +
          (double.tryParse(b['transactionCost']?.toString() ?? '0') ?? 0);
      return bTotal.compareTo(aTotal);
    });
    return expenses.take(5).toList();
  }

  // ── Profile image upload ──────────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    final image = await cloudinary.pickImage();
    if (image == null) return;
    final url = await cloudinary.uploadFile(image);
    if (url == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userUid)
          .update({'profileUrl': url});
      if (mounted) AppToast.success(context, 'Profile image changed!');
    } catch (_) {
      if (mounted) AppToast.error(context, 'An error occurred, please try again');
    }
  }

  // ── Sheet launchers ───────────────────────────────────────────────────────
  void _openIncomeSheet() {
    showAddIncomeSheet(
      context,
      onContinue: ({required title, required amount, required reason}) {
        showTransactionConfirmation(
          context,
          type: TxType.income,
          title: title,
          amount: amount,
          transactionCost: 0,
          reason: reason,
          currentBalance: _balance,
          onConfirm: () async {
            // Update total_income in SharedPreferences.
            final prefs = await SharedPreferences.getInstance();
            totalIncome += amount;
            await prefs.setDouble(PrefsKeys.totalIncome, totalIncome);

            // Write unified transaction + queue Firestore write.
            await _saveTransaction(
              title,
              amount,
              TxType.income,
              reason: reason,
            );
            await refreshData();
          },
        );
      },
    );
  }

  void _openExpenseSheet() {
    showAddExpenseSheet(
      context,
      onContinue: ({
        required title,
        required amount,
        required transactionCost,
        required reason,
      }) {
        showTransactionConfirmation(
          context,
          type: TxType.expense,
          title: title,
          amount: amount,
          transactionCost: transactionCost,
          reason: reason,
          currentBalance: _balance,
          onConfirm: () async {
            await _saveTransaction(
              title,
              amount,
              TxType.expense,
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

  // ── Build ─────────────────────────────────────────────────────────────────
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
              backgroundImage: (profileImage == null || profileImage!.isEmpty)
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
            Text(greetings(),
                style: Theme.of(context).textTheme.headlineSmall),
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
          child: Row(children: [const NotificationIcon()]),
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
          label: 'Transactions',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TransactionsPage()),
            );
            refreshData();
          },
        ),
        QuickActionCard(
          icon: Icons.watch_later,
          label: 'Reminders',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FinancialReminderPage()),
          ),
        ),
      ],
    );
  }
}