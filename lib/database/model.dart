import 'package:kennzeichen/database/index.dart';
import 'package:sqflite/sqflite.dart' as db;

abstract class Model<T extends Model<T>> {

  int? id;

  Model({this.id});
  Model.fromMap(Map<String, Object?> map) {
    id = map["id"] as int?;
    fromMap(map);
  }

  /// Serializes this model to a Map for persistence.
  Map<String, Object?> toMap();
  void fromMap(Map<String, Object?> map);

  String getTableName() {
    return "$T";
  }

  @override
  String toString() {
    return '$T${toMap()}';
  }

  Future<T> save(T Function(Map<String, Object?> map) constructor) async {
    var database = Database.get();
    if (id == null) {
      final id = await database.insert(getTableName(), toMap());
      final maps = await database.query(getTableName(), where: "id = $id", limit: 1);
      if (maps.length != 1) {
        throw Exception("saving failed!");
      }

      return Future.value(constructor(maps[0]));
    } else {
      final data = toMap();
      data.remove("id");
      await Database.get().update(getTableName(), data, where: "id = $id");
      final maps = await database.query(getTableName(), where: "id = $id", limit: 1);
      if (maps.length != 1) {
        throw Exception("saving failed!");
      }

      return Future.value(constructor(maps[0]));
    }
  }

  static Future<int> count<T extends Model<T>>(T example) async {
    final result = await Database.get().rawQuery("SELECT COUNT(*) AS count FROM ${example.getTableName()}");
    return result.first["count"] as int;
  }

  static Future<List<T>> find<T extends Model<T>>(
      T example,
      T Function(Map<String, Object?> map) constructor,
      {
        bool? distinct,
        List<String>? columns,
        String? where,
        List<Object?>? whereArgs,
        String? groupBy,
        String? having,
        String? orderBy,
        int? limit,
        int? offset,
      }
  ) async {
    final result = await Database.get().query(
      example.getTableName(),
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
    );

    return result.map((e) => constructor(e)).toList();
  }

  static Future<void> insert<T extends Model<T>>(T model) async {
    await Database.get().insert(
      model.getTableName(),
      model.toMap(),
      conflictAlgorithm: db.ConflictAlgorithm.replace,
    );
  }
}