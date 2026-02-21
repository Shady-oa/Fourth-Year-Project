import 'dart:convert';

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Savings/financial_service.dart';
import 'package:final_project/SecondaryScreens/Transactions/edit_transaction.dart';
import 'package:final_project/SecondaryScreens/Transactions/transaction_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const String keyTransactions = 'transactions';
  static const String keyBudgets = 'budgets';
  static const String keyTotalIncome = 'total_income';
  static const String keySavings = 'savings';

  // Display list — hidden rows already filtered out.
  List<Map<String, dynamic>> transactions = [];

  // Full raw list from prefs — used only when writing soft-deletes back.
  // Financial calculations use FinancialService (reads prefs directly).
  List<Map<String, dynamic>> _allTxFromPrefs = [];

  List<Budget> budgets = [];
  List<Saving> savings = [];
  String filter = 'all';
  bool isLoading = true;
  double totalIncome = 0.0;
  // Cached financial summary from FinancialService — always in sync with prefs.
  FinancialSummary? _summary;

  // ── Multi-select (bulk soft-delete) ───────────────────────────────────────
  bool _isMultiSelect = false;
  // We track by list position within `transactions` (the display list).
  final Set<int> _selectedIndices = {};

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    loadTransactions();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase().trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> loadTransactions() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final txString = prefs.getString(keyTransactions) ?? '[]';
    // Keep the full raw list for writing soft-deletes back to prefs.
    _allTxFromPrefs = List<Map<String, dynamic>>.from(json.decode(txString));
    // Display list excludes hidden rows.
    transactions = _allTxFromPrefs.where((tx) => tx['hidden'] != true).toList();
    totalIncome = prefs.getDouble(keyTotalIncome) ?? 0.0;

    final budgetStrings = prefs.getStringList(keyBudgets) ?? [];
    budgets = budgetStrings.map((s) => Budget.fromMap(json.decode(s))).toList();

    final savingsStrings = prefs.getStringList(keySavings) ?? [];
    savings = savingsStrings
        .map((s) => Saving.fromMap(json.decode(s)))
        .toList();

    // Use centralised FinancialService so totals match Home / Analytics / Reports.
    // NOTE: FinancialService reads ALL rows (including hidden ones) — this is
    // intentional: hiding a row must never change financial totals.
    _summary = FinancialService.recalculateFromPrefs(prefs);

    setState(() => isLoading = false);
  }

  // ── Bulk soft-delete helpers ───────────────────────────────────────────────

  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelect = !_isMultiSelect;
      _selectedIndices.clear();
    });
  }

  void _toggleSelect(int displayIndex) {
    setState(() {
      if (_selectedIndices.contains(displayIndex)) {
        _selectedIndices.remove(displayIndex);
      } else {
        _selectedIndices.add(displayIndex);
      }
    });
  }

  Future<void> _bulkDelete() async {
    if (_selectedIndices.isEmpty) return;

    // Collect the transaction maps to be hidden.
    final toHide = _selectedIndices.map((i) => transactions[i]).toSet();

    // Mark matching rows hidden in the full prefs list.
    // We match by object identity using date+title+amount for safety.
    for (final row in _allTxFromPrefs) {
      if (toHide.any(
        (h) =>
            h['date'] == row['date'] &&
            h['title'] == row['title'] &&
            h['amount'] == row['amount'],
      )) {
        row['hidden'] = true;
      }
    }

    // Save back to prefs — financial calculations still include hidden rows.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyTransactions, json.encode(_allTxFromPrefs));

    setState(() {
      _isMultiSelect = false;
      _selectedIndices.clear();
    });
    await loadTransactions();
  }

  /// Returns true for any transaction that must be read-only.
  /// Rules:
  ///  • Any saving/budget type is always locked.
  ///  • 'expense' entries whose title starts with
  ///    'Saving fees (non-refundable)' are saving-fee re-logs created by
  ///    FinancialService.refundSavingsPrincipal — they must remain immutable
  ///    even after the linked goal is deleted.
  bool isSavingsOrBudgetTransaction(Map<String, dynamic> tx) {
    const lockedTypes = {
      'savings_deduction',
      'saving_deposit',
      'savings_withdrawal',
      'budget_finalized',
      'budget_expense',
    };
    if (lockedTypes.contains(tx['type'] ?? '')) return true;
    // Also lock saving-fee re-log entries (type == 'expense' but immutable).
    final title = (tx['title'] ?? '').toString();
    if (title.startsWith('Saving fees (non-refundable)')) return true;
    return false;
  }

  // ── Filtering ─────────────────────────────────────────────────────────────
  //
  //  'all'     → every transaction
  //  'income'  → only type == 'income'
  //  'expense' → everything that is NOT income:
  //              normal expenses, savings deposits, saving-fee re-logs,
  //              budget entries, withdrawal display rows — all fall here
  //              because they all reduce the available balance.
  List<Map<String, dynamic>> get typeFilteredTransactions {
    if (filter == 'all') return transactions;
    if (filter == 'income') {
      return transactions.where((tx) => tx['type'] == 'income').toList();
    }
    // 'expense' filter: all non-income transactions
    return transactions.where((tx) => tx['type'] != 'income').toList();
  }

  List<Map<String, dynamic>> get filteredTransactions {
    final base = typeFilteredTransactions;
    if (_searchQuery.isEmpty) return base;

    return base.where((tx) {
      final title = (tx['title'] ?? '').toString().toLowerCase();
      final type = getTypeLabel(tx['type'] ?? '').toLowerCase();
      final rawType = (tx['type'] ?? '').toString().toLowerCase();
      final reason = (tx['reason'] ?? '').toString().toLowerCase();

      String budgetName = '';
      if (tx['budgetId'] != null) {
        final b = budgets.where((b) => b.id == tx['budgetId']).toList();
        if (b.isNotEmpty) budgetName = b.first.name.toLowerCase();
      }

      return title.contains(_searchQuery) ||
          type.contains(_searchQuery) ||
          rawType.contains(_searchQuery) ||
          reason.contains(_searchQuery) ||
          budgetName.contains(_searchQuery);
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> get groupedTransactions {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var tx in filteredTransactions) {
      final date = DateTime.parse(tx['date']);
      final dateKey = DateFormat('dd MMM yyyy').format(date);
      if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
      grouped[dateKey]!.add(tx);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedTx = groupedTransactions;
    final hasSelection = _selectedIndices.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      floatingActionButton: _isMultiSelect
          ? FloatingActionButton.extended(
              backgroundColor: hasSelection
                  ? errorColor
                  : theme.colorScheme.surface,
              foregroundColor: hasSelection
                  ? Colors.white
                  : theme.colorScheme.onSurface,
              icon: Icon(hasSelection ? Icons.delete_sweep : Icons.close),
              label: Text(
                hasSelection
                    ? 'Delete ${_selectedIndices.length} item${_selectedIndices.length == 1 ? '' : 's'}'
                    : 'Cancel',
              ),
              onPressed: hasSelection ? _bulkDelete : _toggleMultiSelect,
            )
          : FloatingActionButton(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              tooltip: 'Select transactions to delete',
              onPressed: _toggleMultiSelect,
              child: const Icon(Icons.checklist_rounded),
            ),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: _isMultiSelect
            ? Text('${_selectedIndices.length} selected')
            : _isSearchVisible
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
                style: theme.textTheme.bodyLarge,
              )
            : const Text('All Transactions'),
        centerTitle: !_isSearchVisible && !_isMultiSelect,
        elevation: 0,
        actions: [
          if (_isMultiSelect)
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedIndices.length == transactions.length) {
                    _selectedIndices.clear();
                  } else {
                    _selectedIndices.addAll(
                      List.generate(transactions.length, (i) => i),
                    );
                  }
                });
              },
              child: Text(
                _selectedIndices.length == transactions.length
                    ? 'Deselect All'
                    : 'Select All',
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isSearchVisible ? Icons.close : Icons.search,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                setState(() {
                  _isSearchVisible = !_isSearchVisible;
                  if (!_isSearchVisible) {
                    _searchCtrl.clear();
                    _searchQuery = '';
                  }
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips (hidden during multi-select to reduce noise)
                if (!_isMultiSelect)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        buildFilterChip('All', 'all', theme),
                        const SizedBox(width: 8),
                        buildFilterChip('Income', 'income', theme),
                        const SizedBox(width: 8),
                        buildFilterChip('Expenses', 'expense', theme),
                      ],
                    ),
                  ),

                if (!_isMultiSelect) buildSummaryCard(theme),

                // Info bar
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isMultiSelect
                        ? Colors.orange.withOpacity(0.08)
                        : accentColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isMultiSelect
                          ? Colors.orange.withOpacity(0.35)
                          : accentColor.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isMultiSelect
                            ? Icons.info_outline
                            : Icons.lock_outline,
                        color: _isMultiSelect
                            ? Colors.orange.shade700
                            : accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isMultiSelect
                              ? 'Select records to remove from history. Financial totals will NOT be affected.'
                              : 'Income & expenses are editable. Savings and budget entries are read-only.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: filteredTransactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No results for "$_searchQuery"'
                                    : 'No transactions found',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Text('Clear search'),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadTransactions,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: groupedTx.length,
                            itemBuilder: (context, index) {
                              final dateKey = groupedTx.keys.elementAt(index);
                              final txList = groupedTx[dateKey]!;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    child: Text(
                                      getDateLabel(dateKey),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withAlpha(80),
                                          ),
                                    ),
                                  ),
                                  ...txList.map((tx) {
                                    // Use position in the DISPLAY list for selection.
                                    final displayIndex = transactions.indexOf(
                                      tx,
                                    );
                                    final isSelected = _selectedIndices
                                        .contains(displayIndex);

                                    final locked = isSavingsOrBudgetTransaction(
                                      tx,
                                    );
                                    return _isMultiSelect
                                        ? _SelectableCard(
                                            transaction: tx,
                                            isSelected: isSelected,
                                            onToggle: () =>
                                                _toggleSelect(displayIndex),
                                          )
                                        : TransactionCard(
                                            transaction: tx,
                                            index: displayIndex,
                                            // Income & expense are editable;
                                            // savings/budget types are locked.
                                            isLocked: locked,
                                            onTap: () =>
                                                _showTransactionDetailSheet(
                                                  context,
                                                  tx,
                                                  displayIndex,
                                                  locked,
                                                ),
                                          );
                                  }),
                                  const SizedBox(height: 8),
                                ],
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget buildFilterChip(String label, String value, ThemeData theme) {
    final isSelected = filter == value;
    return GestureDetector(
      onTap: () => setState(() => filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withAlpha(80),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────
  //
  // Matches the Home page balance-card style (gradient, same typography).
  // Intentionally shows ONLY Income and Expenses to keep the Transactions
  // page focused. Balance and Saved are omitted here as they are shown on
  // the Home page.
  Widget buildSummaryCard(ThemeData theme) {
    final s = _summary;
    final income = s?.totalIncome ?? 0.0;
    final expenses = s?.totalExpenses ?? 0.0;
    final isOverspent = expenses > income;

    // Use errorColor gradient when overspent — mirrors Home page behaviour.
    final gradientStart = isOverspent ? errorColor : accentColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [gradientStart, gradientStart.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientStart.withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles — same as Home page balance card
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -16,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                // ── Income stat ────────────────────────────────────────
                Expanded(
                  child: _buildStat(
                    label: 'Total Income',
                    amount: income,
                    icon: Icons.arrow_circle_down_rounded,
                    alignLeft: true,
                  ),
                ),

                // Divider
                Container(
                  height: 44,
                  width: 1,
                  color: Colors.white.withOpacity(0.25),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),

                // ── Expenses stat ──────────────────────────────────────
                Expanded(
                  child: _buildStat(
                    label: 'Total Expenses',
                    amount: expenses,
                    icon: Icons.arrow_circle_up_rounded,
                    alignLeft: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat({
    required String label,
    required double amount,
    required IconData icon,
    required bool alignLeft,
  }) {
    return Column(
      crossAxisAlignment: alignLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: alignLeft
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (alignLeft) ...[
              Icon(icon, color: Colors.white70, size: 13),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!alignLeft) ...[
              const SizedBox(width: 5),
              Icon(icon, color: Colors.white70, size: 13),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  String getDateLabel(String dateKey) {
    final date = DateFormat('dd MMM yyyy').parse(dateKey);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);
    if (txDate == today) return 'Today';
    if (txDate == yesterday) return 'Yesterday';
    return dateKey;
  }

  String getTypeLabel(String type) {
    switch (type) {
      case 'income':
        return 'Income';
      case 'budget_expense':
        return 'Budget';
      case 'budget_finalized':
        return 'Budget';
      case 'savings_deduction':
        return 'Savings ↓';
      case 'savings_withdrawal':
        return 'Savings ↑';
      case 'expense':
        return 'Expense';
      default:
        return 'Other';
    }
  }

  // ── Transaction Detail Bottom Sheet ───────────────────────────────────────
  //
  // Shown when the user taps any transaction card.  For income/expense (editable)
  // an Edit button is presented.  For locked types only a Close button is shown.
  void _showTransactionDetailSheet(
    BuildContext ctx,
    Map<String, dynamic> tx,
    int displayIndex,
    bool locked,
  ) {
    final type = (tx['type'] ?? 'expense') as String;
    final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
    final txCost =
        double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;
    final reason = (tx['reason'] ?? '').toString().trim();
    final date = DateTime.tryParse(tx['date'] ?? '') ?? DateTime.now();
    final title = (tx['title'] ?? '—').toString();

    // Determine accent colour based on type
    Color accent;
    IconData typeIcon;
    switch (type) {
      case 'income':
        accent = accentColor;
        typeIcon = Icons.arrow_circle_down_rounded;
        break;
      case 'expense':
        accent = errorColor;
        typeIcon = Icons.arrow_circle_up_outlined;
        break;
      case 'budget_expense':
      case 'budget_finalized':
        accent = Colors.orange.shade600;
        typeIcon = Icons.receipt_rounded;
        break;
      case 'savings_deduction':
      case 'saving_deposit':
        accent = const Color(0xFF5B8AF0);
        typeIcon = Icons.savings_outlined;
        break;
      case 'savings_withdrawal':
        accent = Colors.purple.shade400;
        typeIcon = Icons.account_balance_wallet_outlined;
        break;
      default:
        accent = errorColor;
        typeIcon = Icons.receipt_outlined;
    }

    final typeLabel = getTypeLabel(type);
    final numFmt = NumberFormat('#,##0', 'en_US');
    String ksh(double v) => 'Ksh ${numFmt.format(v.round())}';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(sheetCtx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 28,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header row
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(typeIcon, color: accent, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Details',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(
                        sheetCtx,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Detail rows
              _detailRow(sheetCtx, 'Name', title),
              _detailRow(sheetCtx, 'Amount', ksh(amount)),
              if (txCost > 0)
                _detailRow(
                  sheetCtx,
                  'Fee',
                  ksh(txCost),
                  valueColor: Colors.orange,
                ),
              if (txCost > 0)
                _detailRow(sheetCtx, 'Total', ksh(amount + txCost), bold: true),
              if (reason.isNotEmpty) _detailRow(sheetCtx, 'Reason', reason),
              _detailRow(
                sheetCtx,
                'Date',
                DateFormat('d MMM yyyy · h:mm a').format(date),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  if (!locked) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          EditTransactionSheet.show(
                            ctx,
                            transaction: tx,
                            index: displayIndex,
                            onSaved: loadTransactions,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Models (kept local for page self-sufficiency) ─────────────────────────────
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
  }) : expenses = expenses ?? [],
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

// ─────────────────────────────────────────────────────────────────────────────
//  Selectable card — shown only during multi-select mode
// ─────────────────────────────────────────────────────────────────────────────
class _SelectableCard extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isSelected;
  final VoidCallback onToggle;

  const _SelectableCard({
    required this.transaction,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (transaction['title'] ?? 'Transaction').toString();
    final amount =
        double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
    final type = (transaction['type'] ?? 'expense').toString();
    final isIncome = type == 'income';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.red.withOpacity(0.08)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.red.shade300
                  : theme.colorScheme.onSurface.withOpacity(0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red.shade400 : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? Colors.red.shade400
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 14),
              // Title
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: isSelected ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Amount
              Text(
                '${isIncome ? '+' : '-'} Ksh ${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green.shade600 : Colors.red.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
