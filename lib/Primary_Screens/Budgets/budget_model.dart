// ─────────────────────────────────────────────────────────────────────────────
// models/budget_model.dart
//
// Contains: Budget, Expense, BudgetConfirmRow
//
// UPDATED: Added `isDirty` flag to Budget.
// When a budget is modified locally (offline or online), isDirty is set to
// true. BudgetSyncService reads this flag on startup to know which budgets
// need to be pushed to Firestore, even if the document already exists remotely.
// isDirty is NOT persisted to Firestore — it is a local-only field.
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

  /// True when the budget has local changes that have not yet been pushed to
  /// Firestore. Set to true on every local mutation; cleared after a
  /// successful Firestore push.
  bool isDirty;

  Budget({
    String? id,
    required this.name,
    required this.total,
    List<Expense>? expenses,
    this.isChecked = false,
    this.checkedDate,
    DateTime? createdDate,
    this.isDirty = true, // new budgets are always dirty until first push
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
    // isDirty is persisted locally so we remember pending syncs across
    // app restarts (offline edits survive a cold reboot).
    'isDirty': isDirty,
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
    // Default to true for budgets loaded from older snapshots that
    // pre-date this field (ensures they get synced at least once).
    isDirty: map['isDirty'] ?? true,
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