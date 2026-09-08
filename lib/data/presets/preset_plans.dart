import '../../core/constants.dart';
import '../models/training_plan.dart';

/// 10 套预置训练计划
///
/// 分为三档强度：
/// - 低强度约 5 分钟（碎片化场景）
/// - 中强度约 15 分钟（日常训练）
/// - 高强度约 30 分钟（深度训练）
const List<TrainingPlan> kPresetPlans = [
  // ============ 低强度（约 5 分钟） ============
  TrainingPlan(
    id: 'preset_1',
    name: '晨间唤醒',
    description: '快速激活注意力，开启清醒的一天',
    intensity: IntensityLevel.low,
    targetScene: FocusScene.work,
    modules: [
      PlanModule(
        type: TrainingModuleType.schulte,
        title: '舒尔特方格 3×3',
        durationSeconds: 120,
        difficulty: 1,
        params: {'gridSize': 3},
      ),
      PlanModule(
        type: TrainingModuleType.breathing,
        title: '晨间呼吸唤醒',
        durationSeconds: 180,
      ),
    ],
  ),
  TrainingPlan(
    id: 'preset_2',
    name: '通勤专注',
    description: '利用碎片时间训练听觉专注与反应',
    intensity: IntensityLevel.low,
    targetScene: FocusScene.commute,
    modules: [
      PlanModule(
        type: TrainingModuleType.audioFocus,
        title: '听觉专注训练',
        durationSeconds: 150,
      ),
      PlanModule(
        type: TrainingModuleType.shooting,
        title: '反应射击 20 次',
        durationSeconds: 150,
        difficulty: 1,
        params: {'targets': 20},
      ),
    ],
  ),
  TrainingPlan(
    id: 'preset_10',
    name: '睡前舒缓',
    description: '放松神经，帮助入睡',
    intensity: IntensityLevel.low,
    targetScene: FocusScene.rest,
    modules: [
      PlanModule(
        type: TrainingModuleType.breathing,
        title: '舒缓呼吸放松',
        durationSeconds: 150,
      ),
      PlanModule(
        type: TrainingModuleType.audioFocus,
        title: '助眠声景',
        durationSeconds: 150,
        params: {'scene': 'sleep'},
      ),
    ],
  ),

  // ============ 中强度（约 15 分钟） ============
  TrainingPlan(
    id: 'preset_3',
    name: '午休重启',
    description: '恢复下午的专注力与精神状态',
    intensity: IntensityLevel.medium,
    targetScene: FocusScene.work,
    modules: [
      PlanModule(
        type: TrainingModuleType.schulte,
        title: '舒尔特方格 4×4',
        durationSeconds: 300,
        difficulty: 2,
        params: {'gridSize': 4},
      ),
      PlanModule(
        type: TrainingModuleType.tracking,
        title: '动态目标追踪',
        durationSeconds: 300,
        difficulty: 2,
      ),
      PlanModule(
        type: TrainingModuleType.breathing,
        title: '冥想放松',
        durationSeconds: 300,
      ),
    ],
  ),
  TrainingPlan(
    id: 'preset_4',
    name: '视觉强化',
    description: '提升视觉搜索与追踪能力',
    intensity: IntensityLevel.medium,
    targetScene: FocusScene.shooting,
    modules: [
      PlanModule(
        type: TrainingModuleType.schulte,
        title: '舒尔特方格 5×5',
        durationSeconds: 300,
        difficulty: 3,
        params: {'gridSize': 5},
      ),
      PlanModule(
        type: TrainingModuleType.tracking,
        title: '动态目标追踪',
        durationSeconds: 300,
        difficulty: 3,
      ),
      PlanModule(
        type: TrainingModuleType.shooting,
        title: '快速定位训练',
        durationSeconds: 300,
        difficulty: 2,
      ),
    ],
  ),
  TrainingPlan(
    id: 'preset_5',
    name: '深度工作预备',
    description: '进入心流状态，为深度工作热身',
    intensity: IntensityLevel.medium,
    targetScene: FocusScene.work,
    modules: [
      PlanModule(
        type: TrainingModuleType.shooting,
        title: '反应射击训练',
        durationSeconds: 300,
        difficulty: 2,
      ),
      PlanModule(
        type: TrainingModuleType.audioFocus,
        title: '专注声景',
        durationSeconds: 300,
      ),
      PlanModule(
        type: TrainingModuleType.pomodoro,
        title: '番茄专注倒计时',
        durationSeconds: 300,
      ),
    ],
  ),
  TrainingPlan(
    id: 'preset_9',
    name: '认知抑制',
    description: '抑制干扰信息，提升抗干扰能力',
    intensity: IntensityLevel.medium,
    targetScene: FocusScene.study,
    modules: [
      PlanModule(
        type: TrainingModuleType.interference,
        title: '抗干扰识别训练',
        durationSeconds: 450,
        difficulty: 3,
      ),
      PlanModule(
        type: TrainingModuleType.audioFocus,
        title: '听觉专注训练',
        durationSeconds: 450,
      ),
    ],
  ),

  // ============ 高强度（约 30 分钟） ============
  TrainingPlan(
    id: 'preset_6',
    name: '射击专项',
    description: '提升射击场景下的专注与反应',
    intensity: IntensityLevel.high,
    targetScene: FocusScene.shooting,
    modules: [
      PlanModule(
        type: TrainingModuleType.shooting,
        title: '快速定位训练',
        durationSeconds: 600,
        difficulty: 4,
      ),
      PlanModule(
        type: TrainingModuleType.tracking,
        title: '动态目标追踪',
        durationSeconds: 600,
        difficulty: 4,
      ),
      PlanModule(
        type: TrainingModuleType.shooting,
        title: '反应射击进阶',
        durationSeconds: 600,
        difficulty: 5,
      ),
    ],
  ),
  TrainingPlan(
    id: 'preset_7',
    name: '全脑激活',
    description: '综合训练多种认知能力',
    intensity: IntensityLevel.high,
    targetScene: FocusScene.work,
    modules: [
      PlanModule(
        type: TrainingModuleType.schulte,
        title: '舒尔特方格 6×6',
        durationSeconds: 450,
        difficulty: 6,
        params: {'gridSize': 6},
      ),
      PlanModule(
        type: TrainingModuleType.tracking,
        title: '动态目标追踪',
        durationSeconds: 450,
        difficulty: 4,
      ),
      PlanModule(
        type: TrainingModuleType.shooting,
        title: '反应射击训练',
        durationSeconds: 450,
        difficulty: 4,
      ),
      PlanModule(
        type: TrainingModuleType.interference,
        title: '抗干扰识别',
        durationSeconds: 450,
        difficulty: 4,
      ),
    ],
  ),
  TrainingPlan(
    id: 'preset_8',
    name: '动态反应',
    description: '强化反应速度与决策能力',
    intensity: IntensityLevel.high,
    targetScene: FocusScene.shooting,
    modules: [
      PlanModule(
        type: TrainingModuleType.tracking,
        title: '高速移动靶追踪',
        durationSeconds: 900,
        difficulty: 5,
      ),
      PlanModule(
        type: TrainingModuleType.shooting,
        title: '极限反应射击',
        durationSeconds: 900,
        difficulty: 6,
      ),
    ],
  ),
];

/// 训练模块类型的中文标签与图标，供计划系统展示
const Map<TrainingModuleType, String> kModuleTypeLabels = {
  TrainingModuleType.schulte: '舒尔特方格',
  TrainingModuleType.tracking: '动态追踪',
  TrainingModuleType.shooting: '反应射击',
  TrainingModuleType.interference: '抗干扰识别',
  TrainingModuleType.rhythm: '节奏分离',
  TrainingModuleType.audioFocus: '听觉专注',
  TrainingModuleType.breathing: '呼吸放松',
  TrainingModuleType.pomodoro: '番茄钟',
  TrainingModuleType.cognitiveInhibition: '认知抑制',
};
