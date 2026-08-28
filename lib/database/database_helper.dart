import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'dartd:io';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static sql.Database? _database;

  DatabaseHelper._init();

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hesabati.db');
    return _database!;
  }

  Future<sql.Database> _initDB(String filePath) async {
    final dbPath = await sql.getDatabasesPath();
    final fullPath = path.join(dbPath, filePath);

    return await sql.openDatabase(
      fullPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(sql.Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    return await db.insert('customers', customer);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return await db.query('customers', orderBy: 'name');
  }

  Future<Map<String, dynamic>?> getCustomer(int id) async {
    final db = await database;
    final result = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertTransaction(Map<String, dynamic> transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getCustomerTransactions(int customerId) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC',
    );
  }

  Future<double> getCustomerBalance(int customerId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'له' THEN amount ELSE 0 END), 0) as total_for_him,
        COALESCE(SUM(CASE WHEN type = 'عليه' THEN amount ELSE 0 END), 0) as total_on_him
      FROM transactions 
      WHERE customer_id = ?
    ''', [customerId]);

    if (result.isEmpty) return 0.0;
    final row = result.first;
    final forHim = (row['total_for_him'] as num?)?.toDouble() ?? 0.0;
    final onHim = (row['total_on_him'] as num?)?.toDouble() ?? 0.0;
    return forHim - onHim;
  }

  Future<Map<String, double>> getTotals() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'له' THEN amount ELSE 0 END), 0) as total_for_him,
        COALESCE(SUM(CASE WHEN type = 'عليه' THEN amount ELSE 0 END), 0) as total_on_him
      FROM transactions
    ''');

    if (result.isEmpty) {
      return {'له': 0.0, 'عليه': 0.0, 'الرصيد': 0.0};
    }

    final row = result.first;
    final forHim = (row['total_for_him'] as num?)?.toDouble() ?? 0.0;
    final onHim = (row['total_on_him'] as num?)?.toDouble() ?? 0.0;

    return {
      'له': forHim,
      'عليه': onHim,
      'الرصيد': forHim - onHim,
    };
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> backupDatabase() async {
    final db = await database;
    await db.close();
    _database = null;

    final dbPath = await sql.getDatabasesPath();
    final dbFile = File(path.join(dbPath, 'hesabati.db'));

    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(path.join(appDir.path, 'backups'));
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    final timestamp = DateTime.now().toString().replaceAll(':', '-').split('.').first;
    final backupFile = File(path.join(backupDir.path, 'hesabati_backup_$timestamp.db'));

    await dbFile.copy(backupFile.path);
    _database = await _initDB('hesabati.db');

    return backupFile.path;
  }

  Future<String> exportBackup() async {
    final db = await database;
    await db.close();
    _database = null;

    final dbPath = await sql.getDatabasesPath();
    final dbFile = File(path.join(dbPath, 'hesabati.db'));

    final appDir = await getTemporaryDirectory();
    final backupFile = File(path.join(appDir.path, 'hesabati_backup.db'));

    await dbFile.copy(backupFile.path);

    await Share.shareXFiles(
      [XFile(backupFile.path)],
      text: 'نسخة احتياطية - تطبيق حساباتي',
    );

    _database = await _initDB('hesabati.db');

    return backupFile.path;
  }

  Future<void> restoreDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null || result.files.single.path == null) return;

    final db = await database;
    await db.close();
    _database = null;

    final dbPath = await sql.getDatabasesPath();
    final dbFile = File(path.join(dbPath, 'hesabati.db'));

    final pickedFile = File(result.files.single.path!);
    await pickedFile.copy(dbFile.path);

    _database = await _initDB('hesabati.db');
  }
}
