import 'package:uuid/uuid.dart';

class Budget {
  String id;
  String name;
  double total;
  bool achieved;
  DateTime createdAt;

  Budget({
    required this.name,
    required this.total,
    this.achieved = false,
  })  : id = Uuid().v4(),
        createdAt = DateTime.now();

  Budget.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        name = map['name'],
        total = map['total'],
        achieved = map['achieved'],
        createdAt = DateTime.parse(map['createdAt']);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'total': total,
      'achieved': achieved,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
