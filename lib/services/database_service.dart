import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/invoice_model.dart';

class DatabaseService {
  static const String _invoicesBoxName = 'invoices';
  static const String _lastInvoiceKey = 'last_invoice';
  static Box? _invoicesBox;

  /// Initialize Hive database
  static Future<void> init() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);
    _invoicesBox = await Hive.openBox(_invoicesBoxName);
  }

  /// Save current invoice as the "last working" invoice
  static Future<void> saveLastInvoice(Invoice invoice) async {
    final invoiceJson = _invoiceToJson(invoice);
    await _invoicesBox?.put(_lastInvoiceKey, jsonEncode(invoiceJson));
  }

  /// Load the last working invoice
  static Invoice? loadLastInvoice() {
    final jsonString = _invoicesBox?.get(_lastInvoiceKey);
    if (jsonString == null) return null;
    
    try {
      final json = jsonDecode(jsonString);
      return _invoiceFromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Save an invoice with a specific name
  static Future<void> saveNamedInvoice(String name, Invoice invoice) async {
    final invoiceJson = _invoiceToJson(invoice);
    await _invoicesBox?.put('invoice_$name', jsonEncode(invoiceJson));
    
    // Also save to list of saved invoice names
    final savedNames = getSavedInvoiceNames();
    if (!savedNames.contains(name)) {
      savedNames.add(name);
      await _invoicesBox?.put('saved_names', savedNames);
    }
  }

  /// Load a named invoice
  static Invoice? loadNamedInvoice(String name) {
    final jsonString = _invoicesBox?.get('invoice_$name');
    if (jsonString == null) return null;
    
    try {
      final json = jsonDecode(jsonString);
      return _invoiceFromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Get all saved invoice names
  static List<String> getSavedInvoiceNames() {
    final names = _invoicesBox?.get('saved_names');
    if (names == null) return [];
    return List<String>.from(names);
  }

  /// Delete a saved invoice
  static Future<void> deleteNamedInvoice(String name) async {
    await _invoicesBox?.delete('invoice_$name');
    
    final savedNames = getSavedInvoiceNames();
    savedNames.remove(name);
    await _invoicesBox?.put('saved_names', savedNames);
  }

  /// Export all data to JSON file for backup
  static Future<File> exportBackup() async {
    final backupData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'lastInvoice': _invoicesBox?.get(_lastInvoiceKey),
      'savedInvoices': <String, dynamic>{},
    };

    // Add all named invoices
    final savedNames = getSavedInvoiceNames();
    for (final name in savedNames) {
      final invoiceData = _invoicesBox?.get('invoice_$name');
      if (invoiceData != null) {
        (backupData['savedInvoices'] as Map<String, dynamic>)[name] = invoiceData;
      }
    }

    // Save to file
    final appDocDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDocDir.path}/backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupFile = File('${backupDir.path}/pak_trader_backup_$timestamp.json');
    await backupFile.writeAsString(jsonEncode(backupData));
    
    return backupFile;
  }

  /// Share backup file via WhatsApp or other apps
  static Future<void> shareBackup(File backupFile) async {
    await Share.shareXFiles(
      [XFile(backupFile.path)],
      text: 'Pak Trader Invoice Backup',
      subject: 'Backup your invoice data',
    );
  }

  /// Import backup from file
  static Future<bool> importBackup() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return false;

      final filePath = result.files.first.path;
      if (filePath == null) return false;

      final file = File(filePath);
      if (!await file.exists()) return false;

      // Read and parse
      final content = await file.readAsString();
      final backupData = jsonDecode(content);

      // Restore last invoice
      if (backupData['lastInvoice'] != null) {
        await _invoicesBox?.put(_lastInvoiceKey, backupData['lastInvoice']);
      }

      // Restore named invoices
      final savedInvoices = backupData['savedInvoices'] as Map<String, dynamic>?;
      if (savedInvoices != null) {
        final List<String> savedNames = [];
        
        for (final entry in savedInvoices.entries) {
          await _invoicesBox?.put('invoice_${entry.key}', entry.value);
          savedNames.add(entry.key);
        }
        
        // Restore saved names list
        await _invoicesBox?.put('saved_names', savedNames);
      }

      return true;
    } catch (e) {
      print('Import error: $e');
      return false;
    }
  }

  /// Convert Invoice to JSON Map
  static Map<String, dynamic> _invoiceToJson(Invoice invoice) {
    return {
      'invoiceNumber': invoice.invoiceNumber,
      'poNumber': invoice.poNumber,
      'invoiceDate': invoice.invoiceDate,
      'dueDate': invoice.dueDate,
      'billFromName': invoice.billFromName,
      'billFromAddress': invoice.billFromAddress,
      'billFromEmail': invoice.billFromEmail,
      'billFromPhone': invoice.billFromPhone,
      'billToName': invoice.billToName,
      'billToAddress': invoice.billToAddress,
      'billToPhone': invoice.billToPhone,
      'discountAmount': invoice.discountAmount,
      'gstAmount': invoice.gstAmount,
      'items': invoice.items.map((item) => {
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'quantity': item.quantity,
      }).toList(),
    };
  }

  /// Convert JSON Map to Invoice
  static Invoice _invoiceFromJson(Map<String, dynamic> json) {
    final invoice = Invoice(
      invoiceNumber: json['invoiceNumber'] ?? '',
      poNumber: json['poNumber'] ?? '',
      invoiceDate: json['invoiceDate'] ?? '',
      dueDate: json['dueDate'] ?? '',
      billFromName: json['billFromName'] ?? '',
      billFromAddress: json['billFromAddress'] ?? '',
      billFromEmail: json['billFromEmail'] ?? '',
      billFromPhone: json['billFromPhone'] ?? '',
      billToName: json['billToName'] ?? '',
      billToAddress: json['billToAddress'] ?? '',
      billToPhone: json['billToPhone'] ?? '',
      discountAmount: (json['discountAmount'] ?? json['taxAmount'] ?? 0).toDouble(),
      gstAmount: (json['gstAmount'] ?? 0).toDouble(),
    );

    final items = json['items'] as List<dynamic>?;
    if (items != null) {
      invoice.items = items.map((item) => InvoiceItem(
        name: item['name'] ?? '',
        description: item['description'] ?? '',
        price: (item['price'] ?? 0).toDouble(),
        quantity: item['quantity'] ?? 1,
      )).toList();
    }

    return invoice;
  }
}
