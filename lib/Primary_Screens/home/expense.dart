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
