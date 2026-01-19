import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/expense.dart';

class ExpenseReportService {
  static final _dateFormat = DateFormat('MMM dd, yyyy');

  /// Convert currency code to text symbol (ASCII-safe)
  static String _getCurrencyText(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return 'USD';
      case 'NGN':
        return 'NGN';
      case 'GHS':
        return 'GHS';
      case 'KES':
        return 'KES';
      case 'ZAR':
        return 'ZAR';
      case 'EUR':
        return 'EUR';
      case 'GBP':
        return 'GBP';
      default:
        return currencyCode;
    }
  }

  /// Sanitize text to ensure it only contains ASCII-safe characters
  static String _sanitizeText(String text) {
    // Remove or replace any non-ASCII characters
    return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
  }

  /// Format amount with currency (ASCII-safe)
  static String _formatAmount(double amount, String currency) {
    return '${_getCurrencyText(currency)} ${amount.toStringAsFixed(2)}';
  }

  /// Generate PDF report for expenses
  static Future<File> generatePdfReport({
    required List<Expense> expenses,
    required DateTimeRange dateRange,
    required Map<ExpenseCategory, double> categoryBreakdown,
    required double totalAmount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(dateRange, totalAmount, expenses.length),
          pw.SizedBox(height: 24),

          // Summary Section
          _buildSummarySection(totalAmount, expenses.length),
          pw.SizedBox(height: 24),

          // Category Breakdown
          _buildCategoryBreakdown(categoryBreakdown, totalAmount),
          pw.SizedBox(height: 24),

          // Expense Details Table
          _buildExpenseTable(expenses),
          pw.SizedBox(height: 24),

          // Footer
          _buildFooter(),
        ],
      ),
    );

    // Save PDF to temporary directory
    final output = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${output.path}/expense_report_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Share PDF report
  static Future<void> shareReport(File pdfFile, {Rect? sharePositionOrigin}) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'Expense Report',
      text: 'Please find attached expense report',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static pw.Widget _buildHeader(DateTimeRange dateRange, double total, int count) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expense Report',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Period: ${_dateFormat.format(dateRange.start)} - ${_dateFormat.format(dateRange.end)}',
          style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  static pw.Widget _buildSummarySection(double total, int count) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCard('Total Expenses', '${total.toStringAsFixed(2)}'),
          _buildSummaryCard('Transactions', count.toString()),
          _buildSummaryCard(
            'Average',
            '${(count > 0 ? total / count : 0).toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryCard(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          _sanitizeText(label),
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          _sanitizeText(value),
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCategoryBreakdown(
    Map<ExpenseCategory, double> breakdown,
    double total,
  ) {
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Category Breakdown',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Category', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
                _buildTableCell('Percentage', isHeader: true),
              ],
            ),
            // Data rows
            ...sortedEntries.map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return pw.TableRow(
                children: [
                  _buildTableCell(entry.key.displayName),
                  _buildTableCell('${entry.value.toStringAsFixed(2)}'),
                  _buildTableCell('$percentage%'),
                ],
              );
            }),
            // Total row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _buildTableCell('Total', isHeader: true),
                _buildTableCell('${total.toStringAsFixed(2)}', isHeader: true),
                _buildTableCell('100%', isHeader: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildExpenseTable(List<Expense> expenses) {
    // Sort by date descending
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expense Details',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Date', isHeader: true),
                _buildTableCell('Category', isHeader: true),
                _buildTableCell('Description', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
              ],
            ),
            // Data rows
            ...sortedExpenses.map((expense) {
              return pw.TableRow(
                children: [
                  _buildTableCell(_dateFormat.format(expense.date)),
                  _buildTableCell(expense.category.displayName),
                  _buildTableCell(
                    expense.description != null && expense.description!.isNotEmpty
                        ? _sanitizeText(expense.description!)
                        : '-',
                  ),
                  _buildTableCell(_formatAmount(expense.amount, expense.currency)),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        _sanitizeText(text),
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 8),
        pw.Text(
          'Smart Farm - Expense Management System',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
        pw.Text(
          'This is an automatically generated report',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
        ),
      ],
    );
  }
}
