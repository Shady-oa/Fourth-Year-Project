import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_project/Components/Custom_header.dart';
import 'package:final_project/Constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _keyTransactions = 'transactions';
const _keyBudgets = 'budgets';
const _keySavings = 'savings';
const _keyTotalIncome = 'total_income';
const _keyStreakCount = 'streak_count';
const _keyStreakLevel = 'streak_level';

/// Sentinel prefix used to identify enriched messages saved by the backend.
/// Any Firestore document whose content starts with this string is a
/// duplicated context bubble and must be hidden from the UI.
const _contextPrefix = '[USER FINANCIAL DATA CONTEXT]';

// ─── Message Model ────────────────────────────────────────────────────────────
enum MessageSender { user, ai }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage(this.text, this.sender, this.timestamp, {this.isLoading = false});
}

// ─── Pre-designed question model ─────────────────────────────────────────────
class _QuickQuestion {
  final String label;
  final String prompt;
  final IconData icon;
  final Color color;

  const _QuickQuestion({
    required this.label,
    required this.prompt,
    required this.icon,
    required this.color,
  });
}

// ─── AI Page ──────────────────────────────────────────────────────────────────
class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String userUid = FirebaseAuth.instance.currentUser!.uid;

  bool _isSending = false;
  // Tracks whether the initial jump-to-bottom has happened after page load.
  bool _initialScrollDone = false;

  // ─── Quick questions ───────────────────────────────────────────────────────
  static const List<_QuickQuestion> _quickQuestions = [
    _QuickQuestion(
      label: 'Spending trends',
      prompt: 'Analyze my spending trends this month based on my transactions.',
      icon: Icons.trending_up,
      color: Color(0xFF6C63FF),
    ),
    _QuickQuestion(
      label: 'Reduce expenses',
      prompt:
          'How can I reduce unnecessary expenses based on my spending history?',
      icon: Icons.cut_outlined,
      color: Color(0xFFFF6584),
    ),
    _QuickQuestion(
      label: 'Top category',
      prompt: 'What category am I spending the most on, and is it healthy?',
      icon: Icons.donut_large_outlined,
      color: Color(0xFFFFA94D),
    ),
    _QuickQuestion(
      label: 'Savings growth',
      prompt:
          'Compare my savings growth over the last 3 months and give insights.',
      icon: Icons.savings_outlined,
      color: Color(0xFF20C997),
    ),
    _QuickQuestion(
      label: 'End-of-month balance',
      prompt:
          'Based on my current income and expenses, predict my end-of-month balance.',
      icon: Icons.account_balance_outlined,
      color: Color(0xFF339AF0),
    ),
    _QuickQuestion(
      label: 'Budgeting advice',
      prompt:
          'Give me personalized budgeting advice based on my financial data.',
      icon: Icons.lightbulb_outline,
      color: Color(0xFFFFD43B),
    ),
    _QuickQuestion(
      label: 'Financial risks',
      prompt:
          'What financial risks do you detect in my current spending and saving patterns?',
      icon: Icons.warning_amber_outlined,
      color: Color(0xFFFF6B6B),
    ),
    _QuickQuestion(
      label: 'Increase savings',
      prompt:
          'Suggest concrete ways I can increase my savings rate this month.',
      icon: Icons.rocket_launch_outlined,
      color: Color(0xFF51CF66),
    ),
    _QuickQuestion(
      label: 'Recent transactions',
      prompt:
          'Summarize my recent transactions and highlight anything unusual.',
      icon: Icons.receipt_long_outlined,
      color: Color(0xFF845EF7),
    ),
    _QuickQuestion(
      label: 'Savings goals',
      prompt:
          'How close am I to achieving each of my savings goals? What should I prioritize?',
      icon: Icons.flag_outlined,
      color: Color(0xFF22B8CF),
    ),
    _QuickQuestion(
      label: 'Fee analysis',
      prompt:
          'Analyze how much I am spending on transaction fees and how to minimize them.',
      icon: Icons.percent_outlined,
      color: Color(0xFFE64980),
    ),
    _QuickQuestion(
      label: 'Budget health',
      prompt:
          'Evaluate the health of my budgets. Am I on track or overspending?',
      icon: Icons.health_and_safety_outlined,
      color: Color(0xFF2F9E44),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Scroll to bottom after the first frame so the user lands at the
    // latest message even when navigating back to this page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToBottom();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Load local financial data ─────────────────────────────────────────────
  Future<Map<String, dynamic>> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    final txString = prefs.getString(_keyTransactions) ?? '[]';
    final List<dynamic> transactions = json.decode(txString);

    final budgetStrings = prefs.getStringList(_keyBudgets) ?? [];
    final savingsStrings = prefs.getStringList(_keySavings) ?? [];

    final totalIncome = prefs.getDouble(_keyTotalIncome) ?? 0.0;
    final streakCount = prefs.getInt(_keyStreakCount) ?? 0;
    final streakLevel = prefs.getString(_keyStreakLevel) ?? 'Base';

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

  // ─── Build financial context string ───────────────────────────────────────
  Future<String> _buildFinancialContext() async {
    try {
      final data = await _loadLocalData();
      final fmt = NumberFormat('#,##0', 'en_US');
      String ksh(dynamic v) => 'Ksh ${fmt.format((v as num).round())}';

      final sb = StringBuffer();
      sb.writeln('[$_contextPrefix]');
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

  // ─── Send message to AI backend ───────────────────────────────────────────
  /// [displayText] – the clean user question shown in the chat bubble.
  /// [aiPrompt]    – enriched message (context + question) sent to the AI.
  Future<String> _sendMessageToAI(
    String displayText,
    String aiPrompt,
    String userid,
  ) async {
    try {
      final context = await _buildFinancialContext();
      final enrichedMessage = '$context\n\nUser question: $aiPrompt';

      final response = await http.post(
        Uri.parse('https://fourth-year-backend.onrender.com/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userid,
          'message': enrichedMessage,
          // Provide the clean display text so the backend can save only
          // the human-readable question when it stores the user turn.
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

  // ─── Save the clean user message to Firestore immediately ─────────────────
  /// Writes only the human-readable question to Firestore so it appears
  /// in the StreamBuilder bubble before the AI has responded.
  /// The enriched context message that the backend may also write is filtered
  /// out in the StreamBuilder using [_contextPrefix].
  Future<void> _saveUserMessageLocally(String displayText) async {
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

  // ─── Handle sending ────────────────────────────────────────────────────────
  void _handleSend({String? displayText, String? aiPrompt}) async {
    final userText = displayText ?? _controller.text.trim();
    final promptText = aiPrompt ?? userText;

    if (userText.isEmpty || _isSending) return;

    if (displayText == null) _controller.clear();

    setState(() => _isSending = true);

    // 1️⃣  Write the clean user bubble to Firestore immediately (optimistic UI).
    await _saveUserMessageLocally(userText);
    _scrollToBottom();

    // 2️⃣  Call AI backend – backend saves AI reply (and possibly the enriched
    //     user message) to Firestore. The context bubble is filtered in the UI.
    await _sendMessageToAI(userText, promptText, userUid);

    if (mounted) setState(() => _isSending = false);
    _scrollToBottom();
  }

  // ─── Scroll helpers ────────────────────────────────────────────────────────

  /// Instant jump – used for initial load to avoid animation from top.
  void _jumpToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  /// Animated scroll – used after sending / receiving messages.
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Quick questions bottom sheet ─────────────────────────────────────────
  void _showQuestionsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 14, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: brandGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: brandGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Insights',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                              ),
                        ),
                        Text(
                          'Tap a question to ask Penny AI',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey.shade200),
              // Questions list
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _quickQuestions.length,
                  itemBuilder: (_, i) {
                    final q = _quickQuestions[i];
                    return _QuestionTile(
                      question: q,
                      onTap: () {
                        Navigator.pop(ctx);
                        _handleSend(displayText: q.prompt, aiPrompt: q.prompt);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Text cleaning ─────────────────────────────────────────────────────────
  /// Removes stray single asterisks (*) that are NOT part of a ** pair.
  /// Preserves **bold** markers intact so the formatter can handle them.
  String _cleanAiText(String text) {
    // Replace any single * not preceded or followed by another * with nothing.
    // The negative look-around ensures ** is left untouched.
    return text.replaceAllMapped(
      RegExp(r'(?<!\*)\*(?!\*)'),
      (_) => '',
    );
  }

  // ─── Formatted text parser ─────────────────────────────────────────────────
  /// Parses a raw AI response string and converts:
  ///   **text**  →  bold TextSpan
  ///   [text]    →  bold + underlined TextSpan
  ///   plain     →  normal TextSpan
  List<TextSpan> _parseFormattedText(String raw, {required Color textColor}) {
    // First, strip stray single asterisks.
    final text = _cleanAiText(raw);

    final List<TextSpan> spans = [];
    final pattern = RegExp(r'\*\*(.+?)\*\*|\[(.+?)\]');
    int lastEnd = 0;

    // Shared base style for Poppins at 12sp.
    TextStyle base(
      FontWeight weight, {
      TextDecoration decoration = TextDecoration.none,
    }) => TextStyle(
      fontFamily: 'Poppins',
      fontSize: 12,
      height: 1.5,
      color: textColor,
      fontWeight: weight,
      decoration: decoration,
      decorationColor: textColor,
    );

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: base(FontWeight.normal),
          ),
        );
      }

      if (match.group(1) != null) {
        // **text** → bold
        spans.add(
          TextSpan(
            text: match.group(1),
            style: base(FontWeight.w600),
          ),
        );
      } else if (match.group(2) != null) {
        // [text] → bold + underline
        spans.add(
          TextSpan(
            text: match.group(2),
            style: base(FontWeight.w600, decoration: TextDecoration.underline),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: base(FontWeight.normal),
        ),
      );
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text, style: base(FontWeight.normal)));
    }

    return spans;
  }

  // ─── Build message bubble ──────────────────────────────────────────────────
  Widget _buildMessage(ChatMessage message) {
    final isUser = message.sender == MessageSender.user;
    final timeStr = DateFormat('HH:mm').format(message.timestamp);
    final textColor = isUser
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _Avatar(isUser: false),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  // Slightly wider bubble – 80% of screen width.
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.80,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? accentColor
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: message.isLoading
                      ? const _TypingIndicator()
                      : RichText(
                          text: TextSpan(
                            children: isUser
                                ? [
                                    TextSpan(
                                      text: message.text,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        height: 1.5,
                                        color: textColor,
                                      ),
                                    ),
                                  ]
                                : _parseFormattedText(
                                    message.text,
                                    textColor: textColor,
                                  ),
                          ),
                        ),
                ),
              ),
              if (isUser) ...[const SizedBox(width: 8), _Avatar(isUser: true)],
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 46,
              right: isUser ? 46 : 0,
            ),
            child: Text(
              timeStr,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Input widget ──────────────────────────────────────────────────────────
  Widget _buildInputWidget() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Quick questions trigger
            GestureDetector(
              onTap: _showQuestionsSheet,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: brandGreen,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask Penny AI anything…',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFFAAAAAA),
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : () => _handleSend(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isSending ? Colors.grey.shade300 : brandGreen,
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Welcome banner ────────────────────────────────────────────────────────
  Widget _buildWelcomeBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brandGreen.withOpacity(0.85), accentColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: brandGreen.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🤖', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hello! I'm Penny AI",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your smart finance assistant. Tap ✨ or type to ask me anything about your finances.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const CustomHeader(headerName: 'Penny AI'),
        actions: [
          Tooltip(
            message: 'Quick Insights',
            child: InkWell(
              onTap: _showQuestionsSheet,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: brandGreen.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: brandGreen, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'Ask',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: brandGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userUid)
                  .collection('chats')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                // ── FIX 1: Filter out any message whose content contains the
                //    financial-context header. This prevents the enriched user
                //    message saved by the backend from appearing as a bubble. ──
                final messages = docs
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final content =
                          (data['content'] as String? ?? '').trim();
                      return !content.contains(_contextPrefix) &&
                          !content.startsWith('[USER FINANCIAL DATA CONTEXT]');
                    })
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final ts = data['timestamp'];
                      final dt =
                          ts is Timestamp ? ts.toDate() : DateTime.now();
                      return ChatMessage(
                        data['content'] ?? '',
                        data['role'] == 'user'
                            ? MessageSender.user
                            : MessageSender.ai,
                        dt,
                      );
                    })
                    .toList();

                final showWelcome = messages.isEmpty;

                // Scroll to bottom whenever the stream emits new data.
                // On first load use a jump (no animation) so the user lands
                // at the bottom instantly without seeing a scroll animation
                // from the top.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_initialScrollDone) {
                    _initialScrollDone = true;
                    _jumpToBottom();
                  } else {
                    _scrollToBottom();
                  }
                });

                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  children: [
                    if (showWelcome) _buildWelcomeBanner(),
                    if (showWelcome)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _quickQuestions.take(4).map((q) {
                            return GestureDetector(
                              onTap: () => _handleSend(
                                displayText: q.prompt,
                                aiPrompt: q.prompt,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: q.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: q.color.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(q.icon, color: q.color, size: 14),
                                    const SizedBox(width: 5),
                                    Text(
                                      q.label,
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: q.color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ...messages.map((m) => _buildMessage(m)),
                    // Typing indicator while waiting for AI
                    if (_isSending)
                      _buildMessage(
                        ChatMessage(
                          '',
                          MessageSender.ai,
                          DateTime.now(),
                          isLoading: true,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildInputWidget(),
        ],
      ),
    );
  }
}

// ─── Avatar widget ────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final bool isUser;
  const _Avatar({required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isUser
            ? accentColor.withOpacity(0.15)
            : brandGreen.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: isUser
              ? accentColor.withOpacity(0.4)
              : brandGreen.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Icon(
        isUser ? Icons.person_outline : Icons.smart_toy_outlined,
        size: 16,
        color: isUser ? accentColor : brandGreen,
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      _controllers.add(ctrl);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 7,
              height: 7 + (_controllers[i].value * 5),
              decoration: BoxDecoration(
                color: brandGreen.withOpacity(
                  0.6 + _controllers[i].value * 0.4,
                ),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Question tile ────────────────────────────────────────────────────────────
class _QuestionTile extends StatelessWidget {
  final _QuickQuestion question;
  final VoidCallback onTap;

  const _QuestionTile({required this.question, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: question.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: question.color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: question.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(question.icon, color: question.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: question.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    question.prompt,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11.5,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}