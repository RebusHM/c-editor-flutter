import 'package:c_editor/data/pvz_models/PvzModel.dart';

import 'package:c_editor/data/pvz_models/SchoolBusZombieData.dart';

class SchoolBusParamsData extends PvzModel {
  SchoolBusParamsData({
    this.schoolBusHitPoints = 4000,
    this.schoolBusSpeed = 0.2,
    this.zombies = const [],
  });

  int schoolBusHitPoints;
  double schoolBusSpeed;
  List<SchoolBusZombieData> zombies;

  factory SchoolBusParamsData.fromJson(Map<String, dynamic> json) {
    final raw = json['Zombies'] as List<dynamic>? ?? [];
    return SchoolBusParamsData(
      schoolBusHitPoints: json['SchoolBusHitPoints'] as int? ?? 4000,
      schoolBusSpeed: (json['SchoolBusSpeed'] as num?)?.toDouble() ?? 0.2,
      zombies: raw
          .map((e) => SchoolBusZombieData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SchoolBusHitPoints': schoolBusHitPoints,
      'SchoolBusSpeed': schoolBusSpeed,
      'Zombies': zombies.map((e) => e.toJson()).toList(),
    };
  }
}
