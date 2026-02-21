import 'package:final_project/Constants/colors.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';
import 'package:flutter/material.dart';

// ─── Transaction Amount Helpers ────────────────────────────────────────────────
double analyticsAmt(Map<String, dynamic> tx) =>
    double.tryParse(tx['amount'].toString()) ?? 0.0;

double analyticsFee(Map<String, dynamic> tx) =>
    double.tryParse(tx['transactionCost']?.toString() ?? '0') ?? 0.0;

// ─── Category Classifier ───────────────────────────────────────────────────────
String categoriseTitle(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('food') ||
      lower.contains('lunch') ||
      lower.contains('dinner') ||
      lower.contains('breakfast') ||
      lower.contains('restaurant') ||
      lower.contains('snack')) {
    return 'Food & Dining';
  }
  if (lower.contains('transport') ||
      lower.contains('uber') ||
      lower.contains('taxi') ||
      lower.contains('fuel') ||
      lower.contains('matatu') ||
      lower.contains('bus')) {
    return 'Transport';
  }
  if (lower.contains('rent') ||
      lower.contains('house') ||
      lower.contains('electricity') ||
      lower.contains('water') ||
      lower.contains('utility')) {
    return 'Housing';
  }
  if (lower.contains('entertainment') ||
      lower.contains('movie') ||
      lower.contains('game') ||
      lower.contains('netflix') ||
      lower.contains('spotify')) {
    return 'Entertainment';
  }
  if (lower.contains('shopping') ||
      lower.contains('clothes') ||
      lower.contains('shoes')) {
    return 'Shopping';
  }
  if (lower.contains('health') ||
      lower.contains('doctor') ||
      lower.contains('pharmacy')) {
    return 'Health';
  }
  if (lower.contains('saved for') || lower.contains('savings')) {
    return 'Savings';
  }
  if (lower.contains('budget')) return 'Budgets';
  return 'Other';
}

// ─── Budget Health Helpers ────────────────────────────────────────────────────
Color budgetHealthColor(Budget b) {
  final pct = b.total > 0 ? (b.totalSpent / b.total) * 100 : 0.0;
  if (pct < 70) return brandGreen;
  if (pct < 90) return Colors.orange;
  return errorColor;
}

String budgetHealthLabel(Budget b) {
  final pct = b.total > 0 ? (b.totalSpent / b.total) * 100 : 0.0;
  if (pct < 70) return 'Healthy';
  if (pct < 90) return 'Warning';
  return 'Over Budget';
}
