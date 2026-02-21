import 'package:final_project/Constants/colors.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Shared type configuration used by TransactionCard and EditTransactionSheet
// ─────────────────────────────────────────────────────────────────────────────

class TypeCfg {
  final Color accent;
  final IconData icon;
  final String label;
  const TypeCfg(this.accent, this.icon, this.label);
}

TypeCfg getTypeCfg(String type) {
  switch (type) {
    case 'income':
      return const TypeCfg(
          brandGreen, Icons.arrow_circle_down_rounded, 'INCOME');
    case 'budget_expense':
      return TypeCfg(
          Colors.orange.shade600, Icons.receipt_rounded, 'BUDGET');
    case 'budget_finalized':
      return const TypeCfg(
          brandGreen, Icons.check_circle_outline, 'BUDGET ✓');
    case 'savings_deduction':
    case 'saving_deposit':
      return const TypeCfg(
          Color(0xFF5B8AF0), Icons.savings_outlined, 'SAVINGS');
    case 'savings_withdrawal':
      return TypeCfg(Colors.purple.shade400,
          Icons.account_balance_wallet_outlined, 'WITHDRAWAL');
    default:
      return const TypeCfg(
          errorColor, Icons.arrow_circle_up_outlined, 'EXPENSE');
  }
}
