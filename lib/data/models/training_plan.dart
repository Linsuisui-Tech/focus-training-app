import '../../core/constants.dart';

/// 训练计划中的一个模块
///
/// 类比：一份健身计划里的一个动作，比如"平板支撑 60 秒"。
/// 一个 [TrainingPlan] 由多个模块按顺序组成。
class PlanModule {
  /// 模块类型（舒尔特/追踪/射击/抗干扰/节奏/听觉/呼吸/番茄钟等）
  final TrainingModuleType type;

  /// 显示标题
  final String title;

  /// 预计时长（秒）
  final int durationSeconds;

  /// 难度（可选，1-6 对应游戏内 L1-L6）
  final int? difficulty;

  /// 重复次数（可选）
  final int? repeatCount;

  /// 额外参数（如舒尔特网格大小、射击目标数）
  final Map<String, dynamic>? params;

  const PlanModule({
    required this.type,
    required this.title,
    required this.durationSeconds,
    this.difficulty,
    this.repeatCount,
    this.params,
  });

  /// 从 JSON 反序列化
  factory PlanModule.fromJson(Map<String, dynamic> json) {
    return PlanModule(
      type: TrainingModuleType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TrainingModuleType.schulte,
      ),
      title: json['title'] as String,
      durationSeconds: json['durationSeconds'] as int,
      difficulty: json['difficulty'] as int?,
      repeatCount: json['repeatCount'] as int?,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'title': title,
      'durationSeconds': durationSeconds,
      if (difficulty != null) 'difficulty': difficulty,
      if (repeatCount != null) 'repeatCount': repeatCount,
      if (params != null) 'params': params,
    };
  }
}

/// 训练计划
///
/// 类比：一份完整的健身计划，比如"周一：胸背训练"，里面包含多个动作（模块）。
class TrainingPlan {
  /// 唯一标识
  final String id;

  /// 计划名称
  final String name;

  /// 一句话描述
  final String description;

  /// 强度档位
  final IntensityLevel intensity;

  /// 适用场景
  final FocusScene targetScene;

  /// 模块列表（按顺序执行）
  final List<PlanModule> modules;

  /// 是否预置方案（false 表示用户自定义）
  final bool isPreset;

  const TrainingPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.intensity,
    required this.targetScene,
    required this.modules,
    this.isPreset = true,
  });

  /// 总时长（秒）
  int get totalDurationSeconds =>
      modules.fold(0, (sum, m) => sum + m.durationSeconds * (m.repeatCount ?? 1));

  /// 总时长格式化为 "X 分钟" 或 "X 分 Y 秒"
  String get durationLabel {
    final total = totalDurationSeconds;
    final minutes = total ~/ 60;
    final seconds = total % 60;
    if (minutes == 0) return '$seconds 秒';
    if (seconds == 0) return '$minutes 分钟';
    return '$minutes 分 $seconds 秒';
  }

  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    return TrainingPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      intensity: IntensityLevel.values.firstWhere(
        (e) => e.name == json['intensity'],
        orElse: () => IntensityLevel.medium,
      ),
      targetScene: FocusScene.values.firstWhere(
        (e) => e.name == json['targetScene'],
        orElse: () => FocusScene.work,
      ),
      modules: (json['modules'] as List)
          .map((m) => PlanModule.fromJson(m as Map<String, dynamic>))
          .toList(),
      isPreset: json['isPreset'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'intensity': intensity.name,
      'targetScene': targetScene.name,
      'modules': modules.map((m) => m.toJson()).toList(),
      'isPreset': isPreset,
    };
  }
}
