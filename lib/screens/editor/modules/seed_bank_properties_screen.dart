import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:c_editor/data/repository/grid_item_repository.dart';
import 'package:c_editor/data/repository/plant_repository.dart';
import 'package:c_editor/data/pvz_models.dart';
import 'package:c_editor/data/rtid_parser.dart';
import 'package:c_editor/data/repository/zombie_properties_repository.dart';
import 'package:c_editor/data/repository/zombie_repository.dart';
import 'package:c_editor/l10n/app_localizations.dart';
import 'package:c_editor/l10n/resource_names.dart';
import 'package:c_editor/theme/app_theme.dart';
import 'package:c_editor/widgets/asset_image.dart' show AssetImageWidget, imageAltCandidates;

/// Seed bank properties. Ported from Z-Editor-master SeedBankPropertiesEP.kt
class SeedBankPropertiesScreen extends StatefulWidget {
  const SeedBankPropertiesScreen({
    super.key,
    required this.rtid,
    required this.levelFile,
    required this.onChanged,
    required this.onBack,
    required this.onRequestPlantSelection,
    required this.onRequestZombieSelection,
  });

  final String rtid;
  final PvzLevelFile levelFile;
  final VoidCallback onChanged;
  final VoidCallback onBack;
  final void Function(
    void Function(List<String>) onSelected, {
    List<String>? excludeIds,
    bool blockRealmExclusiveInChooser,
    bool allowDuplicateSelection,
  }) onRequestPlantSelection;
  final void Function(void Function(List<String>) onSelected)
      onRequestZombieSelection;

  @override
  State<SeedBankPropertiesScreen> createState() =>
      _SeedBankPropertiesScreenState();
}

