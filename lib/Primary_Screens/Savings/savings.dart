import 'dart:convert';

import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Savings/streak_banner.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Note: The Saving class is defined at the bottom of this file.
int streakCount = 0;
int streakLevel = 1;
String lastSaveDateStr = "";

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => SavingsScreenState();
}

enum SavingsFilter { all, active, achieved }

class SavingsScreenState extends State<SavingsScreen> {
  // Public Variables
  List<Saving> savings = [];
  SavingsFilter currentFilter = SavingsFilter.all;
  bool isLoading = true;

  // Streak Variables

  @override
  void initState() {
    super.initState();
    loadSavings();
    loadStreakData();
  }

  // -------------------- Public Helpers --------------------

  String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'Ksh ',
      decimalDigits: 2,
    ).format(amount);
  }

  String calculateDaysRemaining(DateTime deadline) {
    final now = DateTime.now();
    // Reset time to midnight for accurate day calculation
    final dateNow = DateTime(now.year, now.month, now.day);
    final dateDeadline = DateTime(deadline.year, deadline.month, deadline.day);

    final difference = dateDeadline.difference(dateNow).inDays;

    if (difference < 0) return "Overdue";
    if (difference == 0) return "Due today";
    if (difference == 1) return "1 day to go";
    return "$difference days to go";
  }

  List<Saving> get filteredSavings {
    switch (currentFilter) {
      case SavingsFilter.active:
        return savings.where((s) => !s.achieved).toList();
      case SavingsFilter.achieved:
        return savings.where((s) => s.achieved).toList();
      case SavingsFilter.all:
        return savings;
    }
  }

  // -------------------- Persistence (Data Saving) --------------------

  Future<void> loadSavings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Changed key from 'budgets' to 'savings'
      final savingsStrings = prefs.getStringList('savings') ?? [];

      final List<Saving> loadedSavings = [];

      for (var str in savingsStrings) {
        try {
          final dynamic decoded = json.decode(str);
          loadedSavings.add(Saving.fromMap(decoded));
        } catch (e) {
          debugPrint("Skipping corrupted saving data: $e");
        }
      }

      setState(() {
        savings = loadedSavings;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading savings: $e");
      setState(() {
        savings = [];
        isLoading = false;
      });
    }
  }

  Future<void> saveSavingsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final data = savings.map((s) => json.encode(s.toMap())).toList();
    await prefs.setStringList('savings', data);
  }

  // -------------------- Streak Logic --------------------

  Future<void> loadStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      streakCount = prefs.getInt('streak_count') ?? 0;
      lastSaveDateStr = prefs.getString('last_save_date') ?? "";
      // Simple level logic: Level up every 7 days of streaks
      streakLevel = (streakCount ~/ 7) + 1;
    });
  }

  Future<void> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    if (lastSaveDateStr == todayStr) {
      // Already saved today, streak remains the same
      return;
    }

    if (lastSaveDateStr.isNotEmpty) {
      final lastDate = DateFormat('yyyy-MM-dd').parse(lastSaveDateStr);
      final difference = now.difference(lastDate).inDays;

      if (difference == 1) {
        // Saved yesterday, increment streak
        streakCount++;
      } else {
        // Missed a day, reset streak (but start at 1 for today)
        streakCount = 1;
      }
    } else {
      // First time ever saving
      streakCount = 1;
    }

    lastSaveDateStr = todayStr;
    streakLevel = (streakCount ~/ 7) + 1; // Recalculate level

    await prefs.setInt('streak_count', streakCount);
    await prefs.setString('last_save_date', lastSaveDateStr);

    setState(() {});

    Fluttertoast.showToast(
      msg: "🔥 Streak updated! Day $streakCount",
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  // -------------------- Actions --------------------

  void addSaving(String name, double targetAmount, DateTime deadline) {
    setState(() {
      savings.add(
        Saving(
          name: capitalizeWords(name),
          savedAmount: 0.0, // Starts at 0
          targetAmount: targetAmount,
          deadline: deadline,
        ),
      );
    });
    saveSavingsToStorage();
    Fluttertoast.showToast(msg: 'Saving goal for $name created.');
  }

  void addFunds(int index, double amount) {
    setState(() {
      final saving = savings[index];
      saving.savedAmount += amount;

      // Auto-achieve logic
      if (saving.savedAmount >= saving.targetAmount && !saving.achieved) {
        saving.achieved = true;
        Fluttertoast.showToast(
          msg:
              '🎉 Goal Achieved! You saved ${formatCurrency(saving.targetAmount)}',
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    });

    updateStreak(); // Check and update streak
    saveSavingsToStorage();

    if (!savings[index].achieved) {
      Fluttertoast.showToast(
        msg: 'Added ${formatCurrency(amount)} to ${savings[index].name}',
      );
    }
  }

  void deleteSaving(Saving saving) {
    setState(() => savings.remove(saving));
    saveSavingsToStorage();
    Fluttertoast.showToast(msg: 'Saving for ${saving.name} deleted');
  }

  void renameSaving(Saving saving, String newName) {
    setState(() {
      saving.name = capitalizeWords(newName);
    });
    saveSavingsToStorage();
    Fluttertoast.showToast(msg: 'Saving renamed to ${saving.name}');
  }

  // -------------------- UI Methods --------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final displayedSavings = filteredSavings;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: CustomHeader(headerName: "My Savings"),
      ),
      body: Column(
        children: [
          // Streak Banner
          buildStreakBanner(theme),

          // Filter Section
          if (savings.isNotEmpty) buildFilterBar(theme),

          // Main Content
          Expanded(
            child: savings.isEmpty
                ? buildEmptyState(theme)
                : displayedSavings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.savings_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text("No ${currentFilter.name} savings found"),
                      ],
                    ),
                  )
                : Scrollbar(
                    thumbVisibility: true,
                    radius: const Radius.circular(8),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: displayedSavings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return buildSavingCard(theme, displayedSavings[index]);
                      },
                    ),
                  ),
          ),

          // Bottom Add Button (Only if list is not empty)
          if (savings.isNotEmpty) buildAddAnotherButton(theme),
        ],
      ),
    );
  }

  Widget buildFilterBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: SegmentedButton<SavingsFilter>(
        segments: const [
          ButtonSegment(
            value: SavingsFilter.all,
            label: Text('All'),
            icon: Icon(Icons.list),
          ),
          ButtonSegment(value: SavingsFilter.active, label: Text('Active')),
          ButtonSegment(value: SavingsFilter.achieved, label: Text('Achieved')),
        ],
        selected: {currentFilter},
        onSelectionChanged: (Set<SavingsFilter> newSelection) {
          setState(() {
            currentFilter = newSelection.first;
          });
        },
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget buildSavingCard(ThemeData theme, Saving saving) {
    double remainingAmount = saving.targetAmount - saving.savedAmount;
    if (remainingAmount < 0) remainingAmount = 0;

    return Container(
      decoration: BoxDecoration(
        color: saving.achieved
            ? Colors.green.withOpacity(0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: saving.achieved
              ? Colors.green.withOpacity(0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showSavingOptions(saving),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: saving.achieved
                      ? Colors.green
                      : theme.colorScheme.primaryContainer,
                  child: Icon(
                    saving.achieved ? Icons.check : Icons.savings,
                    color: saving.achieved
                        ? Colors.white
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              saving.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!saving.achieved)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                calculateDaysRemaining(saving.deadline),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Progress Text
                      Text.rich(
                        TextSpan(
                          text: formatCurrency(saving.savedAmount),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: saving.achieved
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                          children: [
                            TextSpan(
                              text: " / ${formatCurrency(saving.targetAmount)}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!saving.achieved)
                        Text(
                          "Remaining: ${formatCurrency(remainingAmount)}",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      if (saving.achieved)
                        Text(
                          "Goal Reached!",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded),
                  color: Colors.grey,
                  onPressed: () => showSavingOptions(saving),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAddAnotherButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: showAddSavingDialog,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Create New Goal',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.savings_rounded,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text('No Savings Yet', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Create a saving goal to start your journey.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: showAddSavingDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Start Saving Now',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showSavingOptions(Saving saving) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(saving.name, style: Theme.of(context).textTheme.titleLarge),
              const Divider(height: 30),
              if (!saving.achieved)
                optionTile(Icons.add_circle_outline, 'Add Funds', () {
                  Navigator.pop(context);
                  final index = savings.indexOf(saving);
                  if (index != -1) showAddFundsDialog(index);
                }),
              optionTile(Icons.edit_outlined, 'Rename Goal', () {
                Navigator.pop(context);
                showRenameSavingDialog(saving);
              }),
              const Divider(),
              optionTile(Icons.delete_outline, 'Delete Goal', () {
                Navigator.pop(context);
                showDeleteConfirmationDialog(saving);
              }, destructive: true),
            ],
          ),
        );
      },
    );
  }

  Widget optionTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool destructive = false,
  }) {
    final color = destructive ? Colors.red : null;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (destructive ? Colors.red : Theme.of(context).primaryColor)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Theme.of(context).primaryColor),
      ),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  // -------------------- Dialogs --------------------

  void showAddSavingDialog() {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // StatefulBuilder to update Date text
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('New Saving Goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name (e.g. Car, Phone)',
                      prefixIcon: Icon(Icons.label),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Amount',
                      prefixIcon: Icon(Icons.flag),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 30),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Target Date / Deadline',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedDate == null
                            ? 'Select Date'
                            : DateFormat('dd MMM yyyy').format(selectedDate!),
                      ),
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
              FilledButton(
                onPressed: () {
                  final name = nameController.text;
                  final target = double.tryParse(targetController.text) ?? 0;

                  if (name.isNotEmpty && target > 0 && selectedDate != null) {
                    addSaving(name, target, selectedDate!);
                    Navigator.pop(context);
                  } else {
                    Fluttertoast.showToast(msg: 'Please fill all fields');
                  }
                },
                child: const Text('Create Goal'),
              ),
            ],
          );
        },
      ),
    );
  }

  void showAddFundsDialog(int index) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Funds'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount to save',
            prefixIcon: Icon(Icons.add_circle),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                addFunds(index, amount);
                Navigator.pop(context);
              } else {
                Fluttertoast.showToast(msg: 'Invalid amount');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void showDeleteConfirmationDialog(Saving saving) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Are you sure you want to delete "${saving.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              deleteSaving(saving);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void showRenameSavingDialog(Saving saving) {
    final controller = TextEditingController(text: saving.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Goal'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                renameSaving(saving, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

// -------------------- SAVING MODEL --------------------

class Saving {
  String name;
  double savedAmount; // Current funds
  double targetAmount; // Goal
  DateTime deadline; // Date goal
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
