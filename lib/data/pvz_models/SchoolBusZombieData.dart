import 'package:c_editor/data/pvz_models/PvzModel.dart';

class SchoolBusZombieData extends PvzModel {
  SchoolBusZombieData({this.typeName = '', this.level = 0});

  String typeName;
  int level;

  factory SchoolBusZombieData.fromJson(Map<String, dynamic> json) {
    return SchoolBusZombieData(
      typeName: json['TypeName'] as String? ?? '',
      level: json['Level'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'TypeName': typeName, 'Level': level};
}
