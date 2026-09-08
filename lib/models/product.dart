class Product {
  final int itemId;
  final String name;
  final String unit;
  final double retailPrice;
  final double wholesalePrice;
  final double halfWholesalePrice;
  final double exportPrice;
  final double consumerPrice;
  final String currency;

  Product({
    required this.itemId,
    required this.name,
    required this.unit,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.halfWholesalePrice,
    required this.exportPrice,
    required this.consumerPrice,
    required this.currency,
  });

  /// Builds a Product from a mysql1 ResultRow.
  /// Field names match the aliases in the recovered SQL query
  /// (ItemID, NAME, Unit, RetailPrice, WholesalePrice, HalfWholesalePrice,
  ///  ExportPrice, ConsumerPrice, Currency).
  factory Product.fromRow(Map<String, dynamic> row) {
    double _num(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return Product(
      itemId: row['ItemID'] is int
          ? row['ItemID'] as int
          : int.tryParse(row['ItemID']?.toString() ?? '') ?? 0,
      name: row['NAME']?.toString() ?? '',
      unit: row['Unit']?.toString() ?? '',
      retailPrice: _num(row['RetailPrice']),
      wholesalePrice: _num(row['WholesalePrice']),
      halfWholesalePrice: _num(row['HalfWholesalePrice']),
      exportPrice: _num(row['ExportPrice']),
      consumerPrice: _num(row['ConsumerPrice']),
      currency: row['Currency']?.toString() ?? '',
    );
  }
}
