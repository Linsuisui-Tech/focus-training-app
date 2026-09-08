import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

/// 训练大厅：6 大模块图标入口
class TrainingHallScreen extends StatelessWidget {
  const TrainingHallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _Module('舒尔特方格', '视觉搜索训练', Icons.grid_on, RouteNames.schulte, AppTheme.neonCyan),
      _Module('动态目标追踪', '眼球追随移动目标', Icons.track_changes, RouteNames.tracking, AppTheme.violetNeural),
      _Module('反应射击', '快速定位与反应', Icons.adjust, RouteNames.shooting, AppTheme.amberPulse),
      _Module('抗干扰识别', 'Stroop 颜色冲突', Icons.psychology, RouteNames.interference, AppTheme.alertRed),
      _Module('节奏分离', '左右节拍分配', Icons.graphic_eq, RouteNames.rhythm, AppTheme.successGreen),
      _Module('专注视频库', '程序化动画与声景', Icons.play_circle_outline, RouteNames.videoLibrary, AppTheme.successGreen),
      _Module('饮食健康', '专注力友好饮食', Icons.restaurant, RouteNames.diet, AppTheme.alertRed),
      _Module('训练计划', '自定义与推荐方案', Icons.calendar_today, RouteNames.plans, AppTheme.nebulaGray),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('训练大厅')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            itemCount: modules.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              final m = modules[index];
              return Card(
                child: InkWell(
                  onTap: () => context.push(m.route),
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(m.icon, color: m.color, size: 40),
                          const SizedBox(height: 12),
                          Text(m.title, style: context.textTheme.titleMedium, textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(m.subtitle, style: context.textTheme.bodySmall, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Module {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;

  _Module(this.title, this.subtitle, this.icon, this.route, this.color);
}
