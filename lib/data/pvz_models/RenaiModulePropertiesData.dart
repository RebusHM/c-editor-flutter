import 'package:c_editor/data/pvz_models/PvzModel.dart';

import 'package:c_editor/data/pvz_models/RenaiStatueInfoData.dart';

class RenaiModulePropertiesData extends PvzModel {
  RenaiModulePropertiesData({
    this.nightEnabled = false,
    this.nightStartWaveNum = 0,
    List<RenaiStatueInfoData>? statueInfos,
    List<RenaiStatueInfoData>? statueNightInfos,
  }) : statueInfos = statueInfos ?? [],
       statueNightInfos = statueNightInfos ?? [];

  /// When false, night wave and night statues are not serialized.
  /// Invalid state: statueNightInfos non-empty but nightEnabled false (UI prevents this).
  bool nightEnabled;
  int nightStartWaveNum;
  List<RenaiStatueInfoData> statueInfos;
  List<RenaiStatueInfoData> statueNightInfos;

  factory RenaiModulePropertiesData.fromJson(Map<String, dynamic> json) {
    final nightWave = (json['NightStartWaveNum'] as num?)?.toInt();
    final nightStatues = (json['StatueNightInfos'] as List<dynamic>?)
        ?.map((e) => RenaiStatueInfoData.fromJson(e as Map<String, dynamic>))
        .toList();
    final hasNightData =
        nightWave != null || (nightStatues?.isNotEmpty == true);
    return RenaiModulePropertiesData(
      nightEnabled: hasNightData,
      nightStartWaveNum: nightWave ?? 0,
      statueInfos:
          (json['StatueInfos'] as List<dynamic>?)
              ?.map(
                (e) => RenaiStatueInfoData.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      statueNightInfos: nightStatues ?? [],
    );
  }

  /// Returns empty map when config is default (no night, no statues),
  /// matching game format e.g. RENAI1.json.
  Map<String, dynamic> toJson() {
    if (!nightEnabled && statueInfos.isEmpty) return {};
    final result = <String, dynamic>{};
    if (statueInfos.isNotEmpty) {
      result['StatueInfos'] = statueInfos.map((e) => e.toJson()).toList();
    }
    if (nightEnabled) {
      result['NightStartWaveNum'] = nightStartWaveNum;
      result['StatueNightInfos'] = statueNightInfos
          .map((e) => e.toJson())
          .toList();
    }
    return result;
  }
}
