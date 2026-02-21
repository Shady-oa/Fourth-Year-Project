// ─── Saving Model ─────────────────────────────────────────────────────────────
class Saving {
  String name;
  double savedAmount, targetAmount;
  DateTime deadline, lastUpdated;
  bool achieved;
  List<dynamic> transactions;

  Saving({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    this.achieved = false,
    DateTime? lastUpdated,
    List<dynamic>? transactions,
  }) : lastUpdated = lastUpdated ?? DateTime.now(),
       transactions = transactions ?? [];

  double get balance => targetAmount - savedAmount;
  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() => {
    'name': name,
    'savedAmount': savedAmount,
    'targetAmount': targetAmount,
    'deadline': deadline.toIso8601String(),
    'achieved': achieved,
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
    lastUpdated: map['lastUpdated'] != null
        ? DateTime.parse(map['lastUpdated'])
        : DateTime.now(),
    transactions: (map['transactions'] as List?) ?? [],
  );
}
