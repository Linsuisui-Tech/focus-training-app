# Focus Spark 专注力训练

一款跨平台专注力训练应用，通过科学设计的游戏化训练，帮助你提升注意力、反应速度和抗干扰能力。基于 Flutter 构建，支持 Windows / Android / iOS。

## 功能特点

- 5 大核心训练模块：舒尔特方格、动态目标追踪、反应射击、抗干扰识别（Stroop）、节奏分离，难度阶梯覆盖新手到高手
- 专注动画视频库：程序化生成的呼吸、节拍器、粒子、光轨动画，无版权、无网络依赖
- 训练计划：10 套预置方案，按低 / 中 / 高强度（约 5 / 15 / 30 分钟）分组
- 数据统计：能力雷达图、总次数 / 总时长 / 连续天数、成就徽章
- 饮食与健康指导：内置专注力科普文章
- 本地存储：训练数据与设置保存在本机，不涉及云端

## 技术栈

| 层 | 技术 |
|----|------|
| 框架 | Flutter 3.x |
| 状态管理 | flutter_riverpod |
| 路由 | go_router |
| 本地存储 | shared_preferences |
| 图表 | fl_chart |
| 字体 | google_fonts（Noto Sans SC / Orbitron） |
| 音效 | FFI 调用 Windows PlaySound（跨平台兜底 SystemSound） |

## 快速开始

### 环境要求
- Flutter SDK ≥ 3.47（含 Dart ≥ 3.13）
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
```

## 项目结构
```
lib/
├─ core/          # 主题、路由、常量
├─ data/
│  ├─ models/     # 数据模型（训练计划、训练记录）
│  ├─ presets/    # 预置内容（10 套计划、饮食文章）
│  └─ repositories/  # 存储仓储
├─ services/      # 音频等服务
└─ ui/
   ├─ games/     # 5 个训练游戏
   ├─ training/  # 训练大厅
   ├─ plans/     # 训练计划
   ├─ stats/     # 数据统计
   ├─ diet/      # 饮食健康
   ├─ video/     # 专注动画
   ├─ settings/  # 设置
   └─ home/      # 首页
```

## 说明
- 训练数据与设置保存在本机（SharedPreferences），不涉及云端
- 专注动画为程序化生成，不依赖外部视频/音频资源
- 音效当前为本地合成的 WAV + 系统音效，未引入第三方音频插件

## License
私有项目，未开源。
