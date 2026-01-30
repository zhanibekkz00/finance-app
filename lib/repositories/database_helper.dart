import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Initialize FFI for Windows/Linux (not web)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    try {
      _database = await _initDB('finance.db');
      return _database!;
    } catch (e) {
      // If database initialization fails (e.g., on web), throw error
      throw Exception('Failed to initialize database: $e');
    }
  }

  Future<Database> _initDB(String filePath) async {
    // sqflite doesn't work on web - skip database initialization
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite is not supported on web platform. '
        'Please use a mobile or desktop platform, or implement Hive storage for web.'
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        colorValue $integerType,
        iconCode $integerType,
        isDefault $boolType
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        type $textType,
        amount $doubleType,
        categoryId $textType,
        date $textType,
        note $textType,
        isRecurring $boolType,
        currency $textType,
        recurrenceInterval $textType,
        nextOccurrence TEXT,
        isPinned $boolType,
        FOREIGN KEY (categoryId) REFERENCES categories (id)
      )
    ''');

    // Seed initial categories
    await _seedCategories(db);
  }

  Future _seedCategories(Database db) async {
    final List<Map<String, dynamic>> defaults = [
      {
        'id': '1',
        'name': 'Food',
        'colorValue': 0xFFF44336,
        'iconCode': 0xe25a,
        'isDefault': 1
      },
      {
        'id': '2',
        'name': 'Transport',
        'colorValue': 0xFF2196F3,
        'iconCode': 0xe1d5,
        'isDefault': 1
      },
      {
        'id': '3',
        'name': 'Salary',
        'colorValue': 0xFF4CAF50,
        'iconCode': 0xe0af,
        'isDefault': 1
      },
    ];

    for (var category in defaults) {
      await db.insert('categories', category);
    }
  }

  // Categories CRUD
  Future<List<CategoryModel>> getAllCategories() async {
    final db = await instance.database;
    final result = await db.query('categories');
    return result.map((json) => CategoryModel.fromMap(json)).toList();
  }

  // Transactions CRUD
  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => TransactionModel.fromMap(json)).toList();
  }

  Future<int> insertTransaction(TransactionModel tx) async {
    final db = await instance.database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<int> updateTransaction(TransactionModel tx) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
