import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/recording.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'recordings.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE recordings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            orderNumber TEXT NOT NULL,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            videoPath TEXT NOT NULL,
            photoPath TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertRecording(Recording recording) async {
    final db = await database;
    return db.insert('recordings', recording.toMap());
  }

  Future<List<Recording>> getAllRecordings() async {
    final db = await database;
    final maps = await db.query('recordings', orderBy: 'id DESC');
    return maps.map((map) => Recording.fromMap(map)).toList();
  }

  Future<int> deleteRecording(int id) async {
    final db = await database;
    return db.delete('recordings', where: 'id = ?', whereArgs: [id]);
  }
}
