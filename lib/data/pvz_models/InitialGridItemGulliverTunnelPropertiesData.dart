import 'package:c_editor/data/pvz_models/GulliverTunnelPlacementData.dart';
import 'package:c_editor/data/pvz_models/PvzModel.dart';

class InitialGridItemGulliverTunnelPropertiesData extends PvzModel {
  InitialGridItemGulliverTunnelPropertiesData({
    List<GulliverTunnelPlacementData>? tunnelPlacements,
  }) : tunnelPlacements = tunnelPlacements ?? [];

  List<GulliverTunnelPlacementData> tunnelPlacements;

  factory InitialGridItemGulliverTunnelPropertiesData.fromJson(
    Map<String, dynamic> json,
  ) {
    return InitialGridItemGulliverTunnelPropertiesData(
      tunnelPlacements:
          (json['TunnelPlacements'] as List<dynamic>?)
              ?.map(
                (e) => GulliverTunnelPlacementData.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'TunnelPlacements': tunnelPlacements.map((e) => e.toJson()).toList(),
  };
}
