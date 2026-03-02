import 'package:projectqdel/model/product_image.dart';

class ProductDetails {
  final String? description;
  final String? volume;
  final double? actualWeight;
  // Remove id, name, images if they're not in the response
  // Or make them optional with defaults

  ProductDetails({
    this.description,
    this.volume,
    this.actualWeight,
  });

  factory ProductDetails.fromJson(Map<String, dynamic> json) {
    return ProductDetails(
      description: json['description'] as String?,
      volume: json['volume'] as String?,
      actualWeight: json['actual_weight'] != null 
          ? (json['actual_weight'] as num).toDouble() 
          : null,
    );
  }
}