// Mengimpor package sqflite untuk manajemen database SQLite lokal
import 'package:sqflite/sqflite.dart';
// Mengimpor package path untuk menggabungkan jalur direktori penyimpanan file DB
import 'package:path/path.dart';
// Mengimpor model data produk dan keranjang
import '../models/product_model.dart';
import '../models/cart_model.dart';

class DBHelper {
  // 1. Membuat Instance Singleton agar DBHelper hanya dibuat 1 kali dalam aplikasi
  static final DBHelper instance = DBHelper._init();
  static Database? _database;

  // Constructor privat untuk mencegah pembentukan objek DBHelper baru di luar kelas
  DBHelper._init();

  // 2. Getter untuk mendapatkan objek Database
  Future<Database> get database async {
    // Jika database sudah pernah dibuka/diinisialisasi, kembalikan instance yang ada
    if (_database != null) return _database!;
    // Jika belum ada, buat/buka database terlebih dahulu
    _database = await _initDB('toko_digital.db');
    return _database!;
  }

  // 3. Fungsi Inisialisasi Database
  Future<Database> _initDB(String filePath) async {
    // Meminta lokasi path direktori khusus penyimpanan database di perangkat/HP
    final dbPath = await getDatabasesPath();
    // Menggabungkan direktori path dengan nama file database
    final path = join(dbPath, filePath);

    // Membuka database dengan konfigurasi versi dan callback fungsi
    return await openDatabase(
      path,
      version: 13, // Versi 13: Menaikkan versi memicu jalannya 'onUpgrade' jika versi DB di HP berbeda
      onCreate: _createDB, // Dipanggil HANYA saat aplikasi pertama kali dipasang (DB belum ada)
      onUpgrade: (db, oldVersion, newVersion) async {
        // --- LANGKAH MIGRASI AUTO-UPDATE TANPA MENGHAPUS KERANJANG ---
        
        // Langkah A: Hapus hanya tabel produk lama agar daftar produk katalog bisa di-refresh
        await db.execute('DROP TABLE IF EXISTS master_products');
        
        // Langkah B: Buat ulang struktur tabel master_products yang baru
        await db.execute('''
          CREATE TABLE master_products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            image_url TEXT NOT NULL
          )
        ''');
        
        // Langkah C: Isi ulang tabel master_products dengan data produk dummy terbaru
        await _insertDummyProducts(db);

        // CATATAN PENTING: Tabel 'local_cart' DIBIARKAN (TIDAK DI-DROP)
        // Hal ini memastikan data barang yang disave pengguna di keranjang TETAP AMAN & TIDAK HILANG.
      },
    );
  }

  // 4. Fungsi Pembentukan Tabel Awal (Hanya dipanggil pertama kali aplikasi diinstall)
  Future<void> _createDB(Database db, int version) async {
    // Langkah A: Membuat tabel untuk katalog produk utama
    await db.execute('''
      CREATE TABLE master_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        image_url TEXT NOT NULL
      )
    ''');

    // Langkah B: Membuat tabel khusus untuk menyimpan item keranjang belanja lokal
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

    // Langkah C: Masukkan data awal produkdummy ke dalam database yang baru dibuat
    await _insertDummyProducts(db);
  }

  // 5. Fungsi untuk Mengisi Data Dummy Produk ke Database
  Future<void> _insertDummyProducts(Database db) async {
    // Menyiapkan daftar list produk default
    List<Map<String, dynamic>> dummyProducts = [
      {
        'name': 'CRF 150L Extreme Green',
        'price': 32000000.0,
        'image_url':
            'https://imgcdn.oto.com/large/gallery/color/73/1263/honda-crf-150l-color-532433.jpg'
      },
      {
        'name': 'Stylo ABS Spesial Burgundy',
        'price': 34450000.0,
        'image_url':
            'https://r2.astra.co.id/public/articles/01KY3QRCPT1PFKCGFS78QKNNDK.png'
      },
      {
        'name': 'Scoopy Prestige White',
        'price': 23800000.0,
        'image_url':
            'https://www.mpmhondajatim.com/images/optimized-produk_foto-1731480587_New%20Honda%20Scoopy%20-%20Variant%20Web%20-%20Prestige%20White.png'
      },
      {
        'name': 'Vario CBS ISS Matte Black',
        'price': 25000000.0,
        'image_url':
            'https://asset.astra-honda.com/uploads/product-draft/colors/varian-warna-6-1-05122025-010953.jpg'
      },
      {
        'name': 'Sepeda Listrik Exotic Varilux',
        'price': 4500000.0,
        'image_url':
            'https://sparepartgallery.id/wp-content/uploads/2024/03/varilux-pro-1-scaled.jpg'
      },
      {
        'name': 'Sepeda Listrik Uwinfly',
        'price': 4100000.0,
        'image_url':
            'https://prambatanjaya.com/wp-content/uploads/UD66AD.jpg'
      },
    ];

    // Iterasi/perulangan untuk memasukkan setiap item produk ke dalam tabel master_products
    for (var product in dummyProducts) {
      await db.insert('master_products', product);
    }
  }

