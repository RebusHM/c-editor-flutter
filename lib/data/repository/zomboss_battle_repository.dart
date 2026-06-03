import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:c_editor/data/asset_loader.dart';

class ZombossBattleInfo {
  const ZombossBattleInfo({
    required this.id,
    required this.icon,
    required this.variations,
    required this.resourceGroups,
  });

  final String id;
  final String icon;
  final List<String> variations;
  final List<String> resourceGroups;
}

class ZombossBattleRepository {
  static const String _resourcePath = 'assets/resources/Zombosses.json';
  static final List<ZombossBattleInfo> allZombosses = [];
  static bool _isLoaded = false;

  static Future<void> init() async {
    if (_isLoaded) return;
    try {
      final jsonString = await loadJsonString(_resourcePath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      allZombosses
        ..clear()
        ..addAll(
          jsonList.map((raw) {
            final item = raw as Map<String, dynamic>;
            return ZombossBattleInfo(
              id: item['id'] as String,
              icon: item['icon'] as String,
              variations: (item['variations'] as List<dynamic>)
                  .map((e) => e.toString())
                  .toList(),
              resourceGroups: (item['resourceGroups'] as List<dynamic>)
                  .map((e) => e.toString())
                  .toList(),
            );
          }),
        );
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading zomboss battle data: $e');
    }
  }

  static ZombossBattleInfo? getBase(String baseId) {
    return allZombosses.where((e) => e.id == baseId).firstOrNull;
  }

  static ZombossBattleInfo? findBaseForVariation(String variation) {
    return allZombosses
        .where((b) => b.variations.contains(variation))
        .firstOrNull;
  }

  static String resolveBaseId(String? preferredBaseId, String variation) {
    if (preferredBaseId != null) {
      final base = getBase(preferredBaseId);
      if (base != null && base.variations.contains(variation)) {
        return preferredBaseId;
      }
    }
    return findBaseForVariation(variation)?.id ??
        allZombosses.firstOrNull?.id ??
        '';
  }
}
