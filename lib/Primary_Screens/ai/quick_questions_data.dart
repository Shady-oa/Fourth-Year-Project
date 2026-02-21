import 'package:final_project/Primary_Screens/ai/quick_question.dart';
import 'package:flutter/material.dart';


// ─── Quick questions data ─────────────────────────────────────────────────────
const List<QuickQuestion> kQuickQuestions = [
  QuickQuestion(
    label: 'Spending trends',
    prompt: 'Analyze my spending trends this month based on my transactions.',
    icon: Icons.trending_up,
    color: Color(0xFF6C63FF),
  ),
  QuickQuestion(
    label: 'Reduce expenses',
    prompt:
        'How can I reduce unnecessary expenses based on my spending history?',
    icon: Icons.cut_outlined,
    color: Color(0xFFFF6584),
  ),
  QuickQuestion(
    label: 'Top category',
    prompt: 'What category am I spending the most on, and is it healthy?',
    icon: Icons.donut_large_outlined,
    color: Color(0xFFFFA94D),
  ),
  QuickQuestion(
    label: 'Savings growth',
    prompt:
        'Compare my savings growth over the last 3 months and give insights.',
    icon: Icons.savings_outlined,
    color: Color(0xFF20C997),
  ),
  QuickQuestion(
    label: 'End-of-month balance',
    prompt:
        'Based on my current income and expenses, predict my end-of-month balance.',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF339AF0),
  ),
  QuickQuestion(
    label: 'Budgeting advice',
    prompt:
        'Give me personalized budgeting advice based on my financial data.',
    icon: Icons.lightbulb_outline,
    color: Color(0xFFFFD43B),
  ),
  QuickQuestion(
    label: 'Financial risks',
    prompt:
        'What financial risks do you detect in my current spending and saving patterns?',
    icon: Icons.warning_amber_outlined,
    color: Color(0xFFFF6B6B),
  ),
  QuickQuestion(
    label: 'Increase savings',
    prompt:
        'Suggest concrete ways I can increase my savings rate this month.',
    icon: Icons.rocket_launch_outlined,
    color: Color(0xFF51CF66),
  ),
  QuickQuestion(
    label: 'Recent transactions',
    prompt:
        'Summarize my recent transactions and highlight anything unusual.',
    icon: Icons.receipt_long_outlined,
    color: Color(0xFF845EF7),
  ),
  QuickQuestion(
    label: 'Savings goals',
    prompt:
        'How close am I to achieving each of my savings goals? What should I prioritize?',
    icon: Icons.flag_outlined,
    color: Color(0xFF22B8CF),
  ),
  QuickQuestion(
    label: 'Fee analysis',
    prompt:
        'Analyze how much I am spending on transaction fees and how to minimize them.',
    icon: Icons.percent_outlined,
    color: Color(0xFFE64980),
  ),
  QuickQuestion(
    label: 'Budget health',
    prompt:
        'Evaluate the health of my budgets. Am I on track or overspending?',
    icon: Icons.health_and_safety_outlined,
    color: Color(0xFF2F9E44),
  ),
];