  // 6. Fungsi Ambil Seluruh Data Produk Katalog
  Future<List<ProductModel>> getProducts() async {
    final db = await instance.database;
    // Mengambil semua baris data dari tabel master_products
    var result = await db.query('master_products');

    // Langkah Pencegahan: Jika karena alasan tertentu data katalog kosong, isi ulang secara otomatis
    if (result.isEmpty) {
      await _insertDummyProducts(db);
      result = await db.query('master_products');
    }

    // Mengubah hasil Map SQLite menjadi bentuk List Objek ProductModel
    return result.map((json) => ProductModel.fromMap(json)).toList();
  }

  // 7. Fungsi Ambil Seluruh Data Isi Keranjang
  Future<List<CartModel>> getCartItems() async {
    final db = await instance.database;
    // Mengambil semua item yang ada di tabel local_cart
    final result = await db.query('local_cart');
    
    // Mengubah hasil Map SQLite menjadi bentuk List Objek CartModel
    return result.map((json) => CartModel.fromMap(json)).toList();
  }

  // 8. Fungsi Tambah Produk ke Keranjang (Add to Cart)
  Future<void> addToCart(ProductModel product) async {
    final db = await instance.database;

    // Cek terlebih dahulu apakah produk ini sudah ada di dalam keranjang belanja atau belum
    final existingItem = await db.query(
      'local_cart',
      where: 'product_id = ?',
      whereArgs: [product.id],
    );

    if (existingItem.isNotEmpty) {
      // Jika produk SUDAH ADA: Tambahkan kuantitas/jumlahnya (+1)
      int currentQty = existingItem.first['quantity'] as int;
      int cartId = existingItem.first['id'] as int;

      await db.update(
        'local_cart',
        {'quantity': currentQty + 1},
        where: 'id = ?',
        whereArgs: [cartId],
      );
    } else {
      // Jika produk BELUM ADA: Masukkan baris data baru ke tabel keranjang
      await db.insert('local_cart', {
        'product_id': product.id,
        'name': product.name,
        'price': product.price,
        'quantity': 1,
        'image_url': product.imageUrl,
      });
    }
  }

  // 9. Fungsi Update Kuantitas Barang di Keranjang (Tambah / Kurang)
  Future<void> updateQuantity(int cartId, int newQuantity) async {
    final db = await instance.database;

    // Jika jumlah diubah menjadi 0 (atau minus), otomatis hapus item dari keranjang
    if (newQuantity <= 0) {
      await deleteCartItem(cartId);
    } else {
      // Jika jumlah lebih dari 0, perbarui nilai kolom quantity
      await db.update(
        'local_cart',
        {'quantity': newQuantity},
        where: 'id = ?',
        whereArgs: [cartId],
      );
    }
  }

  // 10. Fungsi Hapus Single Item dari Keranjang
  Future<void> deleteCartItem(int cartId) async {
    final db = await instance.database;
    // Hapus baris data berdasarkan id keranjang
    await db.delete(
      'local_cart',
      where: 'id = ?',
      whereArgs: [cartId],
    );
  }

  // 11. Fungsi Kosongkan Seluruh Isi Keranjang (Misal setelah Checkout)
  Future<void> clearCart() async {
    final db = await instance.database;
    // Hapus seluruh baris data pada tabel local_cart
    await db.delete('local_cart');
  }
}