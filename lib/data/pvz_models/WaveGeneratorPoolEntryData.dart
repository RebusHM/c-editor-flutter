import 'package:c_editor/data/pvz_models/PvzModel.dart';

/// Entry in global or per-wave [AddToZombiePool].
class WaveGeneratorPoolEntryData extends PvzModel {
  WaveGeneratorPoolEntryData({this.type = ''});

  String type;

  factory WaveGeneratorPoolEntryData.fromJson(Map<String, dynamic> json) {
    return WaveGeneratorPoolEntryData(type: json['Type'] as String? ?? '');
  }

  @override
  Map<String, dynamic> toJson() => {'Type': type};
}
