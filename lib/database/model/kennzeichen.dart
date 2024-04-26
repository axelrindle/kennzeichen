import 'package:kennzeichen/database/model.dart';

class Kennzeichen extends Model<Kennzeichen> {
  String? Kuerzel;
  String? Ort;
  String? Bundesland;
  String? Speziell;

  Kennzeichen({
    this.Kuerzel,
    this.Ort,
    this.Bundesland,
    this.Speziell,
  });
  Kennzeichen.fromMap(super.map) : super.fromMap();

  @override
  Map<String, Object?> toMap() {
    return {
      "id": id,
      "Kuerzel": Kuerzel,
      "Ort": Ort,
      "Bundesland": Bundesland,
      "Speziell": Speziell,
    };
  }

  @override
  void fromMap(Map<String, Object?> map) {
    Kuerzel = map["Kuerzel"] as String;
    Ort = map["Ort"] as String?;
    Bundesland = map["Bundesland"] as String?;
    Speziell = map["Speziell"] as String?;
  }

}