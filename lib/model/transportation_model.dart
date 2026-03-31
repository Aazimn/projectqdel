// lib/model/transportation_model.dart
class DeliveryMode {
  final int? id;
  final String name;
  final String discription;

  
  DeliveryMode({
    this.id,
    required this.name,
    required this.discription

  });
  
  factory DeliveryMode.fromJson(Map<String, dynamic> json) {
    return DeliveryMode(
      id: json['id'],
      name: json['name'] ?? '',
      discription: json['description'] ?? ''

    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'discription':discription
    };
  }
  
  DeliveryMode copyWith({
    int? id,
    String? name,
    String? discription,

  }) {
    return DeliveryMode(
      id: id ?? this.id,
      name: name ?? this.name,
      discription: discription ?? this.discription
  
    );
  }
}