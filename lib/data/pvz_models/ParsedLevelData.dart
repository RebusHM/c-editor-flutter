import 'package:c_editor/data/pvz_models/LevelDefinitionData.dart';
import 'package:c_editor/data/pvz_models/PvzObject.dart';

class ParsedLevelData {
  ParsedLevelData({
    this.levelDef,
    this.waveManager,
    this.waveModule,
    this.waveGenerator,
    required this.objectMap,
  });

  LevelDefinitionData? levelDef;
  dynamic waveManager;
  dynamic waveModule;
  dynamic waveGenerator;
  Map<String, PvzObject> objectMap;
}
