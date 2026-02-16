import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Components/back_button.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/spacing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavingsPage extends StatefulWidget {
  final Function(String, double, String)? onTransactionAdded;

  const SavingsPage({super.key, this.onTransactionAdded});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  static const String keySavings = 'savings';
  static const String keyTransactions = 'transactions';
  static const String keyTotalIncome = 'total_income';
  static const String keyStreakCount = 'streak_count';
  static const String keyLastSaveDate = 'last_save_date';
  static const String keyStreakLevel = 'streak_level';

  final userUid = FirebaseAuth.instance.currentUser!.uid;
  List<Saving> savings = [];
  String filter = 'all';
  bool isLoading = true;

  int streakCount = 0;
  String streakLevel = 'Base';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    final savingsStrings = prefs.getStringList(keySavings) ?? [];
    savings = savingsStrings
        .map((s) => Saving.fromMap(json.decode(s)))
        .toList();

    streakCount = prefs.getInt(keyStreakCount) ?? 0;
    streakLevel = prefs.getString(keyStreakLevel) ?? 'Base';

    checkStreakExpiry();
    setState(() => isLoading = false);
  }

  Future<void> checkStreakExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    String lastSaveDateStr = prefs.getString(keyLastSaveDate) ?? "";

    if (lastSaveDateStr.isEmpty) return;

    final lastDate = DateFormat('yyyy-MM-dd').parse(lastSaveDateStr);
    final difference = now.difference(lastDate).inDays;

    if (difference >= 3) {
      streakCount = 0;
      streakLevel = 'Base';
      await prefs.setInt(keyStreakCount, 0);
      await prefs.setString(keyStreakLevel, 'Base');
      setState(() {});

      await sendNotification(
        '💔 Streak Lost',
        'Your savings streak has been reset due to inactivity. Start saving again to rebuild it!',
      );
    }
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

    String lastSaveDateStr = prefs.getString(keyLastSaveDate) ?? "";

    if (lastSaveDateStr == todayStr) return;

    if (lastSaveDateStr.isNotEmpty) {
      final lastDate = DateFormat('yyyy-MM-dd').parse(lastSaveDateStr);
      final difference = now.difference(lastDate).inDays;

      if (difference == 1) {
        streakCount++;
      } else if (difference >= 3) {
        streakCount = 1;
      } else {
        streakCount = 1;
      }
    } else {
      streakCount = 1;
    }

    streakLevel = getStreakLevel(streakCount);

    await prefs.setInt(keyStreakCount, streakCount);
    await prefs.setString(keyStreakLevel, streakLevel);
    await prefs.setString(keyLastSaveDate, todayStr);

    setState(() {});

    if (streakCount % 7 == 0 && streakCount > 0) {
      await sendNotification(
        '🔥 Streak Milestone!',
        'Amazing! You\'ve maintained a $streakCount day savings streak at $streakLevel level!',
      );
    }
  }

  Future<void> syncSavings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = savings.map((s) => json.encode(s.toMap())).toList();
    await prefs.setStringList(keySavings, data);
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

  List<Saving> get filteredSavings {
    if (filter == 'all') return savings;
    if (filter == 'active') {
      return savings.where((s) => !s.achieved).toList();
    }
    return savings.where((s) => s.achieved).toList();
  }

  Future<void> createSavingGoal() async {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));
    String? selectedIcon;

    final icons = [
      {'code': 'phone', 'icon': Icons.phone_android},
      {'code': 'home', 'icon': Icons.home},
      {'code': 'car', 'icon': Icons.directions_car},
      {'code': 'vacation', 'icon': Icons.flight},
      {'code': 'education', 'icon': Icons.school},
      {'code': 'emergency', 'icon': Icons.warning_amber_rounded},
      {'code': 'wedding', 'icon': Icons.favorite},
      {'code': 'business', 'icon': Icons.business_center},
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Savings Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    hintText: 'e.g. New Phone, Vacation',
                    prefixIcon: Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (Ksh)',
                    hintText: '0',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Due Date'),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Icon:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((iconData) {
                    final isSelected = selectedIcon == iconData['code'];
                    return GestureDetector(
                      onTap: () => setDialogState(
                        () => selectedIcon = iconData['code'] as String,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? brandGreen.withOpacity(0.2)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? brandGreen : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData['icon'] as IconData,
                          color: isSelected ? brandGreen : Colors.grey.shade600,
                          size: 28,
                        ),
                      ),
                    );
                  }).toList(),
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
              style: ElevatedButton.styleFrom(backgroundColor: brandGreen),
              onPressed: () async {
                final target = double.tryParse(targetCtrl.text) ?? 0;
                if (nameCtrl.text.isNotEmpty && target > 0) {
                  final newGoal = Saving(
                    name: nameCtrl.text,
                    savedAmount: 0,
                    targetAmount: target,
                    deadline: selectedDate,
                    iconCode: selectedIcon ?? 'phone',
                  );
                  savings.add(newGoal);
                  await syncSavings();
                  await sendNotification(
                    '🎯 New Goal Created',
                    'You\'ve set a savings goal: ${nameCtrl.text} - Target: Ksh ${target.toStringAsFixed(0)}',
                  );
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addFundsToGoal(Saving saving) async {
    final amountCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Funds to ${saving.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current: Ksh ${saving.savedAmount.toStringAsFixed(0)}'),
            Text('Target: Ksh ${saving.targetAmount.toStringAsFixed(0)}'),
            Text('Remaining: Ksh ${saving.balance.toStringAsFixed(0)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount to Add (Ksh)',
                hintText: '0',
                prefixIcon: Icon(Icons.attach_money),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: brandGreen),
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount > 0) {
                saving.savedAmount += amount;

                bool wasAchieved = saving.achieved;
                if (saving.savedAmount >= saving.targetAmount && !wasAchieved) {
                  saving.achieved = true;
                  await sendNotification(
                    '🎉 Goal Achieved!',
                    'Congratulations! You\'ve reached your ${saving.name} savings goal of Ksh ${saving.targetAmount.toStringAsFixed(0)}!',
                  );
                }

                await syncSavings();
                await saveTransaction(
                  'Saved for ${saving.name}',
                  amount,
                  'savings_deduction',
                );
                await updateStreak();

                if (widget.onTransactionAdded != null) {
                  widget.onTransactionAdded!(
                    'Saved for ${saving.name}',
                    amount,
                    'savings_deduction',
                  );
                }

                Navigator.pop(context);
                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Added Ksh ${amount.toStringAsFixed(0)} to ${saving.name}',
                    ),
                    backgroundColor: brandGreen,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  Future<void> editGoal(Saving saving) async {
    final nameCtrl = TextEditingController(text: saving.name);
    final targetCtrl = TextEditingController(
      text: saving.targetAmount.toStringAsFixed(0),
    );
    DateTime selectedDate = saving.deadline;
    String? selectedIcon = saving.iconCode;

    final icons = [
      {'code': 'phone', 'icon': Icons.phone_android},
      {'code': 'home', 'icon': Icons.home},
      {'code': 'car', 'icon': Icons.directions_car},
      {'code': 'vacation', 'icon': Icons.flight},
      {'code': 'education', 'icon': Icons.school},
      {'code': 'emergency', 'icon': Icons.warning_amber_rounded},
      {'code': 'wedding', 'icon': Icons.favorite},
      {'code': 'business', 'icon': Icons.business_center},
    ];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Savings Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Goal Name',
                    prefixIcon: Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount (Ksh)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Due Date'),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Icon:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((iconData) {
                    final isSelected = selectedIcon == iconData['code'];
                    return GestureDetector(
                      onTap: () => setDialogState(
                        () => selectedIcon = iconData['code'] as String,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? brandGreen.withOpacity(0.2)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? brandGreen : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData['icon'] as IconData,
                          color: isSelected ? brandGreen : Colors.grey.shade600,
                          size: 28,
                        ),
                      ),
                    );
                  }).toList(),
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
              style: ElevatedButton.styleFrom(backgroundColor: brandGreen),
              onPressed: () async {
                final target = double.tryParse(targetCtrl.text) ?? 0;
                if (nameCtrl.text.isNotEmpty && target > 0) {
                  saving.name = nameCtrl.text;
                  saving.targetAmount = target;
                  saving.deadline = selectedDate;
                  saving.iconCode = selectedIcon;

                  if (saving.savedAmount >= saving.targetAmount &&
                      !saving.achieved) {
                    saving.achieved = true;
                    await sendNotification(
                      '🎉 Goal Achieved!',
                      'Congratulations! You\'ve reached your ${saving.name} savings goal!',
                    );
                  }

                  await syncSavings();
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteGoal(Saving saving) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Savings Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${saving.name}"?'),
            const SizedBox(height: 12),
            if (!saving.achieved && saving.savedAmount > 0) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Important',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This goal has Ksh ${saving.savedAmount.toStringAsFixed(0)} saved. Deleting will:',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Restore the saved amount to your balance',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '• Remove all related transactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!saving.achieved && saving.savedAmount > 0) {
        await deleteRelatedTransactions(saving.name);
        await restoreBalanceFromGoal(saving.savedAmount);
      }

      savings.remove(saving);
      await syncSavings();
      await sendNotification(
        '🗑️ Goal Deleted',
        'Your ${saving.name} savings goal has been deleted.',
      );
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Goal deleted successfully'),
          backgroundColor: brandGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> deleteRelatedTransactions(String goalName) async {
    final prefs = await SharedPreferences.getInstance();
    final txString = prefs.getString(keyTransactions) ?? '[]';
    List<Map<String, dynamic>> transactions = List<Map<String, dynamic>>.from(
      json.decode(txString),
    );

    transactions.removeWhere(
      (tx) =>
          tx['title'] != null &&
          tx['title'].toString().contains('Saved for $goalName') &&
          (tx['type'] == 'savings_deduction' || tx['type'] == 'saving_deposit'),
    );

    await prefs.setString(keyTransactions, json.encode(transactions));
  }

  Future<void> restoreBalanceFromGoal(double savedAmount) async {
    final prefs = await SharedPreferences.getInstance();
    double totalIncome = prefs.getDouble(keyTotalIncome) ?? 0.0;

    // Since savings deductions reduce balance, we need to add it back
    // This is effectively reversing the expense
    // We don't change totalIncome, but we remove the expense transactions
    // The balance will automatically adjust when transactions are deleted
  }

  Future<void> saveTransaction(String title, double amount, String type) async {
    final prefs = await SharedPreferences.getInstance();
    final txString = prefs.getString(keyTransactions) ?? '[]';
    List<Map<String, dynamic>> transactions = List<Map<String, dynamic>>.from(
      json.decode(txString),
    );

    final newTx = {
      'title': title,
      'amount': amount,
      'type': type,
      'date': DateTime.now().toIso8601String(),
    };
    transactions.insert(0, newTx);
    await prefs.setString(keyTransactions, json.encode(transactions));
  }

  IconData getIconData(String? code) {
    switch (code) {
      case 'phone':
        return Icons.phone_android;
      case 'home':
        return Icons.home;
      case 'car':
        return Icons.directions_car;
      case 'vacation':
        return Icons.flight;
      case 'education':
        return Icons.school;
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'wedding':
        return Icons.favorite;
      case 'business':
        return Icons.business_center;
      default:
        return Icons.savings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredGoals = filteredSavings;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        leading: const CustomBackButton(),
        title: const CustomHeader(headerName: "Savings Goals"),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                buildStreakCard(theme),
                buildFilterChips(theme),
                buildStatsCard(theme),
                Expanded(
                  child: filteredGoals.isEmpty
                      ? buildEmptyState(theme)
                      : RefreshIndicator(
                          onRefresh: loadData,
                          child: ListView.builder(
                            padding: paddingAllMedium,
                            itemCount: filteredGoals.length,
                            itemBuilder: (context, index) {
                              return buildSavingGoalCard(
                                filteredGoals[index],
                                theme,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: createSavingGoal,
        backgroundColor: brandGreen,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget buildStreakCard(ThemeData theme) {
    Color levelColor = brandGreen;
    IconData levelIcon = Icons.local_fire_department;

    if (streakLevel == 'Bronze') {
      levelColor = Colors.brown;
    } else if (streakLevel == 'Silver') {
      levelColor = Colors.grey;
    } else if (streakLevel == 'Gold') {
      levelColor = Colors.amber;
    } else if (streakLevel == 'Platinum') {
      levelColor = Colors.cyan;
    } else if (streakLevel == 'Diamond') {
      levelColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor, levelColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radiusSmall,
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.3),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(levelIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakCount Day Streak',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$streakLevel Level',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('🔥', style: const TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  Widget buildFilterChips(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          buildFilterChip('All', 'all', theme),
          const SizedBox(width: 8),
          buildFilterChip('Active', 'active', theme),
          const SizedBox(width: 8),
          buildFilterChip('Achieved', 'achieved', theme),
        ],
      ),
    );
  }

  Widget buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = filter == value;
    return GestureDetector(
      onTap: () => setState(() => filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? brandGreen : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? brandGreen : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget buildStatsCard(ThemeData theme) {
    double totalTarget = 0;
    double totalSaved = 0;
    int activeGoals = 0;
    int achievedGoals = 0;

    for (var saving in savings) {
      totalTarget += saving.targetAmount;
      totalSaved += saving.savedAmount;
      if (saving.achieved) {
        achievedGoals++;
      } else {
        activeGoals++;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radiusSmall,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: buildStatItem(
                  'Total Target',
                  'Ksh ${totalTarget.toStringAsFixed(0)}',
                  Icons.flag,
                  Colors.blue,
                  theme,
                ),
              ),
              Container(height: 40, width: 1, color: Colors.grey.shade300),
              Expanded(
                child: buildStatItem(
                  'Total Saved',
                  'Ksh ${totalSaved.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  brandGreen,
                  theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: buildStatItem(
                  'Active Goals',
                  activeGoals.toString(),
                  Icons.trending_up,
                  Colors.orange,
                  theme,
                ),
              ),
              Container(height: 40, width: 1, color: Colors.grey.shade300),
              Expanded(
                child: buildStatItem(
                  'Achieved',
                  achievedGoals.toString(),
                  Icons.check_circle,
                  brandGreen,
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget buildEmptyState(ThemeData theme) {
    String message = 'No savings goals yet';
    String subtitle = 'Create your first goal to start saving!';

    if (filter == 'active') {
      message = 'No active goals';
      subtitle = 'All your goals are achieved! Create a new one.';
    } else if (filter == 'achieved') {
      message = 'No achieved goals';
      subtitle = 'Keep saving to achieve your goals!';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.savings_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget buildSavingGoalCard(Saving saving, ThemeData theme) {
    final progress = saving.targetAmount > 0
        ? (saving.savedAmount / saving.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final daysRemaining = saving.deadline.difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining < 0;
    final isUrgent = daysRemaining <= 7 && daysRemaining >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: radiusSmall,
        border: Border.all(
          color: saving.achieved
              ? brandGreen
              : isOverdue
              ? errorColor
              : Colors.grey.shade200,
          width: saving.achieved ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: saving.achieved
                    ? brandGreen.withOpacity(0.1)
                    : accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                getIconData(saving.iconCode),
                color: saving.achieved ? brandGreen : accentColor,
                size: 28,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    saving.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (saving.achieved)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: brandGreen, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Achieved',
                          style: TextStyle(
                            color: brandGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOverdue
                          ? '${daysRemaining.abs()} days overdue'
                          : '$daysRemaining days remaining',
                      style: TextStyle(
                        color: isOverdue
                            ? errorColor
                            : isUrgent
                            ? Colors.orange
                            : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: isOverdue || isUrgent
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: ${DateFormat('dd MMM yyyy').format(saving.deadline)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            trailing: PopupMenuButton(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
              itemBuilder: (context) => [
                if (!saving.achieved)
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: brandGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Add Funds'),
                      ],
                    ),
                    onTap: () => Future.delayed(
                      Duration.zero,
                      () => addFundsToGoal(saving),
                    ),
                  ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      const Text('Edit Goal'),
                    ],
                  ),
                  onTap: () =>
                      Future.delayed(Duration.zero, () => editGoal(saving)),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: errorColor, size: 20),
                      const SizedBox(width: 8),
                      const Text('Delete Goal'),
                    ],
                  ),
                  onTap: () =>
                      Future.delayed(Duration.zero, () => deleteGoal(saving)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Ksh ${saving.savedAmount.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: brandGreen,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Target',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Ksh ${saving.targetAmount.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      saving.achieved ? brandGreen : accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Complete',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Remaining: Ksh ${saving.balance.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!saving.achieved)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => addFundsToGoal(saving),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add Funds'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Saving {
  String name;
  double savedAmount;
  double targetAmount;
  DateTime deadline;
  bool achieved;
  String? iconCode;

  Saving({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    this.achieved = false,
    this.iconCode,
  });

  double get balance => targetAmount - savedAmount;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'savedAmount': savedAmount,
      'targetAmount': targetAmount,
      'deadline': deadline.toIso8601String(),
      'achieved': achieved,
      'iconCode': iconCode,
    };
  }

  factory Saving.fromMap(Map<String, dynamic> map) {
    return Saving(
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
      iconCode: map['iconCode'],
    );
  }
}
