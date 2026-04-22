import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice_model.dart';
import '../services/pdf_service.dart';
import '../services/database_service.dart';
import '../widgets/item_row_widget.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({super.key});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Invoice info controllers (pre-filled with sample data)
  final _invoiceNumCtrl = TextEditingController(text: '26595');
  final _poNumCtrl = TextEditingController(text: '03051115420');
  final _invoiceDateCtrl = TextEditingController(text: '14-03-26');
  final _dueDateCtrl = TextEditingController(text: '-');

  // Bill From controllers
  final _billNameCtrl = TextEditingController(text: 'Pakistan trader');
  final _billAddressCtrl = TextEditingController(text: 'Quetta airport road');
  final _billEmailCtrl = TextEditingController(text: 'Maliknasir3516@gmail.com');
  final _billPhoneCtrl = TextEditingController(text: '03051115420');

  // Bill To controllers (customer/client)
  final _billToNameCtrl = TextEditingController();
  final _billToAddressCtrl = TextEditingController();
  final _billToPhoneCtrl = TextEditingController();

  // Tax controller
  final _taxCtrl = TextEditingController(text: '0');

  bool _isGenerating = false;
  bool _isSaving = false;
  bool _isRestoring = false;

  // Pre-filled items from screenshot
  late List<InvoiceItem> _items;

  // Saved invoice name for storage
  final _saveNameCtrl = TextEditingController();
  List<String> _savedInvoiceNames = [];

  @override
  void initState() {
    super.initState();
    _loadLastInvoice();
    _refreshSavedNames();
  }

  /// Load the last working invoice from database
  void _loadLastInvoice() {
    final lastInvoice = DatabaseService.loadLastInvoice();
    if (lastInvoice != null) {
      _populateFields(lastInvoice);
    } else {
      // Use default sample data
      _items = [
        InvoiceItem(name: 'strawberry syrup', description: '-', price: 1200, quantity: 5),
        InvoiceItem(name: 'blue lagoon syrup', description: '-', price: 1200, quantity: 5),
        InvoiceItem(name: 'Mint syrup', description: '-', price: 1200, quantity: 5),
        InvoiceItem(name: 'Margrita syrup', description: '-', price: 1200, quantity: 5),
      ];
    }
  }

  /// Populate form fields from invoice
  void _populateFields(Invoice invoice) {
    _invoiceNumCtrl.text = invoice.invoiceNumber;
    _poNumCtrl.text = invoice.poNumber;
    _invoiceDateCtrl.text = invoice.invoiceDate;
    _dueDateCtrl.text = invoice.dueDate;
    _billNameCtrl.text = invoice.billFromName;
    _billAddressCtrl.text = invoice.billFromAddress;
    _billEmailCtrl.text = invoice.billFromEmail;
    _billPhoneCtrl.text = invoice.billFromPhone;
    _billToNameCtrl.text = invoice.billToName;
    _billToAddressCtrl.text = invoice.billToAddress;
    _billToPhoneCtrl.text = invoice.billToPhone;
    _taxCtrl.text = invoice.taxAmount.toStringAsFixed(0);
    _items = List.from(invoice.items);
  }

  /// Refresh list of saved invoice names
  void _refreshSavedNames() {
    setState(() {
      _savedInvoiceNames = DatabaseService.getSavedInvoiceNames();
    });
  }

  @override
  void dispose() {
    _invoiceNumCtrl.dispose();
    _poNumCtrl.dispose();
    _invoiceDateCtrl.dispose();
    _dueDateCtrl.dispose();
    _billNameCtrl.dispose();
    _billAddressCtrl.dispose();
    _billEmailCtrl.dispose();
    _billPhoneCtrl.dispose();
    _billToNameCtrl.dispose();
    _billToAddressCtrl.dispose();
    _billToPhoneCtrl.dispose();
    _taxCtrl.dispose();
    _saveNameCtrl.dispose();
    super.dispose();
  }

  /// Save current invoice as "last working" invoice
  Future<void> _autoSave() async {
    await DatabaseService.saveLastInvoice(_buildInvoice());
  }

  /// Save invoice with a specific name
  Future<void> _saveNamedInvoice() async {
    if (_saveNameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a name to save', error: true);
      return;
    }
    
    setState(() => _isSaving = true);
    try {
      await DatabaseService.saveNamedInvoice(
        _saveNameCtrl.text.trim(),
        _buildInvoice(),
      );
      _refreshSavedNames();
      _showSnack('Invoice saved as "${_saveNameCtrl.text.trim()}"');
      _saveNameCtrl.clear();
    } catch (e) {
      _showSnack('Error saving: $e', error: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Load a saved invoice
  void _loadSavedInvoice(String name) {
    final invoice = DatabaseService.loadNamedInvoice(name);
    if (invoice != null) {
      setState(() {
        _populateFields(invoice);
      });
      _showSnack('Loaded "$name"');
      _autoSave(); // Also save as last working
    }
  }

  /// Delete a saved invoice
  Future<void> _deleteSavedInvoice(String name) async {
    await DatabaseService.deleteNamedInvoice(name);
    _refreshSavedNames();
    _showSnack('Deleted "$name"');
  }

  /// Export backup file
  Future<void> _exportBackup() async {
    setState(() => _isSaving = true);
    try {
      final backupFile = await DatabaseService.exportBackup();
      await DatabaseService.shareBackup(backupFile);
      _showSnack('Backup created and ready to share');
    } catch (e) {
      _showSnack('Error creating backup: $e', error: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Import from backup file
  Future<void> _importBackup() async {
    setState(() => _isRestoring = true);
    try {
      final success = await DatabaseService.importBackup();
      if (success) {
        _refreshSavedNames();
        // Load the last invoice from backup
        final lastInvoice = DatabaseService.loadLastInvoice();
        if (lastInvoice != null) {
          setState(() {
            _populateFields(lastInvoice);
          });
        }
        _showSnack('Backup restored successfully');
      } else {
        _showSnack('No file selected or invalid backup', error: true);
      }
    } catch (e) {
      _showSnack('Error restoring backup: $e', error: true);
    } finally {
      setState(() => _isRestoring = false);
    }
  }

  Invoice _buildInvoice() {
    return Invoice(
      invoiceNumber: _invoiceNumCtrl.text,
      poNumber: _poNumCtrl.text,
      invoiceDate: _invoiceDateCtrl.text,
      dueDate: _dueDateCtrl.text,
      billFromName: _billNameCtrl.text,
      billFromAddress: _billAddressCtrl.text,
      billFromEmail: _billEmailCtrl.text,
      billFromPhone: _billPhoneCtrl.text,
      billToName: _billToNameCtrl.text,
      billToAddress: _billToAddressCtrl.text,
      billToPhone: _billToPhoneCtrl.text,
      items: List.from(_items),
      taxAmount: double.tryParse(_taxCtrl.text) ?? 0,
    );
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.total);
  double get _tax => double.tryParse(_taxCtrl.text) ?? 0;
  double get _grandTotal => _subtotal + _tax;

  Future<File?> _generate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    if (_items.isEmpty) {
      _showSnack('Add at least one item.', error: true);
      return null;
    }

    setState(() => _isGenerating = true);
    try {
      // Request storage permission on older Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (status.isDenied) {
          _showSnack('Storage permission denied.', error: true);
          return null;
        }
      }
      final file = await PdfService.generateInvoice(_buildInvoice());
      return file;
    } catch (e) {
      _showSnack('Error generating PDF: $e', error: true);
      return null;
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _onGeneratePdf() async {
    final file = await _generate();
    if (file == null) return;
    _showSnack('PDF saved: ${file.path}');
  }

  Future<void> _onShareWhatsApp() async {
    final file = await _generate();
    if (file == null) return;

    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice #${_invoiceNumCtrl.text}',
        subject: 'Invoice from ${_billNameCtrl.text}',
      );
    } catch (e) {
      _showSnack('Error sharing: $e', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ─────────────────────────────── BUILD ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F3FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9B8EC4),
        foregroundColor: Colors.white,
        title: const Text(
          'Invoice Generator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionCard(
                title: 'Invoice Info',
                icon: Icons.receipt_long,
                children: [
                  _row([
                    _field(_invoiceNumCtrl, 'Invoice #', required: true),
                    _field(_poNumCtrl, 'PO #'),
                  ]),
                  const SizedBox(height: 12),
                  _row([
                    _field(_invoiceDateCtrl, 'Invoice Date'),
                    _field(_dueDateCtrl, 'Due Date'),
                  ]),
                ],
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Bill From',
                icon: Icons.store,
                children: [
                  _field(_billNameCtrl, 'Business Name', required: true),
                  const SizedBox(height: 12),
                  _field(_billAddressCtrl, 'Address'),
                  const SizedBox(height: 12),
                  _row([
                    _field(
                      _billEmailCtrl,
                      'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v != null && v.isNotEmpty && !v.contains('@')) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                    _field(
                      _billPhoneCtrl,
                      'Phone',
                      keyboardType: TextInputType.phone,
                    ),
                  ]),
                ],
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Bill To (Customer / Client)',
                icon: Icons.person,
                children: [
                  _field(_billToNameCtrl, 'Customer / Company Name', required: true),
                  const SizedBox(height: 12),
                  _field(_billToAddressCtrl, 'Address (optional)'),
                  const SizedBox(height: 12),
                  _field(
                    _billToPhoneCtrl,
                    'Phone (optional)',
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildItemsSection(),
              const SizedBox(height: 16),
              _buildSaveLoadSection(),
              const SizedBox(height: 16),
              _buildBackupSection(),
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, color: Color(0xFF9B8EC4)),
                const SizedBox(width: 8),
                const Text(
                  'Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A3F6B),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _items.add(InvoiceItem(quantity: 1));
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6A5ACD),
                  ),
                ),
              ],
            ),
            const Divider(),
            if (_items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No items yet. Tap "Add Item" to begin.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (ctx, i) => ItemRowWidget(
                  key: ValueKey(_items[i]),
                  item: _items[i],
                  onDelete: () => setState(() => _items.removeAt(i)),
                  onChanged: () => setState(() {}),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveLoadSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.save, color: Color(0xFF9B8EC4)),
                const SizedBox(width: 8),
                const Text(
                  'Save & Load Invoices',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A3F6B),
                  ),
                ),
              ],
            ),
            const Divider(),
            // Save current invoice
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _saveNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Invoice Name (e.g., Client_April)',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveNamedInvoice,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A5ACD),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Saved invoices list
            if (_savedInvoiceNames.isNotEmpty) ...[
              const Text(
                'Saved Invoices:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _savedInvoiceNames.map((name) => Chip(
                  label: Text(name),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _deleteSavedInvoice(name),
                  backgroundColor: const Color(0xFF9B8EC4).withOpacity(0.2),
                  side: BorderSide(color: const Color(0xFF9B8EC4).withOpacity(0.4)),
                )).toList(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Load Saved Invoice',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  value: null,
                  hint: const Text('Select invoice to load...'),
                  items: _savedInvoiceNames.map((name) => DropdownMenuItem(
                    value: name,
                    child: Text(name),
                  )).toList(),
                  onChanged: (name) {
                    if (name != null) _loadSavedInvoice(name);
                  },
                ),
              ),
            ] else
              const Text(
                'No saved invoices yet. Enter a name above and tap Save.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.backup, color: Color(0xFF9B8EC4)),
                const SizedBox(width: 8),
                const Text(
                  'Backup & Restore',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A3F6B),
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(
              'Export all your invoice data to a file. Share via WhatsApp, email, or save to cloud. Restore on any device.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _exportBackup,
                    icon: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload, size: 18),
                    label: const Text('Export Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRestoring ? null : _importBackup,
                    icon: _isRestoring
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download, size: 18),
                    label: const Text('Restore Backup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final subtotal = _subtotal;
    final tax = _tax;
    final grand = _grandTotal;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: Color(0xFF9B8EC4)),
                const SizedBox(width: 8),
                const Text(
                  'Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A3F6B),
                  ),
                ),
              ],
            ),
            const Divider(),
            _summaryLine('Subtotal', subtotal.toStringAsFixed(0)),
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text('Tax', style: TextStyle(fontSize: 14)),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _taxCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '0',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const Divider(thickness: 1.5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount Due',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    grand.toStringAsFixed(0),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _onGeneratePdf,
            icon: _isGenerating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: const Text(
              'Generate PDF',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A5ACD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isGenerating ? null : _onShareWhatsApp,
            icon: const Icon(Icons.share),
            label: const Text(
              'Share via WhatsApp',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────── Helpers ───────────────────────────────────────────

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF9B8EC4)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A3F6B),
                  ),
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
          .take(children.length * 2 - 1)
          .toList(),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null),
    );
  }
}
