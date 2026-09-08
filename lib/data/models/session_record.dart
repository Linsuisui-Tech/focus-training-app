import '../../core/constants.dart';

/// 一次训练的成绩记录
///
/// 类比：健身 App 里"今天做了 30 分钟有氧，消耗 300 卡"的一条记录。
/// 每个游戏结束后保存一条，供统计页做雷达图和排行榜。
class SessionRecord {
  /// 训练模块类型
  final TrainingModuleType moduleType;

  /// 难度等级（1-6）
  final int difficulty;

  /// 综合得分 0-100（当前以准确率 × 100 计算）
  final double score;

  /// 详细指标（如 accuracy、reactionTimeMs、medianPlateTime 等）
  final Map<String, dynamic> metrics;

  /// 完成时间
  final DateTime timestamp;

  /// 训练时长（秒）
  final int durationSeconds;

  const SessionRecord({
    required this.moduleType,
    required this.difficulty,
    required this.score,
    required this.metrics,
    required this.timestamp,
    required this.durationSeconds,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      moduleType: TrainingModuleType.values.firstWhere(
        (e) => e.name == json['moduleType'],
        orElse: () => TrainingModuleType.schulte,
      ),
      difficulty: json['difficulty'] as int,
      score: (json['score'] as num).toDouble(),
      metrics: (json['metrics'] as Map).cast<String, dynamic>(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      durationSeconds: json['durationSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleType': moduleType.name,
      'difficulty': difficulty,
      'score': score,
      'metrics': metrics,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'durationSeconds': durationSeconds,
    };
  }
}

/// 能力维度（对应雷达图的五个轴）
enum AbilityDimension {
  visualSearch('视觉搜索'),
  tracking('动态追踪'),
  reaction('反应速度'),
  inhibition('抗干扰'),
  rhythm('听觉节奏');

  final String label;

  const AbilityDimension(this.label);
}

/// 训练类型 → 能力维度映射
AbilityDimension abilityDimensionFor(TrainingModuleType type) {
  switch (type) {
    case TrainingModuleType.schulte:
      return AbilityDimension.visualSearch;
    case TrainingModuleType.tracking:
      return AbilityDimension.tracking;
    case TrainingModuleType.shooting:
      return AbilityDimension.reaction;
    case TrainingModuleType.interference:
    case TrainingModuleType.cognitiveInhibition:
      return AbilityDimension.inhibition;
    case TrainingModuleType.rhythm:
    case TrainingModuleType.audioFocus:
      return AbilityDimension.rhythm;
    default:
      return AbilityDimension.visualSearch;
  }
}
