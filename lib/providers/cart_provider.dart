import 'package:flutter/material.dart';
import '../helpers/db_helpers.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';

class CartProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  List<CartModel> _cartItems = [];

  List<ProductModel> get products => _products;
  List<CartModel> get cartItems => _cartItems;

  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get totalItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  Future<void> fetchProductsAndCart() async {
    try {
      _products = await DBHelper.instance.getProducts();
      _cartItems = await DBHelper.instance.getCartItems();
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> addToCart(ProductModel product) async {
    await DBHelper.instance.addToCart(product);
    await fetchProductsAndCart();
  }

  Future<void> updateQuantity(int cartId, int newQuantity) async {
    await DBHelper.instance.updateQuantity(cartId, newQuantity);
    await fetchProductsAndCart();
  }

  Future<void> deleteCartItem(int cartId) async {
    await DBHelper.instance.deleteCartItem(cartId);
    await fetchProductsAndCart();
  }

  Future<void> clearCart() async {
    await DBHelper.instance.clearCart();
    await fetchProductsAndCart();
  }
}