class _SeedBankPropertiesScreenState extends State<SeedBankPropertiesScreen> {
  late PvzObject _moduleObj;
  late SeedBankData _data;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final info = RtidParser.parse(widget.rtid);
    final alias = info?.alias ?? '';
    final existing = widget.levelFile.objects.firstWhereOrNull(
      (o) => o.aliases?.contains(alias) == true,
    );
    if (existing != null) {
      _moduleObj = existing;
    } else {
      _moduleObj = PvzObject(
        aliases: [alias],
        objClass: 'SeedBankProperties',
        objData: SeedBankData().toJson(),
      );
      widget.levelFile.objects.add(_moduleObj);
    }
    try {
      _data = SeedBankData.fromJson(
        Map<String, dynamic>.from(_moduleObj.objData as Map),
      );
    } catch (_) {
      _data = SeedBankData();
    }
    _data = SeedBankData(
      presetPlantList: List.from(_data.presetPlantList),
      plantWhiteList: List.from(_data.plantWhiteList),
      plantBlackList: List.from(_data.plantBlackList),
      selectionMethod: _data.selectionMethod,
      globalLevel: _data.globalLevel,
      overrideSeedSlotsCount: _data.overrideSeedSlotsCount,
      zombieMode: _data.zombieMode,
      seedPacketType: _data.seedPacketType,
      gridItemMode: _data.gridItemMode,
    );
    _syncGridItemModeFromPreset();
  }

  /// Legacy levels may have grid items in preset without GridItemMode flag.
  void _syncGridItemModeFromPreset() {
    if (_data.gridItemMode == true) return;
    if (_data.presetPlantList.any(kSeedBankGridItemIds.contains)) {
      _data.gridItemMode = true;
    }
  }

  /// Indices in [SeedBankData.presetPlantList] for chips (excludes grid items).
  List<int> get _presetPlantDisplayIndices {
    final indices = <int>[];
    for (var i = 0; i < _data.presetPlantList.length; i++) {
      if (!kSeedBankGridItemIds.contains(_data.presetPlantList[i])) {
        indices.add(i);
      }
    }
    return indices;
  }

  List<String> get _presetPlantsExcludingGridItems => [
        for (final i in _presetPlantDisplayIndices) _data.presetPlantList[i],
      ];

  bool _isGridItemSelected(String id) => _data.presetPlantList.contains(id);

  void _removeGridItemsFromPreset() {
    _data.presetPlantList
        .removeWhere((id) => kSeedBankGridItemIds.contains(id));
  }

  void _setGridItemSelected(String id, bool selected) {
    if (selected) {
      if (!_data.presetPlantList.contains(id)) {
        _data.presetPlantList.add(id);
      }
    } else {
      _data.presetPlantList.remove(id);
    }
  }

  void _sync() {
    _moduleObj.objData = _data.toJson();
    widget.onChanged();
    setState(() {});
  }

  void _addToPresetPlants() {
    // Preset: allow duplicates and blacklisted plants
    widget.onRequestPlantSelection(
      (ids) {
        setState(() {
          _data.presetPlantList.addAll(ids);
          _sync();
        });
      },
      blockRealmExclusiveInChooser: false,
      allowDuplicateSelection: true,
    );
  }

  void _addToWhiteList() {
    final exclude = [
      ..._data.plantWhiteList,
      ..._data.plantBlackList,
    ];
    widget.onRequestPlantSelection(
      (ids) {
        setState(() {
          final toAdd = ids.where((id) => !_data.plantWhiteList.contains(id));
          _data.plantWhiteList.addAll(toAdd);
          _sync();
        });
      },
      excludeIds: exclude,
      blockRealmExclusiveInChooser: _data.selectionMethod == 'chooser',
    );
  }

  void _addToBlackList() {
    final exclude = [
      ..._data.plantWhiteList,
      ..._data.plantBlackList,
    ];
    widget.onRequestPlantSelection(
      (ids) {
        setState(() {
          final toAdd = ids.where((id) => !_data.plantBlackList.contains(id));
          _data.plantBlackList.addAll(toAdd);
          _sync();
        });
      },
      excludeIds: exclude,
      blockRealmExclusiveInChooser: _data.selectionMethod == 'chooser',
    );
  }

  void _addToZombies() {
    widget.onRequestZombieSelection((ids) {
      setState(() {
        for (final id in ids) {
          _data.presetPlantList
              .add(ZombieRepository().buildZombieAliases(id));
        }
        _sync();
      });
    });
  }

  void _clearSeedBankLists() {
    _data.presetPlantList.clear();
    _data.plantWhiteList.clear();
    _data.plantBlackList.clear();
    _data.gridItemMode = false;
  }

  void _removePresetPlantAt(int index) {
    setState(() {
      _data.presetPlantList.removeAt(_presetPlantDisplayIndices[index]);
      _sync();
    });
  }

  void _removeFromList(List<String> list, int index) {
    setState(() {
      list.removeAt(index);
      _sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isZombieMode = _data.zombieMode == true;
    final isReversedZombie =
        _data.seedPacketType == 'UIIZombieSeedPacket';

    final izombieColor = theme.brightness == Brightness.dark
        ? pvzPurpleDark
        : pvzPurpleLight;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text(isZombieMode ? (l10n?.seedBankIZombie ?? 'Seed bank (I, Zombie)') : (l10n?.moduleTitle_SeedBankProperties ?? 'Seed bank')),
        backgroundColor: isZombieMode ? izombieColor : null,
        foregroundColor: isZombieMode ? theme.colorScheme.surface : null,
        iconTheme: isZombieMode
            ? IconThemeData(color: theme.colorScheme.surface)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context, isZombieMode),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBasicRulesCard(context, isZombieMode, l10n),
              const SizedBox(height: 16),
              if (isZombieMode)
                _ResourceListEditor(
                  title: l10n?.availableZombies ?? 'Available zombies',
                  description: l10n?.availableZombiesDescription ?? 'Zombies available for I, Zombie mode',
                  items: _data.presetPlantList,
                  accentColor: izombieColor,
                  isZombie: true,
                  onAdd: _addToZombies,
                  onRemove: (i) => _removeFromList(_data.presetPlantList, i),
                )
              else ...[
                _ResourceListEditor(
                  title: l10n?.presetPlants ?? 'Preset plants (PresetPlantList)',
                  description: l10n?.plantsAvailableAtStart ?? 'Plants available at start',
                  items: _presetPlantsExcludingGridItems,
                  accentColor: theme.colorScheme.secondary,
                  isZombie: false,
                  onAdd: _addToPresetPlants,
                  onRemove: _removePresetPlantAt,
                ),
                const SizedBox(height: 16),
                _ResourceListEditor(
                  title: l10n?.whiteList ?? 'White list (WhiteList)',
                  description: l10n?.whiteListDescription ?? 'Only these plants allowed (empty = no limit)',
                  items: _data.plantWhiteList,
                  accentColor: theme.colorScheme.primary,
                  isZombie: false,
                  onAdd: _addToWhiteList,
                  onRemove: (i) => _removeFromList(_data.plantWhiteList, i),
                ),
                const SizedBox(height: 16),
                _ResourceListEditor(
                  title: l10n?.blackList ?? 'Black list (BlackList)',
                  description: l10n?.blackListDescription ?? 'These plants are forbidden',
                  items: _data.plantBlackList,
                  accentColor: theme.colorScheme.error,
                  isZombie: false,
                  onAdd: _addToBlackList,
                  onRemove: (i) => _removeFromList(_data.plantBlackList, i),
                ),
                const SizedBox(height: 16),
                _buildGridItemsCard(context, l10n),
              ],
              if (isZombieMode)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: izombieColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n?.izombieCardSlotsHint ?? 'Only some zombies have IZ card slots. Check Other category in zombie selection.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _buildZombieModeSwitch(context, isZombieMode, izombieColor),
              const SizedBox(height: 16),
              if (isZombieMode)
                _buildReversedZombieSwitch(
                    context, isReversedZombie, izombieColor),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicRulesCard(BuildContext context, bool isZombieMode, AppLocalizations? l10n) {
    final theme = Theme.of(context);
    final izombieColor = theme.brightness == Brightness.dark
        ? pvzPurpleDark
        : pvzPurpleLight;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.yard,
                  color: isZombieMode
                      ? izombieColor
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n?.basicRules ?? 'Basic rules',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              l10n?.selectionMethod ?? 'Selection method',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: Text(AppLocalizations.of(context)?.chooser ?? 'Chooser'),
                  selected:
                      _data.selectionMethod == 'chooser' && !isZombieMode,
                  onSelected: isZombieMode
                      ? null
                      : (v) {
                          setState(() {
                            _data.selectionMethod = 'chooser';
                            _sync();
                          });
                        },
                ),
                FilterChip(
                  label: Text(AppLocalizations.of(context)?.preset ?? 'Preset'),
                  selected:
                      _data.selectionMethod == 'preset' || isZombieMode,
                  onSelected: isZombieMode
                      ? null
                      : (v) {
                          setState(() {
                            _data.selectionMethod = 'preset';
                            _sync();
                          });
                        },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.seedBankPresetModeHint ??
                  'Preset mode enters game immediately regardless of card count.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Opacity(
              opacity: isZombieMode ? 0.5 : 1,
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '${_data.globalLevel ?? 0}',
                      decoration: InputDecoration(
                        labelText: l10n?.seedBankPlantLevelLabel ??
                            'Plant level (0-5)',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (s) {
                        final v = int.tryParse(s) ?? 0;
                        final clamped = v.clamp(0, 5);
                        _data.globalLevel =
                            clamped == 0 ? null : clamped;
                        _sync();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: '${_data.overrideSeedSlotsCount ?? 0}',
                      decoration: InputDecoration(
                        labelText: l10n?.seedBankSlotCountLabel ??
                            'Slot count (0-9)',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (s) {
                        final v = int.tryParse(s) ?? 0;
                        _data.overrideSeedSlotsCount = v.clamp(0, 9);
                        _sync();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n?.seedBankCourtyardSlotsHint ??
                  'Courtyard mode ignores slot count. Chooser locks 8 slots.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItemsCard(BuildContext context, AppLocalizations? l10n) {
    final gridMode = _data.gridItemMode == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: SwitchListTile(
            title: Text(
              l10n?.seedBankAddGridItemsTitle ?? 'Add grid items',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              l10n?.seedBankAddGridItemsSubtitle ??
                  'Adds frozen mini-game grid items to the preset seed bank.',
            ),
            value: gridMode,
            onChanged: (enabled) {
              setState(() {
                _data.gridItemMode = enabled;
                if (!enabled) {
                  _removeGridItemsFromPreset();
                }
                _sync();
              });
            },
          ),
        ),
        if (gridMode) ...[
          const SizedBox(height: 16),
          Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < kSeedBankGridItemIds.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                  _SeedBankGridItemRow(
                    typeName: kSeedBankGridItemIds[i],
                    selected: _isGridItemSelected(kSeedBankGridItemIds[i]),
                    onChanged: (selected) {
                      setState(() {
                        _setGridItemSelected(kSeedBankGridItemIds[i], selected);
                        _sync();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildZombieModeSwitch(
      BuildContext context, bool isZombieMode, Color izombieColor) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(
          switchTheme: SwitchThemeData(
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return izombieColor;
              return null;
            }),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.surface;
              }
              return null;
            }),
          ),
        ),
        child: SwitchListTile(
          title: Text(
            AppLocalizations.of(context)?.izombieModeTitle ?? 'I, Zombie mode',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            AppLocalizations.of(context)?.izombieModeSubtitle ?? 'Enable to place zombies. Locks selection method.',
          ),
          value: isZombieMode,
          onChanged: (v) {
          setState(() {
            if (_data.zombieMode != v) {
              _clearSeedBankLists();
            }
            _data.zombieMode = v;
            if (v) {
              _data.selectionMethod = 'preset';
              _data.seedPacketType = null;
            } else {
              _data.seedPacketType = null;
            }
            _sync();
          });
        },
        ),
      ),
    );
  }

  Widget _buildReversedZombieSwitch(
      BuildContext context, bool isReversedZombie, Color izombieColor) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(
          switchTheme: SwitchThemeData(
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return izombieColor;
              return null;
            }),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.surface;
              }
              return null;
            }),
          ),
        ),
        child: SwitchListTile(
        title: Text(
          AppLocalizations.of(context)?.reverseZombieFactionTitle ?? 'Reverse zombie faction',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          AppLocalizations.of(context)?.reverseZombieFactionSubtitle ?? 'Enable to make zombies plant faction. For ZvZ.',
        ),
        value: isReversedZombie,
        onChanged: (v) {
          setState(() {
            _data.seedPacketType =
                v ? 'UIIZombieSeedPacket' : null;
            _sync();
          });
        },
        ),
      ),
    );
  }

  void _showHelp(BuildContext context, bool isZombieMode) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.seedBankHelp ?? 'Seed bank help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n?.seedBankLetsPlayersChoose ?? 'Seed bank lets players choose plants. In courtyard mode you can set global level and all plants.'),
              const SizedBox(height: 8),
              Text(l10n?.whiteListBlackListHint ?? 'White list: empty = no limit. Black list overrides white list.'),
              const SizedBox(height: 8),
              Text(l10n?.iZombieModePresetHint ?? 'I, Zombie mode: preset zombies for player. Selection locked to preset.'),
              const SizedBox(height: 8),
              Text(l10n?.invalidIdsHint ?? 'Invalid IDs leave empty slots. Zombie IDs in plant mode and vice versa. Put zombie slots first.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.ok ?? 'OK'),
          ),
        ],
      ),
    );
  }
}

