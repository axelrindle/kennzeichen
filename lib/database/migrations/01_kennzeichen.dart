import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:kennzeichen/database/migration.dart';
import 'package:sqflite/sqflite.dart';

class Migration01GermanList extends Migration {

  @override
  Future<void> up(Transaction txn) async {
    final json = await rootBundle.loadString("assets/raw/raw.json");
    final data = jsonDecode(json) as List<dynamic>;

    await txn.execute("""
    CREATE TABLE "Kennzeichen" (
      "id"	INTEGER,
      "Kuerzel"	   TEXT NOT NULL,
      "Ort"	       TEXT DEFAULT NULL,
      "Bundesland" TEXT DEFAULT NULL,
      "Speziell"   TEXT DEFAULT NULL,
      
      PRIMARY KEY("id" AUTOINCREMENT)
    )
    """);

    await txn.execute("""
    CREATE INDEX "kennzeichen_bundesland" ON "Kennzeichen" (
      "Bundesland"  ASC
    )
    """);

    await txn.execute("""
    CREATE UNIQUE INDEX "kennzeichen_kuerzel" ON "Kennzeichen" (
      "Kuerzel"	ASC
    );
    """);

    for (var value in data) {
      await txn.insert("Kennzeichen", value);
    }
  }

  @override
  Future<void> down(Transaction txn) async {
    await txn.execute("""
    DROP TABLE kennzeichen
    """);
  }

}