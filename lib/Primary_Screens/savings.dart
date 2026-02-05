import 'dart:convert';

import 'package:final_project/Components/Custom_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => SavingsScreenState();
}

enum SavingsFilter { all, active, achieved }

class SavingsScreenState extends State<SavingsScreen> {
  List<Saving> savings = [];
  SavingsFilter currentFilter = SavingsFilter.all;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSavings();
  }

  // ---------------- Helpers ----------------

  String formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: 'Ksh ',
      decimalDigits: 2,
    ).format(amount);
  }

  int daysRemaining(DateTime deadline) {
    return deadline.difference(DateTime.now()).inDays;
  }

  List<Saving> get filteredSavings {
    switch (currentFilter) {
      case SavingsFilter.active:
        return savings.where((s) => !s.isAchieved).toList();
      case SavingsFilter.achieved:
        return savings.where((s) => s.isAchieved).toList();
      default:
        return savings;
    }
  }

  // ---------------- Persistence ----------------

  Future<void> loadSavings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('savings') ?? [];
    setState(() {
      savings = data.map((e) => Saving.fromMap(json.decode(e))).toList();
      isLoading = false;
    });
  }

  Future<void> saveSavings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'savings',
      savings.map((e) => json.encode(e.toMap())).toList(),
    );
  }

  // ---------------- Actions ----------------

  void addSaving(Saving saving) {
    setState(() => savings.add(saving));
    saveSavings();
  }

  void addFunds(Saving saving, double amount) {
    setState(() {
      saving.currentAmount += amount;
      saving.updateAchievement();
      saving.updateStreak();
    });
    saveSavings();
  }

  void deleteSaving(Saving saving) {
    setState(() => savings.remove(saving));
    saveSavings();
  }

  void renameSaving(Saving saving, String name) {
    setState(() => saving.name = name);
    saveSavings();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const CustomHeader(headerName: "Savings")),
      body: Column(
        children: [
          buildFilter(),
          Expanded(
            child: savings.isEmpty
                ? buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredSavings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => buildSavingTile(filteredSavings[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddSavingDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget buildFilter() {
    return SegmentedButton<SavingsFilter>(
      segments: const [
        ButtonSegment(value: SavingsFilter.all, label: Text('All')),
        ButtonSegment(value: SavingsFilter.active, label: Text('Active')),
        ButtonSegment(value: SavingsFilter.achieved, label: Text('Achieved')),
      ],
      selected: {currentFilter},
      onSelectionChanged: (s) => setState(() => currentFilter = s.first),
    );
  }

  Widget buildSavingTile(Saving saving) {
    final remaining = saving.targetAmount - saving.currentAmount;
    final progress = saving.currentAmount / saving.targetAmount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: saving.isAchieved
            ? Colors.green.withOpacity(0.1)
            : Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(saving.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),

          LinearProgressIndicator(value: progress.clamp(0, 1)),
          const SizedBox(height: 6),

          Text(
            saving.isAchieved
                ? "🎉 Goal achieved!"
                : "Remaining: ${formatCurrency(remaining)}",
          ),

          Text(
            saving.isAchieved
                ? "Completed"
                : "${daysRemaining(saving.deadline)} days to go",
          ),

          Text("🔥 Streak: ${saving.streak} (${saving.streakLevel})"),

          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => showSavingOptions(saving),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(child: Text("No savings yet. Start your first goal!"));
  }

  // ---------------- Dialogs ----------------

  void showAddSavingDialog() {
    final name = TextEditingController();
    final target = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Create Saving"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Saving name"),
            ),
            TextField(
              controller: target,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Target amount"),
            ),
            TextButton(
              child: const Text("Pick deadline"),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: deadline,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) deadline = picked;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              addSaving(
                Saving(
                  name: name.text,
                  targetAmount: double.parse(target.text),
                  deadline: deadline,
                ),
              );
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void showSavingOptions(Saving saving) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("Add Funds"),
            onTap: () {
              Navigator.pop(context);
              showAddFundsDialog(saving);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("Rename"),
            onTap: () {
              Navigator.pop(context);
              showRenameDialog(saving);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete"),
            onTap: () {
              deleteSaving(saving);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void showAddFundsDialog(Saving saving) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Funds"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              addFunds(saving, double.parse(controller.text));
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void showRenameDialog(Saving saving) {
    final controller = TextEditingController(text: saving.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Saving"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              renameSaving(saving, controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}

// ---------------- MODEL ----------------

class Saving {
  String name;
  double targetAmount;
  double currentAmount;
  DateTime deadline;
  int streak;
  DateTime? lastSavedDate;

  Saving({
    required this.name,
    required this.targetAmount,
    required this.deadline,
    this.currentAmount = 0,
    this.streak = 0,
    this.lastSavedDate,
  });

  bool get isAchieved => currentAmount >= targetAmount;

  void updateAchievement() {}

  void updateStreak() {
    final today = DateTime.now();
    if (lastSavedDate == null || today.difference(lastSavedDate!).inDays > 1) {
      streak = 1;
    } else if (today.difference(lastSavedDate!).inDays == 1) {
      streak++;
    }
    lastSavedDate = today;
  }

  String get streakLevel {
    if (streak >= 30) return "Legend";
    if (streak >= 14) return "Consistent";
    if (streak >= 7) return "Rising";
    return "Beginner";
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'targetAmount': targetAmount,
    'currentAmount': currentAmount,
    'deadline': deadline.toIso8601String(),
    'streak': streak,
    'lastSavedDate': lastSavedDate?.toIso8601String(),
  };

  factory Saving.fromMap(Map<String, dynamic> map) => Saving(
    name: map['name'],
    targetAmount: (map['targetAmount'] as num).toDouble(),
    currentAmount: (map['currentAmount'] as num).toDouble(),
    deadline: DateTime.parse(map['deadline']),
    streak: map['streak'] ?? 0,
    lastSavedDate: map['lastSavedDate'] != null
        ? DateTime.parse(map['lastSavedDate'])
        : null,
  );
}
