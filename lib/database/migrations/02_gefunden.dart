import 'package:kennzeichen/database/migration.dart';
import 'package:sqflite/sqflite.dart';

class Migration02Gefunden extends Migration {

  @override
  Future<void> up(Transaction txn) async {
    await txn.execute("""
    CREATE TABLE "Gefunden" (
      "id"	INTEGER,
      "kennzeichen_id"	INTEGER NOT NULL UNIQUE,
      "timestamp"	NUMERIC NOT NULL,
      "count" INTEGER NOT NULL DEFAULT 0 CHECK(count >= 0),
      PRIMARY KEY("id" AUTOINCREMENT),
      FOREIGN KEY("kennzeichen_id") REFERENCES "kennzeichen"("id")
    )
    """);
  }

  @override
  Future<void> down(Transaction txn) async {
    await txn.execute("""
    DROP TABLE Gefunden
    """);
  }

}