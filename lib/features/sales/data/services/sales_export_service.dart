import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/sale.dart';

class SalesExportService {
  /// Export sales data to CSV format
  static Future<File> exportToCSV(
    List<Sale> sales, {
    String? fileName,
  }) async {
    final csvData = _generateCSV(sales);
    final directory = await _getExportDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file =
        File('${directory.path}/${fileName ?? "sales_export_$timestamp"}.csv');
    await file.writeAsString(csvData);
    return file;
  }

  /// Generate CSV string from sales data
  static String _generateCSV(List<Sale> sales) {
    final buffer = StringBuffer();

    // CSV Headers
    buffer.writeln(
      'Date,Sale Type,Quantity,Price Per Unit,Total Amount,Currency,Buyer Name,Payment Status,Notes,Group',
    );

    // CSV Rows
    for (final sale in sales) {
      final row = [
        DateFormat('yyyy-MM-dd').format(sale.saleDate),
        sale.saleType.displayName,
        sale.quantity.toString(),
        sale.pricePerUnit.toStringAsFixed(2),
        sale.totalAmount.toStringAsFixed(2),
        sale.currency,
        _escapeCsvField(sale.buyerName ?? ''),
        sale.paymentStatus.displayName,
        _escapeCsvField(sale.notes ?? ''),
        _escapeCsvField(sale.groupTitle ?? ''),
      ];
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Escape CSV fields that contain commas or quotes
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Export sales data to PDF with comprehensive report
  static Future<File> exportToPDF(
    List<Sale> sales, {
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? analytics,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final currencyFormat =
        NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    // Calculate summary metrics if not provided
    final totalRevenue =
        sales.fold<double>(0, (sum, sale) => sum + sale.totalAmount);
    final totalQuantity =
        sales.fold<int>(0, (sum, sale) => sum + sale.quantity);
    final avgSaleValue = sales.isNotEmpty ? totalRevenue / sales.length : 0.0;

    // Payment status breakdown
    final paidSales =
        sales.where((s) => s.paymentStatus == PaymentStatus.paid).toList();
    final pendingSales =
        sales.where((s) => s.paymentStatus == PaymentStatus.pending).toList();
    final partialSales = sales
        .where((s) => s.paymentStatus == PaymentStatus.partiallyPaid)
        .toList();

    final paidAmount =
        paidSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final pendingAmount =
        pendingSales.fold<double>(0, (sum, s) => sum + s.totalAmount);
    final partialAmount =
        partialSales.fold<double>(0, (sum, s) => sum + s.totalAmount);

    // Sale type breakdown
    final birdsSales =
        sales.where((s) => s.saleType == SaleType.birds).toList();
    final eggsSales = sales.where((s) => s.saleType == SaleType.eggs).toList();
    final manureSales =
        sales.where((s) => s.saleType == SaleType.manure).toList();
    final otherSales =
        sales.where((s) => s.saleType == SaleType.other).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title ?? 'Sales Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                if (startDate != null && endDate != null)
                  pw.Text(
                    'Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                pw.Text(
                  'Generated: ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Summary Metrics
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Summary',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPdfMetric('Total Sales', sales.length.toString()),
                    _buildPdfMetric(
                        'Total Revenue', currencyFormat.format(totalRevenue)),
                    _buildPdfMetric(
                        'Avg Sale', currencyFormat.format(avgSaleValue)),
                    _buildPdfMetric('Total Quantity', totalQuantity.toString()),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Payment Status Breakdown
          pw.Text(
            'Payment Status Breakdown',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            data: [
              ['Status', 'Count', 'Amount'],
              [
                'Paid',
                paidSales.length.toString(),
                currencyFormat.format(paidAmount)
              ],
              [
                'Pending',
                pendingSales.length.toString(),
                currencyFormat.format(pendingAmount)
              ],
              [
                'Partially Paid',
                partialSales.length.toString(),
                currencyFormat.format(partialAmount)
              ],
            ],
          ),

          pw.SizedBox(height: 20),

          // Sale Type Breakdown
          pw.Text(
            'Revenue by Sale Type',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            data: [
              ['Type', 'Count', 'Revenue'],
              if (birdsSales.isNotEmpty)
                [
                  'Birds',
                  birdsSales.length.toString(),
                  currencyFormat.format(birdsSales.fold<double>(
                      0, (s, sale) => s + sale.totalAmount)),
                ],
              if (eggsSales.isNotEmpty)
                [
                  'Eggs',
                  eggsSales.length.toString(),
                  currencyFormat.format(eggsSales.fold<double>(
                      0, (s, sale) => s + sale.totalAmount)),
                ],
              if (manureSales.isNotEmpty)
                [
                  'Manure',
                  manureSales.length.toString(),
                  currencyFormat.format(manureSales.fold<double>(
                      0, (s, sale) => s + sale.totalAmount)),
                ],
              if (otherSales.isNotEmpty)
                [
                  'Other',
                  otherSales.length.toString(),
                  currencyFormat.format(otherSales.fold<double>(
                      0, (s, sale) => s + sale.totalAmount)),
                ],
            ],
          ),

          pw.SizedBox(height: 20),

          // Detailed Sales List
          pw.Text(
            'Detailed Sales List',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),

          // Limit to first 100 sales for PDF size
          pw.Table.fromTextArray(
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            data: [
              ['Date', 'Type', 'Qty', 'Price', 'Total', 'Buyer', 'Status'],
              ...sales.take(100).map((sale) => [
                    DateFormat('MM/dd/yy').format(sale.saleDate),
                    sale.saleType.displayName,
                    sale.quantity.toString(),
                    sale.pricePerUnit.toStringAsFixed(2),
                    sale.totalAmount.toStringAsFixed(2),
                    (sale.buyerName ?? '-').length > 15
                        ? '${(sale.buyerName ?? '-').substring(0, 12)}...'
                        : (sale.buyerName ?? '-'),
                    sale.paymentStatus.displayName.substring(0, 4),
                  ]),
            ],
          ),

          if (sales.length > 100)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                '... and ${sales.length - 100} more sales. Export to CSV for complete data.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),

          pw.SizedBox(height: 20),

          // Footer
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Smart Farm Sales Report',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );

    final directory = await _getExportDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/sales_report_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Build a PDF metric widget
  static pw.Widget _buildPdfMetric(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
      ],
    );
  }

  /// Get export directory based on platform
  static Future<Directory> _getExportDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Web platform does not support file system access');
    }

    if (Platform.isAndroid) {
      // Use external storage for Android
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final exportDir = Directory('${directory.path}/SmartFarm/Exports');
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        return exportDir;
      }
    }

    // Fallback to documents directory
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/Exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// Share file using platform share sheet
  static Future<void> shareFile(
    File file, {
    String? subject,
    String? text,
  }) async {
    final xFile = XFile(file.path);
    await Share.shareXFiles(
      [xFile],
      subject: subject ?? 'Sales Export',
      text: text ?? 'Sales data exported from Smart Farm',
    );
  }

  /// Export and share CSV
  static Future<void> exportAndShareCSV(
    List<Sale> sales, {
    String? fileName,
  }) async {
    final file = await exportToCSV(sales, fileName: fileName);
    await shareFile(
      file,
      subject: 'Sales Data Export',
      text:
          'Sales data exported as CSV from Smart Farm. Total sales: ${sales.length}',
    );
  }

  /// Export and share PDF
  static Future<void> exportAndSharePDF(
    List<Sale> sales, {
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? analytics,
  }) async {
    final file = await exportToPDF(
      sales,
      title: title,
      startDate: startDate,
      endDate: endDate,
      analytics: analytics,
    );
    await shareFile(
      file,
      subject: 'Sales Report',
      text:
          'Sales report exported from Smart Farm. Period: ${startDate != null ? DateFormat('MMM dd').format(startDate) : 'All time'}',
    );
  }

  /// Get export file path for display
  static Future<String> getExportPath() async {
    final directory = await _getExportDirectory();
    return directory.path;
  }
}
