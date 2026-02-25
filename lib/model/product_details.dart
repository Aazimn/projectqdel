import 'package:projectqdel/model/product_image.dart';

class ProductDetails {
  final int id;
  final String name;
  final String description;
  final String volume;
  final double actualWeight;
  final List<ProductImage> images;

  ProductDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.volume,
    required this.actualWeight,
    required this.images,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      volume: json['volume'],
      actualWeight: (json['actual_weight'] as num).toDouble(),
      images: (json['images'] as List)
          .map((e) => ProductImage.fromJson(e))
          .toList(),
    );
  }
}