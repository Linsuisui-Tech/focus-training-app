import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/models/training_plan.dart';
import '../../data/presets/preset_plans.dart';

/// 训练计划系统：预置方案 + 自定义计划列表
class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lowPlans = kPresetPlans.where((p) => p.intensity == IntensityLevel.low).toList();
    final mediumPlans = kPresetPlans.where((p) => p.intensity == IntensityLevel.medium).toList();
    final highPlans = kPresetPlans.where((p) => p.intensity == IntensityLevel.high).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('训练计划')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: _tabIndex == 0
                  ? _buildPresetList(context, lowPlans, mediumPlans, highPlans)
                  : _buildCustomPlanEntry(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.panelNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTab('推荐方案', 0),
          _buildTab('我的计划', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.neonCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppTheme.spaceBlack : AppTheme.nebulaGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresetList(
    BuildContext context,
    List<TrainingPlan> lowPlans,
    List<TrainingPlan> mediumPlans,
    List<TrainingPlan> highPlans,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        _buildIntensitySection(context, '低强度 · 约 5 分钟', lowPlans, AppTheme.successGreen),
        _buildIntensitySection(context, '中强度 · 约 15 分钟', mediumPlans, AppTheme.neonCyan),
        _buildIntensitySection(context, '高强度 · 约 30 分钟', highPlans, AppTheme.amberPulse),
      ],
    );
  }

  Widget _buildIntensitySection(
    BuildContext context,
    String title,
    List<TrainingPlan> plans,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(title, style: context.textTheme.titleMedium),
            ],
          ),
        ),
        ...plans.map((plan) => _buildPlanCard(context, plan)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPlanCard(BuildContext context, TrainingPlan plan) {
    final moduleCount = plan.modules.length;
    return Card(
      child: InkWell(
        onTap: () => context.push('${RouteNames.planDetail}?id=${plan.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildIntensityBadge(plan.intensity),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.name, style: context.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(plan.description, style: context.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMetaChip(plan.durationLabel, AppTheme.neonCyan),
                        const SizedBox(width: 8),
                        _buildMetaChip('$moduleCount 个模块', AppTheme.violetNeural),
                        const SizedBox(width: 8),
                        _buildMetaChip(plan.targetScene.label, AppTheme.nebulaGray),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.neonCyan),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntensityBadge(IntensityLevel intensity) {
    final (color, label) = switch (intensity) {
      IntensityLevel.low => (AppTheme.successGreen, '低'),
      IntensityLevel.medium => (AppTheme.neonCyan, '中'),
      IntensityLevel.high => (AppTheme.amberPulse, '高'),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildMetaChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildCustomPlanEntry(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: InkWell(
            onTap: () => context.push('${RouteNames.planDetail}?id=new'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.add_circle_outline, color: AppTheme.neonCyan, size: 48),
                  const SizedBox(height: 16),
                  Text('创建自定义计划', style: context.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    '从 9 种训练模块中自由组合，设置时长与难度',
                    style: context.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '自定义计划保存功能将在 P4 阶段接入本地存储',
            style: context.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
