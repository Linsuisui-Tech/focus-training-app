# P1 阶段审查摘要 — 基础骨架

## 阶段目标
搭建 Flutter + Flame 工程，配置深空光轨主题与 GoRouter 路由，输出可在 Windows 运行的空壳 App。

## 已完成工作

### 1. 开发环境
- 安装 Flutter SDK 3.47.2（使用清华镜像加速）
- 路径：`C:\Users\Administrator\.workbuddy\binaries\flutter`
- Windows 桌面端构建环境可用（Visual Studio Build Tools 2022 + Windows 10 SDK）
- Android SDK 未安装，当前无法构建 APK；iOS 需在 macOS 环境构建

### 2. 项目初始化
- 创建 Flutter 工程：`focus_training_app`
- 启用平台：Android / iOS / Windows
- 工作区路径：`D:\work  buddy AI 产生物\林的专注力训练App`
- 由于 Windows 构建工具对中文路径支持不完善，实际构建在英文路径 `C:\workbuddy-projects\focus_training_app` 完成，源码已同步回工作区

### 3. 依赖管理
已添加：
- `flame: ^1.18.0` → 实际解析 1.38.2
- `flutter_riverpod: ^2.5.1` → 状态管理
- `go_router: ^14.2.1` → 路由
- `hive: ^2.2.3` + `hive_flutter: ^1.1.0` → 本地数据
- `shared_preferences: ^2.2.3` → 配置存储
- `fl_chart: ^0.68.0` → 图表
- `google_fonts: ^6.2.1` → 字体

暂注释（P2/P3 再引入）：
- `audioplayers: ^6.0.0` —— 在 Windows 构建时会触发 nuget 包安装失败（`Microsoft.Windows.ImplementationLibrary`），待后续单独处理音频插件依赖。

### 4. 主题系统
- 文件：`lib/core/theme.dart`
- 原创"深空光轨 / 神经脉冲"主题
- 核心色板：
  - 背景 `#0B0D17`
  - 高亮 `#00E0FF`
  - 提醒 `#FFB800`
  - 辅助 `#7B61FF`
- 字体：Orbitron（英文标题）+ Noto Sans SC（中文正文）
- 已配置全局 ThemeData、ElevatedButton、OutlinedButton、Card、AppBar、BottomNavigationBar 样式

### 5. 路由系统
- 文件：`lib/core/router.dart`
- 使用 GoRouter 声明式路由
- 已配置页面：
  - `/` 首页
  - `/training` 训练大厅
  - `/training/schulte?size=5` 舒尔特方格
  - `/training/tracking` 动态目标追踪
  - `/training/shooting` 反应射击
  - `/training/video` 专注视频库
  - `/diet` 饮食健康
  - `/plans` 训练计划列表
  - `/plans/detail?id=1` 计划详情
  - `/stats` 数据统计
  - `/settings` 设置

### 6. 页面骨架
已创建所有页面的空壳 Widget：
- `lib/ui/home/home_screen.dart`
- `lib/ui/training/training_hall_screen.dart`
- `lib/ui/games/schulte/schulte_game_screen.dart`
- `lib/ui/games/tracking/tracking_game_screen.dart`
- `lib/ui/games/shooting/shooting_game_screen.dart`
- `lib/ui/video/video_library_screen.dart`
- `lib/ui/diet/diet_screen.dart`
- `lib/ui/plans/plans_screen.dart`
- `lib/ui/plans/plan_detail_screen.dart`
- `lib/ui/stats/stats_screen.dart`
- `lib/ui/settings/settings_screen.dart`

### 7. 代码质量
- `dart analyze lib`：无错误、无警告
- 已迁移所有 `Color.withOpacity` 到 `Color.withValues(alpha: ...)` 以适配 Flutter 3.47
- 已修复 `CardTheme` → `CardThemeData` 类型变更

### 8. 构建验证
- Windows release 构建成功
- 可执行文件：`release/windows/focus_training_app.exe`（约 91 KB，依赖同目录 `flutter_windows.dll` 和 `data/`）
- 由于中文路径问题，Windows 构建必须在英文路径执行；工作区源码保持同步

## 关键决策与说明

| 决策 | 说明 |
|------|------|
| 项目实际构建路径 | `C:\workbuddy-projects\focus_training_app`，避免 Windows 构建工具中文路径乱码 |
| 源码主位置 | `D:\work  buddy AI 产生物\林的专注力训练App`，与用户工作区一致 |
| audioplayers 暂移除 | 避免 P1 阶段 nuget 构建阻塞，P2/P3 再集成 |
| 设置页射击音效开关 | UI 已预留，实际音效功能待 P2 接入 |

## 下一步（P2 核心游戏）
1. 实现舒尔特方格（Flame 渲染 + 点击计时 + 排行榜）
2. 实现动态目标追踪（移动靶 + 眼球追踪式训练）
3. 实现反应射击小游戏（快速定位 + 反应时测试）
4. 接入 audioplayers 并解决 Windows nuget 依赖

## 待用户确认
- P1 主题与路由是否符合预期？
- 是否同意进入 P2 核心游戏开发？