class _SeedBankGridItemRow extends StatelessWidget {
  const _SeedBankGridItemRow({
    required this.typeName,
    required this.selected,
    required this.onChanged,
  });

  final String typeName;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const iconBoxSize = 56.0;
    final iconPath = GridItemRepository.getIconPath(typeName);
    final key = 'griditem_$typeName';
    final localized = ResourceNames.lookup(context, key);
    final name = localized != key ? localized : typeName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: iconBoxSize,
            height: iconBoxSize,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AssetImageWidget(
                assetPath: iconPath,
                width: iconBoxSize - 8,
                height: iconBoxSize - 8,
                fit: BoxFit.contain,
                altCandidates: imageAltCandidates(iconPath),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Checkbox(
            value: selected,
            onChanged: (v) => onChanged(v ?? false),
          ),
        ],
      ),
    );
  }
}

String _plantDisplayName(BuildContext context, String id) {
  final plant = PlantRepository().getPlantInfoById(id);
  if (plant != null) {
    return ResourceNames.lookup(context, plant.name);
  }
  return id;
}

/// For I-zombie mode: show only translated name, never raw codename with zombie_ prefix.
String _zombieDisplayName(BuildContext context, String id) {
  final key = ZombieRepository().getName(id);
  final translated = ResourceNames.lookup(context, key);
  if (translated == key && key.startsWith('zombie_')) {
    final withoutPrefix = key.substring(7);
    return withoutPrefix
        .split('_')
        .map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}' : '')
        .join(' ');
  }
  return translated;
}

