import 'package:c_editor/data/pvz_models/PvzModel.dart';

class ZombieResilienceData extends PvzModel {
  ZombieResilienceData({
    this.amount = 300,
    this.weakType = 6,
    this.recoverSpeed = 25,
    this.damageThresholdPerSecond = 1500,
    this.resilienceBaseDamageThreshold = 40,
    this.resilienceExtraDamageThreshold = 60,
  });

  int amount;
  int weakType;
  double recoverSpeed;
  double damageThresholdPerSecond;
  int resilienceBaseDamageThreshold;
  int resilienceExtraDamageThreshold;

  factory ZombieResilienceData.fromJson(Map<String, dynamic> json) {
    return ZombieResilienceData(
      amount: (json['Amount'] as num?)?.toInt() ?? 300,
      weakType: (json['WeakType'] as num?)?.toInt() ?? 6,
      recoverSpeed: (json['RecoverSpeed'] as num?)?.toDouble() ?? 25,
      damageThresholdPerSecond:
          (json['DamageThresholdPerSecond'] as num?)?.toDouble() ?? 1500,
      resilienceBaseDamageThreshold:
          (json['ResilienceBaseDamageThreshold'] as num?)?.toInt() ?? 40,
      resilienceExtraDamageThreshold:
          (json['ResilienceExtraDamageThreshold'] as num?)?.toInt() ?? 60,
    );
  }

  Map<String, dynamic> toJson() => {
    'Amount': amount,
    'WeakType': weakType,
    'RecoverSpeed': recoverSpeed,
    'DamageThresholdPerSecond': damageThresholdPerSecond,
    'ResilienceBaseDamageThreshold': resilienceBaseDamageThreshold,
    'ResilienceExtraDamageThreshold': resilienceExtraDamageThreshold,
  };
}

