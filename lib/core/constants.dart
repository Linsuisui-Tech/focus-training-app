library;

/// 训练模块类型
enum TrainingModuleType {
  schulte,
  tracking,
  shooting,
  interference,
  rhythm,
  audioFocus,
  breathing,
  pomodoro,
  cognitiveInhibition,
}

/// 训练强度档位
enum IntensityLevel {
  low('低强度', 5),
  medium('中强度', 15),
  high('高强度', 30);

  final String label;
  final int defaultMinutes;

  const IntensityLevel(this.label, this.defaultMinutes);
}

/// 难度等级（部分模块通用）
enum Difficulty {
  easy('简单', 1),
  normal('普通', 2),
  hard('困难', 3),
  expert('专家', 4);

  final String label;
  final int value;

  const Difficulty(this.label, this.value);
}

/// 训练场景标签
enum FocusScene {
  shooting('射击'),
  work('工作'),
  study('学习'),
  commute('通勤'),
  rest('休息');

  final String label;

  const FocusScene(this.label);
}

/// 路由名称常量
class RouteNames {
  RouteNames._();

  static const String home = '/';
  static const String trainingHall = '/training';
  static const String schulte = '/training/schulte';
  static const String tracking = '/training/tracking';
  static const String shooting = '/training/shooting';
  static const String interference = '/training/interference';
  static const String rhythm = '/training/rhythm';
  static const String videoLibrary = '/training/video';
  static const String diet = '/diet';
  static const String plans = '/plans';
  static const String planDetail = '/plans/detail';
  static const String stats = '/stats';
  static const String settings = '/settings';
}

/// 应用级常量
class AppConstants {
  AppConstants._();

  static const String appName = 'Focus Spark';
  static const String appNameCn = '专注力训练';
  static const String appVersion = '1.0.0';

  // 本地存储 Key
  static const String hiveBoxName = 'focus_training_box';
  static const String prefThemeMode = 'theme_mode';
  static const String prefSoundEnabled = 'sound_enabled';
  static const String prefVibrationEnabled = 'vibration_enabled';
  static const String prefGunSoundEnabled = 'gun_sound_enabled';
  static const String prefCloudSyncEnabled = 'cloud_sync_enabled';

  // 舒尔特方格默认配置
  static const List<int> schulteGridSizes = [3, 4, 5, 6, 7, 8];

  // 预置计划数量
  static const int presetPlanCount = 10;
}
