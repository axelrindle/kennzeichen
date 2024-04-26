import 'dart:ffi';

import 'package:kennzeichen/database/index.dart';
import 'package:kennzeichen/database/model.dart';
import 'package:kennzeichen/database/model/kennzeichen.dart';

class Gefunden extends Model<Gefunden> {
  int? KennzeichenId;
  int? Timestamp;
  int? Count;

  Gefunden({
    this.KennzeichenId,
    this.Timestamp,
    this.Count,
  });
  Gefunden.fromMap(super.map) : super.fromMap();

  @override
  Map<String, Object?> toMap() {
    return {
      "id": id,
      "kennzeichen_id": KennzeichenId,
      "timestamp": Timestamp,
      "count": Count,
    };
  }

  @override
  void fromMap(Map<String, Object?> map) {
    KennzeichenId = map["kennzeichen_id"] as int?;
    Timestamp = map["timestamp"] as int?;
    Count = map["count"] as int?;
  }

  Future<Kennzeichen?> kennzeichen() async {
    final result = await Model.find(Kennzeichen(), Kennzeichen.fromMap,
      where: "id = ?",
      whereArgs: [KennzeichenId]);

    if (result.length != 1) {
      return null;
    }

    return result.first;
  }

}