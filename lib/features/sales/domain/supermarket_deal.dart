/// Represents a discounted grocery product at a Guatemalan supermarket
/// with prices in Guatemalan Quetzales (GTQ / Q).
class SupermarketDeal {
  const SupermarketDeal({
    required this.id,
    required this.supermarketId,
    required this.supermarketName,
    required this.productName,
    this.brand = '',
    this.category = '',
    required this.regularPriceGtq,
    required this.salePriceGtq,
    required this.discountPercent,
    required this.savingsGtq,
    this.queryTerm = '',
    this.productUrl = '',
  });

  final String id;
  final String supermarketId;
  final String supermarketName;
  final String productName;
  final String brand;
  final String category;
  final double regularPriceGtq;
  final double salePriceGtq;
  final int discountPercent;
  final double savingsGtq;
  final String queryTerm;
  final String productUrl;

  String get formattedSalePrice => 'Q ${salePriceGtq.toStringAsFixed(2)}';
  String get formattedRegularPrice => 'Q ${regularPriceGtq.toStringAsFixed(2)}';
  String get formattedSavings => 'Q ${savingsGtq.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'supermarketId': supermarketId,
        'supermarketName': supermarketName,
        'productName': productName,
        'brand': brand,
        'category': category,
        'regularPriceGtq': regularPriceGtq,
        'salePriceGtq': salePriceGtq,
        'discountPercent': discountPercent,
        'savingsGtq': savingsGtq,
        'queryTerm': queryTerm,
        'productUrl': productUrl,
      };

  factory SupermarketDeal.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    int toInt(dynamic value) {
      if (value is num) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    final reg = toDouble(json['regularPriceGtq']);
    final sale = toDouble(json['salePriceGtq']);
    final savings = json['savingsGtq'] != null
        ? toDouble(json['savingsGtq'])
        : (reg - sale > 0 ? reg - sale : 0.0);
    final discount = json['discountPercent'] != null
        ? toInt(json['discountPercent'])
        : (reg > 0 && reg > sale ? (((reg - sale) / reg) * 100).round() : 0);

    return SupermarketDeal(
      id: json['id']?.toString() ?? '',
      supermarketId: json['supermarketId']?.toString() ?? '',
      supermarketName: json['supermarketName']?.toString() ?? 'Supermercado',
      productName: json['productName']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      regularPriceGtq: reg,
      salePriceGtq: sale,
      discountPercent: discount,
      savingsGtq: savings,
      queryTerm: json['queryTerm']?.toString() ?? '',
      productUrl: json['productUrl']?.toString() ?? '',
    );
  }
}
