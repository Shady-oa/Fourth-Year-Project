import 'dart:convert';

import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Savings/financial_service.dart';
import 'package:final_project/SecondaryScreens/Transactions/selectable_transaction_card.dart';
import 'package:final_project/SecondaryScreens/Transactions/transaction_card.dart';
import 'package:final_project/SecondaryScreens/Transactions/transaction_detail_sheet.dart';
import 'package:final_project/SecondaryScreens/Transactions/transaction_filter_chip.dart';
import 'package:final_project/SecondaryScreens/Transactions/transaction_helpers.dart';
import 'package:final_project/SecondaryScreens/Transactions/transaction_models.dart';
import 'package:final_project/SecondaryScreens/Transactions/transaction_summary_card.dart';

import 'package:flutter/material.dart';
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
    savings = savingsStrings.map((s) => Saving.fromMap(json.decode(s))).toList();

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
    return buildGroupedTransactions(filteredTransactions);
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
                        TransactionFilterChip(
                          label: 'All',
                          value: 'all',
                          currentFilter: filter,
                          onSelected: (v) => setState(() => filter = v),
                        ),
                        const SizedBox(width: 8),
                        TransactionFilterChip(
                          label: 'Income',
                          value: 'income',
                          currentFilter: filter,
                          onSelected: (v) => setState(() => filter = v),
                        ),
                        const SizedBox(width: 8),
                        TransactionFilterChip(
                          label: 'Expenses',
                          value: 'expense',
                          currentFilter: filter,
                          onSelected: (v) => setState(() => filter = v),
                        ),
                      ],
                    ),
                  ),

                if (!_isMultiSelect)
                  TransactionSummaryCard(summary: _summary),

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
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 80),
                            itemCount: groupedTx.length,
                            itemBuilder: (context, index) {
                              final dateKey =
                                  groupedTx.keys.elementAt(index);
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
                                    final displayIndex =
                                        transactions.indexOf(tx);
                                    final isSelected = _selectedIndices
                                        .contains(displayIndex);

                                    final locked =
                                        isSavingsOrBudgetTransaction(tx);
                                    return _isMultiSelect
                                        ? SelectableTransactionCard(
                                            transaction: tx,
                                            isSelected: isSelected,
                                            onToggle: () =>
                                                _toggleSelect(displayIndex),
                                          )
                                        : TransactionCard(
                                            transaction: tx,
                                            index: displayIndex,
                                            isLocked: locked,
                                            onTap: () =>
                                                TransactionDetailSheet.show(
                                              context,
                                              tx,
                                              displayIndex,
                                              locked,
                                              loadTransactions,
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
}
