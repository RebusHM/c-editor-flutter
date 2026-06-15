import 'package:c_editor/data/pvz_models/PvzModel.dart';

/// Zombie spawn entry inside [WaveGeneratorWaveData].
/// Row is stored as a string in level JSON: "1"–"5", "?", or omitted for random.
class WaveGeneratorZombieEntryData extends PvzModel {
  WaveGeneratorZombieEntryData({this.type = '', this.row});

  String type;
  String? row;

  factory WaveGeneratorZombieEntryData.fromJson(Map<String, dynamic> json) {
    final rawRow = json['Row'];
    String? row;
    if (rawRow is String) {
      row = rawRow;
    } else if (rawRow is num) {
      row = rawRow.toString();
    }
    return WaveGeneratorZombieEntryData(
      type: json['Type'] as String? ?? '',
      row: row,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{'Type': type};
    if (row != null && row!.isNotEmpty) {
      data['Row'] = row;
    }
    return data;
  }
}
