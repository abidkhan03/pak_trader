import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/invoice_model.dart';

class PdfService {
  // Purple header color matching the invoice screenshot
  static const PdfColor _headerPurple = PdfColor.fromInt(0xFF9B8EC4);
  static const PdfColor _black = PdfColor.fromInt(0xFF000000);
  static const PdfColor _white = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
  static const PdfColor _borderGrey = PdfColor.fromInt(0xFFCCCCCC);
  static const PdfColor _cyanLink = PdfColor.fromInt(0xFF00ACC1);

  /// Generates the invoice PDF and saves it to app documents directory.
  /// Returns the saved [File].
  static Future<File> generateInvoice(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(invoice),
              pw.SizedBox(height: 16),
              _buildItemTable(invoice),
              pw.SizedBox(height: 32),
              _buildSummary(invoice),
              pw.Spacer(),
            ],
          );
        },
      ),
    );

    // Save to Downloads folder
    Directory downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      final dir = await getDownloadsDirectory();
      downloadsDir = dir!;
    }
    
    // Ensure directory exists
    if (!downloadsDir.existsSync()) {
      downloadsDir.createSync(recursive: true);
    }
    
    final fileName =
        'invoice_${invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${downloadsDir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── Header section (purple background) ──────────────────────────────────
  static pw.Widget _buildHeader(Invoice invoice) {
    return pw.Container(
      color: _headerPurple,
      padding: const pw.EdgeInsets.fromLTRB(32, 40, 32, 32),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left: INVOICE title + meta
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 48,
                    fontWeight: pw.FontWeight.bold,
                    color: _black,
                  ),
                ),
                pw.SizedBox(height: 24),
                _metaRow('Invoice #:', invoice.invoiceNumber),
                _metaRow('PO #:', invoice.poNumber),
                _metaRow('Due Date:', invoice.dueDate.isEmpty ? '-' : invoice.dueDate),
                _metaRow('Invoice Date:', invoice.invoiceDate.isEmpty ? '-' : invoice.invoiceDate),
              ],
            ),
          ),
          // Right: Bill From + Bill To
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Bill From:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: _black,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  invoice.billFromName,
                  style: pw.TextStyle(fontSize: 11, color: _black),
                ),
                pw.Text(
                  invoice.billFromAddress,
                  style: pw.TextStyle(fontSize: 11, color: _black),
                ),
                pw.Text(
                  invoice.billFromEmail,
                  style: pw.TextStyle(fontSize: 11, color: _cyanLink),
                ),
                pw.Text(
                  invoice.billFromPhone,
                  style: pw.TextStyle(fontSize: 11, color: _cyanLink),
                ),
                if (invoice.billToName.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Bill To:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _black,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.billToName,
                    style: pw.TextStyle(fontSize: 11, color: _black),
                  ),
                  if (invoice.billToAddress.isNotEmpty)
                    pw.Text(
                      invoice.billToAddress,
                      style: pw.TextStyle(fontSize: 11, color: _black),
                    ),
                  if (invoice.billToPhone.isNotEmpty)
                    pw.Text(
                      invoice.billToPhone,
                      style: pw.TextStyle(fontSize: 11, color: _cyanLink),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: _black),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, color: _black),
          ),
        ],
      ),
    );
  }

  // ── Item table ───────────────────────────────────────────────────────────
  static pw.Widget _buildItemTable(Invoice invoice) {
    const colWidths = [
      pw.FlexColumnWidth(2.5),
      pw.FlexColumnWidth(2.5),
      pw.FlexColumnWidth(1.5),
      pw.FlexColumnWidth(1.5),
      pw.FlexColumnWidth(1.5),
    ];

    final headerCells = ['Item Name', 'Description', 'Price', 'Quantity', 'Total']
        .map(
          (h) => pw.Container(
            color: _black,
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: pw.Text(
              h,
              style: pw.TextStyle(
                color: _white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        )
        .toList();

    final rows = invoice.items.asMap().entries.map((entry) {
      final idx = entry.key;
      final item = entry.value;
      final bg = idx.isEven ? _white : _lightGrey;
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: bg),
        children: [
          _tableCell(item.name, align: pw.Alignment.centerLeft),
          _tableCell(item.description.isEmpty ? '-' : item.description,
              align: pw.Alignment.centerLeft),
          _tableCell(item.price.toStringAsFixed(0), align: pw.Alignment.centerRight),
          _tableCell(item.quantity.toString(), align: pw.Alignment.centerRight),
          _tableCell(item.total.toStringAsFixed(0), align: pw.Alignment.centerRight),
        ],
      );
    }).toList();

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 32),
      child: pw.Table(
        columnWidths: {
          0: colWidths[0],
          1: colWidths[1],
          2: colWidths[2],
          3: colWidths[3],
          4: colWidths[4],
        },
        border: pw.TableBorder.all(color: _borderGrey, width: 0.5),
        children: [
          pw.TableRow(children: headerCells),
          ...rows,
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, {pw.Alignment? align}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      alignment: align ?? pw.Alignment.centerLeft,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, color: _black)),
    );
  }

  // ── Summary box (bottom right) ───────────────────────────────────────────
  static pw.Widget _buildSummary(Invoice invoice) {
    final rows = <pw.Widget>[
      _summaryRow(
        'Subtotal:',
        invoice.subtotal.toStringAsFixed(0),
        bold: false,
      ),
    ];
    
    // Add discount row if applicable
    if (invoice.discountAmount > 0) {
      rows.add(pw.Divider(height: 0, thickness: 0.5, color: _borderGrey));
      rows.add(_summaryRow(
        'Discount:',
        '-${invoice.discountAmount.toStringAsFixed(0)}',
        bold: false,
      ));
    }
    
    // Add GST row if applicable
    if (invoice.gstAmount > 0) {
      rows.add(pw.Divider(height: 0, thickness: 0.5, color: _borderGrey));
      rows.add(_summaryRow(
        'GST:',
        invoice.gstAmount.toStringAsFixed(0),
        bold: false,
      ));
    }
    
    rows.add(pw.Divider(height: 0, thickness: 0.5, color: _borderGrey));
    rows.add(_summaryRow(
      'Amount Due:',
      invoice.grandTotal.toStringAsFixed(0),
      bold: true,
      darkBg: true,
    ));
    
    return pw.Padding(
      padding: const pw.EdgeInsets.only(right: 32),
      child: pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Container(
          width: 220,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _borderGrey, width: 0.8),
          ),
          child: pw.Column(
            children: rows,
          ),
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    bool darkBg = false,
  }) {
    final textColor = darkBg ? _white : _black;
    final bg = darkBg ? _black : _white;
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
