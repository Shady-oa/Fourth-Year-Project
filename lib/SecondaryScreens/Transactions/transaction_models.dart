// ─────────────────────────────────────────────────────────────────────────────
//  Models used by TransactionsPage
//  Extracted from all_transactions.dart — structure unchanged.
// ─────────────────────────────────────────────────────────────────────────────

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
  })  : expenses = expenses ?? [],
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
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
} // end Saving class