class _ResourceListEditor extends StatelessWidget {
  const _ResourceListEditor({
    required this.title,
    required this.description,
    required this.items,
    required this.accentColor,
    required this.isZombie,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String description;
  final List<String> items;
  final Color accentColor;
  final bool isZombie;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: onAdd,
                  color: accentColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  AppLocalizations.of(context)?.emptyList ?? 'Empty list',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(items.length, (i) {
                  final id = items[i];
                  final zombieTypeName = isZombie ? ZombiePropertiesRepository.getTypeNameByAlias(id) : null;
                  final name = isZombie
                      ? _zombieDisplayName(context, zombieTypeName!)
                      : _plantDisplayName(context, id);
                  final zombie = isZombie ? ZombieRepository().getZombieById(zombieTypeName!) : null;
                  final plant = !isZombie ? PlantRepository().getPlantInfoById(id) : null;
                  final iconPath = isZombie
                      ? (zombie?.iconAssetPath ?? 'assets/images/others/unknown.webp')
                      : (plant?.iconAssetPath ?? 'assets/images/others/unknown.webp');
                  const iconSize = 48.0;
                  return Container(
                    padding: const EdgeInsets.only(
                      left: 4,
                      top: 4,
                      bottom: 4,
                      right: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: iconSize,
                                height: iconSize,
                                child: AssetImageWidget(
                                  assetPath: iconPath,
                                  width: iconSize,
                                  height: iconSize,
                                  fit: BoxFit.cover,
                                  altCandidates: imageAltCandidates(iconPath),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => onRemove(i),
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(4),
                                minimumSize: const Size(28, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
