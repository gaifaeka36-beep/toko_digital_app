class CartModel {
  final int id;
  final int productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  CartModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      id: map['id'],
      productId: map['product_id'],
      name: map['name'],
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'],
      imageUrl: map['image_url'] ?? '',
    );
  }
}