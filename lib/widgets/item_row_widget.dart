import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/invoice_model.dart';

class ItemRowWidget extends StatefulWidget {
  final InvoiceItem item;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const ItemRowWidget({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  State<ItemRowWidget> createState() => _ItemRowWidgetState();
}

class _ItemRowWidgetState extends State<ItemRowWidget> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _descCtrl = TextEditingController(text: widget.item.description);
    _priceCtrl = TextEditingController(
      text: widget.item.price > 0 ? widget.item.price.toStringAsFixed(0) : '',
    );
    _qtyCtrl = TextEditingController(text: widget.item.quantity.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _update() {
    widget.item.name = _nameCtrl.text;
    widget.item.description = _descCtrl.text;
    widget.item.price = double.tryParse(_priceCtrl.text) ?? 0;
    widget.item.quantity = int.tryParse(_qtyCtrl.text) ?? 1;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final total = (double.tryParse(_priceCtrl.text) ?? 0) *
        (int.tryParse(_qtyCtrl.text) ?? 1);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildField(
                    controller: _nameCtrl,
                    label: 'Item Name',
                    hint: 'e.g. Strawberry Syrup',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: _buildField(
                    controller: _descCtrl,
                    label: 'Description',
                    hint: 'Optional',
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove item',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _priceCtrl,
                    label: 'Price',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildField(
                    controller: _qtyCtrl,
                    label: 'Qty',
                    hint: '1',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 8),
                // Computed total display
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B8EC4).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF9B8EC4).withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          total.toStringAsFixed(0),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF6A5ACD),
                          ),
                        ),
                      ],
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
      onChanged: (_) {
        setState(() {}); // Refresh total display
        _update();
      },
    );
  }
}
