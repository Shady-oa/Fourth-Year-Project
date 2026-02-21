// lib/Models/saving_model.dart
// Shared model — import this in savings_page.dart, home_page.dart,
// all_transactions.dart, analytics_page.dart, report_page.dart
// to eliminate duplication and ensure one source of truth.

class SavingTransaction {
  final String type; // 'deposit' | 'withdrawal'
  final double amount;
  final double transactionCost; // only for deposits; NEVER refunded on goal deletion
  final DateTime date;
  final String goalName;

  SavingTransaction({
    required this.type,
    required this.amount,
    this.transactionCost = 0.0,
    required this.date,
    required this.goalName,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'amount': amount,
        'transactionCost': transactionCost,
        'date': date.toIso8601String(),
        'goalName': goalName,
      };

  factory SavingTransaction.fromMap(Map<String, dynamic> map) =>
      SavingTransaction(
        type: map['type'] ?? 'deposit',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        transactionCost:
            (map['transactionCost'] as num?)?.toDouble() ?? 0.0,
        date: map['date'] != null
            ? DateTime.parse(map['date'])
            : DateTime.now(),
        goalName: map['goalName'] ?? '',
      );
}

class Saving {
  String name;
  double savedAmount;
  double targetAmount;
  DateTime deadline;
  bool achieved;
  DateTime lastUpdated;
  List<SavingTransaction> transactions;

  Saving({
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    this.achieved = false,
    DateTime? lastUpdated,
    List<SavingTransaction>? transactions,
  })  : lastUpdated = lastUpdated ?? DateTime.now(),
        transactions = transactions ?? [];

  // ── Computed props ─────────────────────────────────────────────────────────
  double get balance => targetAmount - savedAmount;
  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Total fees paid across all deposit transactions for this goal.
  /// These are NEVER refunded when a goal is deleted.
  double get totalFeesPaid => transactions
      .where((t) => t.type == 'deposit')
      .fold(0.0, (s, t) => s + t.transactionCost);

  Map<String, dynamic> toMap() => {
        'name': name,
        'savedAmount': savedAmount,
        'targetAmount': targetAmount,
        'deadline': deadline.toIso8601String(),
        'achieved': achieved,
        'lastUpdated': lastUpdated.toIso8601String(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
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
        // walletType / walletName silently ignored for backward compat
        transactions: map['transactions'] != null
            ? (map['transactions'] as List)
                .map((t) =>
                    SavingTransaction.fromMap(t as Map<String, dynamic>))
                .toList()
            : [],
      );
}
