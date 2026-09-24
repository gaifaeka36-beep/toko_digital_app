import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';
import '../models/cart_model.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  DBHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('toko_digital.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS master_products');
        await db.execute('DROP TABLE IF EXISTS local_cart');
        await _createDB(db, newVersion);
      },
      // Bagian onOpen sengaja dihapus agar data produk baru tersimpan permanen
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE master_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        image_url TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE local_cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        image_url TEXT NOT NULL
      )
    ''');

    await _insertDummyProducts(db);
  }

  Future<void> _insertDummyProducts(Database db) async {
    List<Map<String, dynamic>> dummyProducts = [
      {
        'name': 'kulkas polytron',
        'price': 3200000.0,
        'image_url': 'https://www.ufoelektronika.com/image/cache/catalog/Kulkas/Polytron-Kulkas-Multi-Door-New-Belleza-Inverter-550-Liter-PRS510X-1000x1000.jpg'
      },
      {
        'name': 'megicom panasonic',
        'price': 540000.0,
        'image_url': 'https://image-asset.parto.id/i/8g/b2edcbd6e9d6252111f60a220aaca69c.jpg'
      },
      {
        'name': 'kipas angin cosmos',
        'price': 380000.0,
        'image_url': 'https://media.dinomarket.com/docs/imgTD/2019-07/CosmosKipasStand_16SDB_190719170722_ll.jpg.jpg'
      },
      {
        'name': 'setrika miyako',
        'price': 350000.0,
        'image_url': 'https://static.retailworldvn.com/Products/Images/12229/301855/setrika-kering-maspion-ha-110-350w-600x600.jpg'
      },
    ];

    for (var product in dummyProducts) {
      await db.insert('master_products', product);
    }
  }

  Future<List<ProductModel>> getProducts() async {
    final db = await instance.database;
    final result = await db.query('master_products');
    return result.map((json) => ProductModel.fromMap(json)).toList();
  }

  Future<List<CartModel>> getCartItems() async {
    final db = await instance.database;
    final result = await db.query('local_cart');
    return result.map((json) => CartModel.fromMap(json)).toList();
  }

  Future<void> addToCart(ProductModel product) async {
    final db = await instance.database;

    final existingItem = await db.query(
      'local_cart',
      where: 'product_id = ?',
      whereArgs: [product.id],
    );

    if (existingItem.isNotEmpty) {
      int currentQty = existingItem.first['quantity'] as int;
      int cartId = existingItem.first['id'] as int;

      await db.update(
        'local_cart',
        {'quantity': currentQty + 1},
        where: 'id = ?',
        whereArgs: [cartId],
      );
    } else {
      await db.insert('local_cart', {
        'product_id': product.id,
        'name': product.name,
        'price': product.price,
        'quantity': 1,
        'image_url': product.imageUrl,
      });
    }
  }

  Future<void> updateQuantity(int cartId, int newQuantity) async {
    final db = await instance.database;

    if (newQuantity <= 0) {
      await deleteCartItem(cartId);
    } else {
      await db.update(
        'local_cart',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [cartId],
      );
    }
  }

  Future<void> deleteCartItem(int cartId) async {
    final db = await instance.database;
    await db.delete(
      'local_cart',
      where: 'id = ?',
      whereArgs: [cartId],
    );
  }

  Future<void> clearCart() async {
    final db = await instance.database;
    await db.delete('local_cart');
  }
}