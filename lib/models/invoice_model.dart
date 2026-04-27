class InvoiceItem {
  String name;
  String description;
  double price;
  int quantity;

  InvoiceItem({
    this.name = '',
    this.description = '',
    this.price = 0,
    this.quantity = 1,
  });

  double get total => price * quantity;

  InvoiceItem copyWith({
    String? name,
    String? description,
    double? price,
    int? quantity,
  }) {
    return InvoiceItem(
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Invoice {
  String invoiceNumber;
  String poNumber;
  String invoiceDate;
  String dueDate;

  // Bill From
  String billFromName;
  String billFromAddress;
  String billFromEmail;
  String billFromPhone;

  // Bill To (customer/client)
  String billToName;
  String billToAddress;
  String billToPhone;

  List<InvoiceItem> items;
  double discountAmount;
  double gstAmount;

  Invoice({
    this.invoiceNumber = '',
    this.poNumber = '',
    this.invoiceDate = '',
    this.dueDate = '',
    this.billFromName = '',
    this.billFromAddress = '',
    this.billFromEmail = '',
    this.billFromPhone = '',
    this.billToName = '',
    this.billToAddress = '',
    this.billToPhone = '',
    List<InvoiceItem>? items,
    this.discountAmount = 0,
    this.gstAmount = 0,
  }) : items = items ?? [];

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);

  double get grandTotal => subtotal - discountAmount + gstAmount;
}
