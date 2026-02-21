// ─────────────────────────────────────────────────────────────────────────────
// models/budget_model.dart
//
// Contains: Budget, Expense, BudgetConfirmRow
// ─────────────────────────────────────────────────────────────────────────────

/// Data class used by both budget_confirm_sheet.dart rows.
class BudgetConfirmRow {
  final String label;
  final String value;
  final bool highlight;
  const BudgetConfirmRow(this.label, this.value, {this.highlight = false});
}

// ── Budget Model ─────────────────────────────────────────────────────────────

class Budget {
  String id;
  String name;
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
  }) : expenses = expenses ?? [],
       id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdDate = createdDate ?? DateTime.now();

  double get totalSpent => expenses.fold(0.0, (sum, e) => sum + e.amount);
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

// ── Expense Model ─────────────────────────────────────────────────────────────

class Expense {
  String id;
  String name;
  double amount;
  DateTime createdDate;

  Expense({
    String? id,
    required this.name,
    required this.amount,
    DateTime? createdDate,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
