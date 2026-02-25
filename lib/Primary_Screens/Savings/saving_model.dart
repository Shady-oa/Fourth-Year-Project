// Primary_Screens/Savings/saving_model.dart

import 'package:uuid/uuid.dart';

class SavingTransaction {
  final String type; // 'deposit' | 'withdrawal'
  final double amount;
  final double transactionCost;
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
  /// Stable unique ID — generated once on creation, persisted to both
  /// SharedPreferences and Firestore as the document ID.
  final String id;

  String name;
  double savedAmount;
  double targetAmount;
  DateTime deadline;
  bool achieved;
  DateTime lastUpdated;
  List<SavingTransaction> transactions;

  /// Dirty flag — true when local state has not yet been pushed to Firestore.
  /// Persisted to SharedPreferences so pending changes survive cold restarts.
  /// Never written to Firestore (stripped in SavingsSyncService._pushSavingDoc).
  bool isDirty;

  Saving({
    String? id,
    required this.name,
    required this.savedAmount,
    required this.targetAmount,
    required this.deadline,
    this.achieved = false,
    DateTime? lastUpdated,
    List<SavingTransaction>? transactions,
    this.isDirty = true, // new goals start dirty so they sync on next open
  })  : id = id ?? const Uuid().v4(),
        lastUpdated = lastUpdated ?? DateTime.now(),
        transactions = transactions ?? [];

  // ── Computed props ────────────────────────────────────────────────────────
  double get balance => targetAmount - savedAmount;
  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get totalFeesPaid => transactions
      .where((t) => t.type == 'deposit')
      .fold(0.0, (s, t) => s + t.transactionCost);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'savedAmount': savedAmount,
        'targetAmount': targetAmount,
        'deadline': deadline.toIso8601String(),
        'achieved': achieved,
        'lastUpdated': lastUpdated.toIso8601String(),
        'transactions': transactions.map((t) => t.toMap()).toList(),
        'isDirty': isDirty,
      };

  factory Saving.fromMap(Map<String, dynamic> map) => Saving(
        id: map['id'] as String? ?? const Uuid().v4(),
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
        transactions: map['transactions'] != null
            ? (map['transactions'] as List)
                .map((t) =>
                    SavingTransaction.fromMap(t as Map<String, dynamic>))
                .toList()
            : [],
        // Existing records without isDirty default to false (already synced).
        isDirty: map['isDirty'] as bool? ?? false,
      );
}