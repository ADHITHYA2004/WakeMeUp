import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/destination.dart';

/// Service to manage SQLite database for storing destinations
/// Uses SQLite on mobile, SharedPreferences on web
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  static const String _prefsKey = 'wakemeup_destinations';

  DatabaseService._init();

  /// Check if running on web
  bool get isWeb => kIsWeb;

  /// Get database instance, creating if necessary (mobile only)
  Future<Database?> get database async {
    if (isWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database and create tables (mobile only)
  Future<Database> _initDatabase() async {
    if (isWeb) throw UnsupportedError('SQLite not supported on web');
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'wakemeup.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  /// Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE destinations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  /// Initialize database (public method)
  Future<void> initDatabase() async {
    if (!isWeb) {
      await database;
    }
    // Web uses SharedPreferences, no initialization needed
  }

  /// Insert a new destination
  Future<int> insertDestination(Destination destination) async {
    if (isWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      final destinations = await getAllDestinations();
      final newId = destinations.isEmpty 
          ? 1 
          : destinations.map((d) => d.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      final newDest = destination.copyWith(id: newId);
      destinations.add(newDest);
      await _saveDestinationsToPrefs(destinations);
      return newId;
    } else {
      final db = await database;
      return await db!.insert('destinations', destination.toMap());
    }
  }

  /// Get all destinations, ordered by creation date (newest first)
  Future<List<Destination>> getAllDestinations() async {
    if (isWeb) {
      return await _getDestinationsFromPrefs();
    } else {
      final db = await database;
      final maps = await db!.query(
        'destinations',
        orderBy: 'created_at DESC',
      );
      return maps.map((map) => Destination.fromMap(map)).toList();
    }
  }

  /// Get a destination by ID
  Future<Destination?> getDestination(int id) async {
    if (isWeb) {
      final destinations = await _getDestinationsFromPrefs();
      try {
        return destinations.firstWhere((d) => d.id == id);
      } catch (e) {
        return null;
      }
    } else {
      final db = await database;
      final maps = await db!.query(
        'destinations',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return Destination.fromMap(maps.first);
    }
  }

  /// Delete a destination by ID
  Future<int> deleteDestination(int id) async {
    if (isWeb) {
      final destinations = await _getDestinationsFromPrefs();
      destinations.removeWhere((d) => d.id == id);
      await _saveDestinationsToPrefs(destinations);
      return 1;
    } else {
      final db = await database;
      return await db!.delete(
        'destinations',
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  /// Clear all destinations
  Future<int> clearAllDestinations() async {
    if (isWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      return 1;
    } else {
      final db = await database;
      return await db!.delete('destinations');
    }
  }

  /// Save destinations to SharedPreferences (web only)
  Future<void> _saveDestinationsToPrefs(List<Destination> destinations) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = destinations.map((d) => jsonEncode(d.toMap())).toList();
    await prefs.setStringList(_prefsKey, jsonList);
  }

  /// Get destinations from SharedPreferences (web only)
  Future<List<Destination>> _getDestinationsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_prefsKey) ?? [];
    return jsonList
        .map((json) => Destination.fromMap(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by date descending
  }
}

