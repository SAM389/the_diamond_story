import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../models/sale.dart';

class SalesPdfService {
  static const String _companyName = 'THE DIAMOND STORY';
  static const String _addressLine1 = 'A/320, Diamond Village,';
  static const String _addressLine2 = 'Jadakhadi, Mahidharpura,';
  static const String _addressLine3 = 'Surat 395003';
  static const String _contact = '8000354314 / 9820988523';

  static Future<Uint8List> buildSaleBillPdf(Sale sale) async {
    final doc = pw.Document();

    final rows = _buildRows(sale);
    final total = rows.fold<double>(0.0, (sum, row) => sum + row.price);
    final remark = (sale.notes ?? '').trim().isEmpty ? '-' : sale.notes!.trim();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (context) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    _companyName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(_addressLine1),
                          pw.Text(_addressLine2),
                          pw.Text(_addressLine3),
                          pw.SizedBox(height: 4),
                          pw.Text('Contact no: $_contact'),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Text('Date of sales: ${_displayDate(sale.date)}'),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text('Bill no: ${sale.billNo ?? '-'}'),
                pw.SizedBox(height: 10),
                pw.Text('To: ${sale.partyName ?? '-'}'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.7),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.8),
              1: const pw.FlexColumnWidth(2.7),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(2.2),
            },
            headers: const [
              'No',
              'Description of Goods',
              'Carats',
              'Price (Rs)',
              'Remark',
            ],
            data: rows
                .asMap()
                .entries
                .map(
                  (entry) => [
                    (entry.key + 1).toString(),
                    entry.value.description,
                    entry.value.carats,
                    _formatRs(entry.value.price),
                    remark,
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 14),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey500),
              ),
              child: pw.Text(
                'Total: ${_formatRs(total)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  static String buildFileName(Sale sale) {
    final base = (sale.billNo ?? 'sale_${sale.id ?? 'bill'}')
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final dateStamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-')
        .replaceAll('T', '_');
    return '${base}_$dateStamp.pdf';
  }

  static List<_BillRow> _buildRows(Sale sale) {
    if (sale.items.isNotEmpty) {
      return sale.items
          .map(
            (item) => _BillRow(
              description: item.diamondCode?.trim().isNotEmpty == true
                  ? item.diamondCode!.trim()
                  : 'Diamond #${item.diamondId}',
              carats: item.diamondWeight == null
                  ? '-'
                  : '${item.diamondWeight!.toStringAsFixed(3)} ct',
              price: item.amount,
            ),
          )
          .toList();
    }

    return [
      _BillRow(
        description: (sale.diamondCode ?? '-').trim().isEmpty ? '-' : sale.diamondCode!,
        carats: '-',
        price: sale.price,
      ),
    ];
  }

  static String _displayDate(String date) {
    try {
      final parsed = DateFormat('yyyy-MM-dd').parseStrict(date);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }

  static String _formatRs(double amount) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return 'Rs ${formatter.format(amount)}';
  }
}

class _BillRow {
  final String description;
  final String carats;
  final double price;

  const _BillRow({
    required this.description,
    required this.carats,
    required this.price,
  });
}
