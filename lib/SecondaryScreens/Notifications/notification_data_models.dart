// ─── Lightweight local data models ────────────────────────────────────────────
// Used only by SmartNotificationService to read budget / savings data from prefs.

class BudgetData {
  final String id;
  final String name;
  final double total;
  final double totalSpent;
  final bool isChecked;

  BudgetData({
    required this.id,
    required this.name,
    required this.total,
    required this.totalSpent,
    required this.isChecked,
  });

  factory BudgetData.fromMap(Map<String, dynamic> map) {
    final expenses = (map['expenses'] as List? ?? []);
    final spent = expenses.fold<double>(
      0.0,
      (s, e) => s + ((e['amount'] as num?)?.toDouble() ?? 0.0),
    );
    return BudgetData(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      totalSpent: spent,
      isChecked: map['isChecked'] ?? false,
    );
  }
}

class SavingData {
  final String name;
  final double savedAmount;
  final double targetAmount;
  final DateTime deadline;
  final bool achieved;

  SavingData({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    required this.achieved,
  });

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  factory SavingData.fromMap(Map<String, dynamic> map) => SavingData(
        name: map['name'] ?? '',
        savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0.0,
        targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
        deadline: map['deadline'] != null
            ? DateTime.parse(map['deadline'])
            : DateTime.now().add(const Duration(days: 30)),
        achieved: map['achieved'] ?? false,
      );
}
