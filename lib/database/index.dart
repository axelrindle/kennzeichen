import 'package:kennzeichen/database/migration.dart';
import 'package:kennzeichen/database/migrations/01_kennzeichen.dart';
import 'package:kennzeichen/database/migrations/02_gefunden.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as db;

class Database {

  static const String _tableName = "migrations";

  static Database? _instance;
  static Database work() => _instance!;
  static db.Database get() => _instance!._handle!;

  static Future<void> init() async {
    if (_instance != null) {
      throw Exception("database has already been initialized!");
    }

    _instance = Database();
    await _instance?._init();
  }


  final List<Migration> migrations = [
    Migration01GermanList(),
    Migration02Gefunden(),
  ];

  db.Database? _handle;

  Future<String> getPath() async {
    return join(await db.getDatabasesPath(), "data.db");
  }

  Future<void> reset() async {
    await _handle?.close();
    await db.deleteDatabase(await getPath());
  }

  Future<void> _init() async {
    final platform = await PackageInfo.fromPlatform();

    _handle = await db.openDatabase(
      await getPath(),
      version: int.parse(platform.buildNumber),
      onCreate: (db, version) async {
        // create migration table
        await db.execute("""
        CREATE TABLE "$_tableName" (
          "id" INTEGER NOT NULL,
          "name" TEXT NOT NULL UNIQUE,
          "timestamp"	INTEGER NOT NULL,
          "success"	INTEGER NOT NULL CHECK(success in (0,1)),
          
          PRIMARY KEY("id" AUTOINCREMENT)
        );
        """);

        await _migrate(db, 0, version);
      },
      onUpgrade: (db, oldVersion, newVersion) async => await _migrate(db, oldVersion, newVersion),
    );
  }

  Future<void> _migrate(db.Database db, int oldVersion, int newVersion) async {
    print("Database is at version $oldVersion");
    print("Migrating database to version $newVersion …");

    final ran = await db.query(_tableName, orderBy: "timestamp");
    final toRun = migrations.where((todo) => ran.indexWhere((done) => done["name"] == "$todo") == -1);

    print("Running ${toRun.length} migrations …");

    for (var migration in toRun) {
      final name = "$migration";

      final id = await db.insert(_tableName, {
        "name": name,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
        "success": 0,
      });

      print("Migrating $name …");

      try {
        await db.transaction((txn) async {
          await migration.up(txn);

          await txn.update(_tableName, {
            "success": 1,
          },
            where: "id = $id"
          );
        }, exclusive: true);
      } on Exception {
        await db.transaction((txn) async {
          await migration.down(txn);
          await db.delete("migrations", where: "id = ?", whereArgs: [id]);
        }, exclusive: true);
        rethrow;
      }
    }

    await db.execute("PRAGMA user_version = $newVersion");

    print("Success. Database is at version $newVersion");
  }

}