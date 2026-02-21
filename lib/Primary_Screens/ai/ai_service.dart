import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Primary_Screens/ai/ai_constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


// ─── AI Service ───────────────────────────────────────────────────────────────
class AiService {
  // ─── Load local financial data ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    final txString = prefs.getString(kAiKeyTransactions) ?? '[]';
    final List<dynamic> transactions = json.decode(txString);

    final budgetStrings = prefs.getStringList(kAiKeyBudgets) ?? [];
    final savingsStrings = prefs.getStringList(kAiKeySavings) ?? [];

    final totalIncome = prefs.getDouble(kAiKeyTotalIncome) ?? 0.0;
    final streakCount = prefs.getInt(kAiKeyStreakCount) ?? 0;
    final streakLevel = prefs.getString(kAiKeyStreakLevel) ?? 'Base';

    double totalExpenses = 0.0;
    final Map<String, double> categoryTotals = {};
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);

    double thisMonthIncome = 0.0;
    double thisMonthExpenses = 0.0;
    double totalFees = 0.0;

    final recentTx = <Map<String, dynamic>>[];

    for (final tx in transactions.take(200)) {
      final map = tx as Map<String, dynamic>;
      final amount = double.tryParse(map['amount']?.toString() ?? '0') ?? 0.0;
      final fee =
          double.tryParse(map['transactionCost']?.toString() ?? '0') ?? 0.0;
      final type = map['type'] ?? '';
      final txDate = DateTime.tryParse(map['date'] ?? '') ?? now;

      if (type == 'income') {
        if (txDate.isAfter(thisMonthStart)) thisMonthIncome += amount;
      } else {
        totalExpenses += amount + fee;
        totalFees += fee;
        final label = type == 'budget_finalized' || type == 'budget_expense'
            ? 'Budget'
            : type == 'savings_deduction' || type == 'saving_deposit'
            ? 'Savings'
            : 'Expense';
        categoryTotals[label] = (categoryTotals[label] ?? 0) + amount + fee;
        if (txDate.isAfter(thisMonthStart)) thisMonthExpenses += amount + fee;
      }

      if (recentTx.length < 10) recentTx.add(map);
    }

    final savingsSummary = savingsStrings.map((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      return {
        'name': m['name'],
        'savedAmount': m['savedAmount'],
        'targetAmount': m['targetAmount'],
        'achieved': m['achieved'],
        'deadline': m['deadline'],
      };
    }).toList();

    final budgetSummary = budgetStrings.map((s) {
      final m = json.decode(s) as Map<String, dynamic>;
      final expenses = (m['expenses'] as List? ?? []);
      final spent = expenses.fold<double>(
        0.0,
        (sum, e) => sum + ((e['amount'] as num?)?.toDouble() ?? 0.0),
      );
      return {
        'name': m['name'],
        'total': m['total'],
        'spent': spent,
        'isChecked': m['isChecked'] ?? false,
      };
    }).toList();

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netBalance': totalIncome - totalExpenses,
      'thisMonthIncome': thisMonthIncome,
      'thisMonthExpenses': thisMonthExpenses,
      'totalFees': totalFees,
      'categoryBreakdown': categoryTotals,
      'recentTransactions': recentTx,
      'savings': savingsSummary,
      'budgets': budgetSummary,
      'streakCount': streakCount,
      'streakLevel': streakLevel,
      'transactionCount': transactions.length,
    };
  }

  // ─── Build financial context string ───────────────────────────────────────────
  static Future<String> buildFinancialContext() async {
    try {
      final data = await loadLocalData();
      final fmt = NumberFormat('#,##0', 'en_US');
      String ksh(dynamic v) => 'Ksh ${fmt.format((v as num).round())}';

      final sb = StringBuffer();
      sb.writeln('[$kAiContextPrefix]');
      sb.writeln('Total Income: ${ksh(data['totalIncome'])}');
      sb.writeln('Total Expenses: ${ksh(data['totalExpenses'])}');
      sb.writeln('Net Balance: ${ksh(data['netBalance'])}');
      sb.writeln('This Month Income: ${ksh(data['thisMonthIncome'])}');
      sb.writeln('This Month Expenses: ${ksh(data['thisMonthExpenses'])}');
      sb.writeln('Total Fees Paid: ${ksh(data['totalFees'])}');
      sb.writeln('Total Transactions: ${data['transactionCount']}');
      sb.writeln(
        'Savings Streak: ${data['streakCount']} days (${data['streakLevel']} level)',
      );

      final cats = data['categoryBreakdown'] as Map<String, double>;
      if (cats.isNotEmpty) {
        sb.writeln('\nSpending by Category:');
        cats.forEach((cat, amt) => sb.writeln('  - $cat: ${ksh(amt)}'));
      }

      final recent = data['recentTransactions'] as List;
      if (recent.isNotEmpty) {
        sb.writeln('\nLast ${recent.length} Transactions:');
        for (final tx in recent) {
          final t = tx as Map<String, dynamic>;
          final amt = double.tryParse(t['amount']?.toString() ?? '0') ?? 0;
          final fee =
              double.tryParse(t['transactionCost']?.toString() ?? '0') ?? 0;
          final date = t['date'] != null
              ? DateFormat('dd MMM yyyy').format(DateTime.parse(t['date']))
              : 'N/A';
          sb.writeln(
            '  - [${t['type']}] ${t['title']} | ${ksh(amt + fee)} | $date',
          );
        }
      }

      final savings = data['savings'] as List;
      if (savings.isNotEmpty) {
        sb.writeln('\nSavings Goals:');
        for (final s in savings) {
          final m = s as Map<String, dynamic>;
          final pct = (m['targetAmount'] as num) > 0
              ? ((m['savedAmount'] as num) / (m['targetAmount'] as num) * 100)
                    .toStringAsFixed(0)
              : '0';
          sb.writeln(
            '  - ${m['name']}: ${ksh(m['savedAmount'])} / ${ksh(m['targetAmount'])} ($pct%) | Achieved: ${m['achieved']}',
          );
        }
      }

      final budgets = data['budgets'] as List;
      if (budgets.isNotEmpty) {
        sb.writeln('\nBudgets:');
        for (final b in budgets) {
          final m = b as Map<String, dynamic>;
          final pct = (m['total'] as num) > 0
              ? ((m['spent'] as num) / (m['total'] as num) * 100)
                    .toStringAsFixed(0)
              : '0';
          sb.writeln(
            '  - ${m['name']}: ${ksh(m['spent'])} / ${ksh(m['total'])} ($pct%) | Finalized: ${m['isChecked']}',
          );
        }
      }

      sb.writeln('\n[END OF CONTEXT]');
      return sb.toString();
    } catch (e) {
      return '[Financial context unavailable: $e]';
    }
  }

  // ─── Send message to AI backend ───────────────────────────────────────────────
  static Future<String> sendMessageToAI(
    String displayText,
    String aiPrompt,
    String userid,
  ) async {
    try {
      final context = await buildFinancialContext();
      final enrichedMessage = '$context\n\nUser question: $aiPrompt';

      final response = await http.post(
        Uri.parse('https://fourth-year-backend.onrender.com/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userid,
          'message': enrichedMessage,
          'displayMessage': displayText,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? "Sorry, I didn't understand that.";
      } else {
        return 'Error: AI backend returned ${response.statusCode}';
      }
    } catch (e) {
      return 'Error connecting to AI backend: $e';
    }
  }

  // ─── Save the clean user message to Firestore immediately ─────────────────────
  static Future<void> saveUserMessageLocally(
    String userUid,
    String displayText,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .collection('chats')
        .add({
          'content': displayText,
          'role': 'user',
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
