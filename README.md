# Focus Spark · 专注力训练

一款跨平台专注力训练应用，通过科学设计的游戏化训练，帮助你提升注意力、反应速度和抗干扰能力。基于 Flutter 构建，支持 Windows / Android / iOS。

## ✨ 功能特性

- **5 大核心训练游戏**，难度阶梯覆盖新手到高手
- **10 套预置训练计划**，按强度（5/15/30 分钟）分组
- **能力雷达图**，五维可视化你的训练成长
- **本地排行榜 + 成就系统**，记录每一次进步
- **饮食与健康指导**，通俗易懂的专注力科普
- **程序化专注动画**，无版权、无网络依赖

## 🎮 训练模块

| 模块 | 玩法 | 难度阶梯 |
|------|------|----------|
| 舒尔特方格 | 按顺序点击乱序数字 | L1-L6（3×3 升序 → 6×6 首尾交替），支持**引导模式**、**颜色干扰模式** |
| 动态目标追踪 | 追踪并点击移动目标 | L1-L6（目标变小变快变多） |
| 反应射击 | 限时命中随机出现的靶心 | L1-L6（目标缩小、停留缩短） |
| 抗干扰识别 | Stroop 变体，选颜色不读字 | L1-L6（一致试次占比递减） |
| 节奏分离 | 分别计数左右不同节奏 | L1-L6（左右节拍比变化） |

## 📊 数据统计

- 能力雷达图：视觉搜索 / 动态追踪 / 反应速度 / 抗干扰 / 听觉节奏
- 汇总指标：总训练次数、总时长、连续训练天数
- 成就徽章：首次训练、十次/百次训练、连续三天/七天

## 🛠 技术栈

| 层 | 技术 |
|----|------|
| 框架 | Flutter 3.x |
| 状态管理 | flutter_riverpod |
| 路由 | go_router |
| 本地存储 | shared_preferences |
| 图表 | fl_chart |
| 字体 | google_fonts（Noto Sans SC / Orbitron） |
| 音效 | FFI 调用 Windows PlaySound（跨平台兜底 SystemSound） |

## 🚀 快速开始

### 环境要求
- Flutter SDK ≥ 3.47（含 Dart ≥ 3.x）
- Windows 构建需 Visual Studio 2022（含 C++ 桌面开发工作负载）

### 运行
```bash
# 拉取依赖
flutter pub get

# 运行（Windows）
flutter run -d windows
```

### 构建
```bash
# Windows 发布版
flutter build windows --release
# 产物在 build/windows/x64/runner/Release/

# 打包成安装包（需 Inno Setup 6）
cd installer && ISCC.exe setup.iss
```

## 📁 项目结构

```
lib/
├── core/          # 主题、路由、常量
├── data/
│   ├── models/    # 数据模型（训练计划、训练记录）
│   ├── presets/   # 预置内容（10 套计划、饮食文章）
│   └── repositories/  # 存储仓库
├── services/      # 音频等服务
└── ui/
    ├── games/     # 5 个训练游戏
    ├── training/  # 训练大厅
    ├── plans/     # 训练计划
    ├── stats/     # 数据统计
    ├── diet/      # 饮食健康
    ├── video/     # 专注动画
    ├── settings/  # 设置
    └── home/      # 首页
```

## 📝 说明

- 训练数据与设置保存在本机（SharedPreferences），不涉及云端
- 专注动画为程序化生成，不依赖外部视频/音频资源
- 音频当前为本地合成的 WAV + 系统音效，未引入第三方音频插件

## 📄 License

私有项目，未开源。
