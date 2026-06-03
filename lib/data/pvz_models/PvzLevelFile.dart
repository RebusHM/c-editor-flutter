import 'package:c_editor/data/pvz_models/PvzObject.dart';

class PvzLevelFile {
  PvzLevelFile({required this.objects, this.version = 1});

  List<PvzObject> objects;
  int version;

  factory PvzLevelFile.fromJson(Map<String, dynamic> json) {
    final list = json['objects'] as List<dynamic>? ?? [];
    return PvzLevelFile(
      objects: list
          .map((e) => PvzObject.fromJson(e as Map<String, dynamic>))
          .toList(),
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'objects': objects.map((e) => e.toJson()).toList(),
    'version': version,
  };
}
