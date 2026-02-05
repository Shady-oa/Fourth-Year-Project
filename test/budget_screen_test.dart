import 'package:final_project/Models/budget_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Budget', () {
    test('toMap() should return a valid map', () {
      final budget = Budget(name: 'Groceries', total: 500.0);
      final budgetMap = budget.toMap();

      expect(budgetMap['name'], 'Groceries');
      expect(budgetMap['total'], 500.0);
      expect(budgetMap['achieved'], false);
    });

    test('fromMap() should create a valid Budget object', () {
      final budgetMap = {
        'id': '123',
        'name': 'Groceries',
        'total': 500.0,
        'achieved': false,
        'createdAt': DateTime.now().toIso8601String(),
      };
      final budget = Budget.fromMap(budgetMap);

      expect(budget.name, 'Groceries');
      expect(budget.total, 500.0);
      expect(budget.achieved, false);
    });
  });
}
