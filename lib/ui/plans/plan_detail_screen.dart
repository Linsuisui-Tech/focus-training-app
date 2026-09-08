import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/training_plan.dart';
import '../../data/presets/preset_plans.dart';

/// 计划详情页：展示模块组成，支持开始训练
class PlanDetailScreen extends StatelessWidget {
  final String? planId;

  const PlanDetailScreen({super.key, this.planId});

  TrainingPlan? _findPlan() {
    if (planId == null || planId == 'new') return null;
    for (final plan in kPresetPlans) {
      if (plan.id == planId) return plan;
    }
    return null;
  }

  String _routeForModule(PlanModule module) {
    return switch (module.type) {
      TrainingModuleType.schulte => RouteNames.schulte,
      TrainingModuleType.tracking => RouteNames.tracking,
      TrainingModuleType.shooting => RouteNames.shooting,
      TrainingModuleType.interference => RouteNames.interference,
      TrainingModuleType.rhythm => RouteNames.rhythm,
      _ => RouteNames.videoLibrary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final plan = _findPlan();

    if (plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('计划详情')),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.extension_outlined, color: AppTheme.nebulaGray, size: 64),
                const SizedBox(height: 16),
                Text('计划不存在或尚未创建', style: context.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  '自定义计划编辑器将在 P4 阶段实现',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(plan.name)),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildHeader(context, plan),
                  const SizedBox(height: 16),
                  _buildMetaRow(context, plan),
                  const SizedBox(height: 24),
                  Text('训练模块', style: context.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...plan.modules.asMap().entries.map(
                        (e) => _buildModuleTile(context, e.key, e.value),
                      ),
                ],
              ),
            ),
            _buildBottomBar(context, plan),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TrainingPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(plan.name, style: context.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(plan.description, style: context.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildMetaRow(BuildContext context, TrainingPlan plan) {
    final (intensityColor, intensityLabel) = switch (plan.intensity) {
      IntensityLevel.low => (AppTheme.successGreen, '低强度'),
      IntensityLevel.medium => (AppTheme.neonCyan, '中强度'),
      IntensityLevel.high => (AppTheme.amberPulse, '高强度'),
    };

    return Row(
      children: [
        _buildMetaCard(Icons.speed, intensityLabel, intensityColor),
        const SizedBox(width: 12),
        _buildMetaCard(Icons.timer_outlined, plan.durationLabel, AppTheme.neonCyan),
        const SizedBox(width: 12),
        _buildMetaCard(Icons.explore_outlined, plan.targetScene.label, AppTheme.violetNeural),
      ],
    );
  }

  Widget _buildMetaCard(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.panelNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleTile(BuildContext context, int index, PlanModule module) {
    final route = _routeForModule(module);
    return Card(
      child: InkWell(
        onTap: () => context.push(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: AppTheme.neonCyan, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title, style: context.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${module.durationSeconds ~/ 60} 分钟'
                      '${module.difficulty != null ? ' · 难度 L${module.difficulty}' : ''}',
                      style: context.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_outline, color: AppTheme.neonCyan),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, TrainingPlan plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.deepNavy,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('返回'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  // 开始训练：跳转到第一个模块
                  final firstModule = plan.modules.first;
                  context.push(_routeForModule(firstModule));
                },
                child: const Text('开始训练'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
