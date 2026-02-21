// ─────────────────────────────────────────────────────────────────────────────
// utils/budget_pdf_exporter.dart
//
// Contains exportBudgetAsPDF — extracted from _BudgetDetailPageState.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:final_project/Components/toast.dart';
import 'package:final_project/Constants/currency_formatter.dart';
import 'package:final_project/Primary_Screens/Budgets/budget_model.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

Future<void> exportBudgetAsPDF(BuildContext context, Budget budget) async {
  try {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMM yyyy');
    final now = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BUDGET REPORT',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(
                'Budget Name: ${budget.name}',
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                'Generated: ${dateFormat.format(now)}',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(5),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BUDGET SUMMARY',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Budget Amount: ${CurrencyFormatter.format(budget.total)}',
                    ),
                    pw.Text(
                      'Amount Spent: ${CurrencyFormatter.format(budget.totalSpent)}',
                    ),
                    pw.Text(
                      'Remaining Balance: ${CurrencyFormatter.format(budget.amountLeft)}',
                    ),
                    pw.Text(
                      'Status: ${budget.isChecked ? "FINALIZED" : "ACTIVE"}',
                    ),
                    if (budget.isChecked && budget.checkedDate != null)
                      pw.Text(
                        'Finalized on: ${dateFormat.format(budget.checkedDate!)}',
                      ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'EXPENSE BREAKDOWN',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              if (budget.expenses.isEmpty)
                pw.Text('No expenses recorded')
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Expense',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...budget.expenses.map(
                      (exp) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(exp.name),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              CurrencyFormatter.format(exp.amount),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              dateFormat.format(exp.createdDate),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text(
                'Total Expenses: ${CurrencyFormatter.format(budget.totalSpent)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/budget_${budget.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Budget Report: ${budget.name}');

    if (context.mounted) {
      AppToast.success(context, 'PDF exported successfully');
    }
  } catch (e) {
    debugPrint('Error exporting PDF: $e');
    if (context.mounted) {
      AppToast.error(context, 'Error exporting PDF: $e');
    }
  }
}
