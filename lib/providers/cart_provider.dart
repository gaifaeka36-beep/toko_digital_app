import 'package:flutter/foundation.dart';
import '../helpers/db_helpers.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';

class CartProvider with ChangeNotifier {
  List<ProductModel> _products = [];
  List<CartModel> _cartItems = [];

  List<ProductModel> get products => _products;
  List<CartModel> get cartItems => _cartItems;

  // Hitung total harga belanjaan secara otomatis
  double get totalPrice {
    return _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  // Hitung total jumlah barang di keranjang
  int get totalItemCount {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // Muat data produk dan keranjang dari SQLite saat pertama kali dibuka
  Future<void> fetchProductsAndCart() async {
    _products = await DBHelper.instance.getProducts();
    _cartItems = await DBHelper.instance.getCartItems();
    notifyListeners();
  }

  // Tambahkan item ke keranjang
  Future<void> addToCart(ProductModel product) async {
    await DBHelper.instance.addToCart(product);
    _cartItems = await DBHelper.instance.getCartItems();
    notifyListeners();
  }

  // Ubah kuantitas item (+ / -)
  Future<void> updateQuantity(int cartId, int newQuantity) async {
    await DBHelper.instance.updateQuantity(cartId, newQuantity);
    _cartItems = await DBHelper.instance.getCartItems();
    notifyListeners();
  }

  // Hapus item dari keranjang
  Future<void> removeItem(int cartId) async {
    await DBHelper.instance.deleteCartItem(cartId);
    _cartItems = await DBHelper.instance.getCartItems();
    notifyListeners();
  }
}