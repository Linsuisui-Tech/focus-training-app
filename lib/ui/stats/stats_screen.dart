import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/session_record.dart';
import '../../data/repositories/training_repository.dart';

/// 数据统计页：能力雷达图 + 汇总 + 最佳成绩
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic> _summary = {'totalCount': 0, 'totalSeconds': 0, 'streak': 0, 'activeDays': 0};
  Map<AbilityDimension, double> _averages = {};
  Map<AbilityDimension, double> _bests = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final summary = await TrainingRepository.getSummary();
    final averages = await TrainingRepository.getAbilityAverages();
    final bests = await TrainingRepository.getAbilityBests();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _averages = averages;
      _bests = bests;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('数据统计')),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
          child: const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan)),
        ),
      );
    }

    final totalSeconds = _summary['totalSeconds'] as int;
    final totalMinutes = totalSeconds ~/ 60;

    return Scaffold(
      appBar: AppBar(title: const Text('数据统计')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.neonCyan,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSummaryCards(context, totalMinutes),
              const SizedBox(height: 24),
              _buildRadarCard(context),
              const SizedBox(height: 24),
              _buildBestsCard(context),
              const SizedBox(height: 24),
              _buildAchievementsCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, int totalMinutes) {
    return Row(
      children: [
        _buildSummaryCard(context, '${_summary['totalCount']}', '总训练次数', Icons.fitness_center, AppTheme.neonCyan),
        const SizedBox(width: 12),
        _buildSummaryCard(context, '$totalMinutes', '总时长(分)', Icons.timer_outlined, AppTheme.violetNeural),
        const SizedBox(width: 12),
        _buildSummaryCard(context, '${_summary['streak']}', '连续天数', Icons.local_fire_department, AppTheme.amberPulse),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.panelNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: context.textTheme.headlineSmall?.copyWith(color: color)),
            const SizedBox(height: 4),
            Text(label, style: context.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarCard(BuildContext context) {
    final dimensions = AbilityDimension.values;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('能力雷达图', style: context.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('各维度平均得分（0-100）', style: context.textTheme.bodySmall),
            const SizedBox(height: 20),
            SizedBox(
              height: 280,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      dataEntries: dimensions
                          .map((d) => RadarEntry(value: _averages[d] ?? 0))
                          .toList(),
                      fillColor: AppTheme.neonCyan.withValues(alpha: 0.2),
                      borderColor: AppTheme.neonCyan,
                      borderWidth: 2,
                      entryRadius: 3,
                    ),
                  ],
                  radarShape: RadarShape.polygon,
                  titlePositionPercentageOffset: 0.25,
                  getTitle: (index, angle) {
                    final d = dimensions[index];
                    return RadarChartTitle(text: d.label);
                  },
                  tickCount: 5,
                  ticksTextStyle: const TextStyle(color: AppTheme.nebulaGray, fontSize: 10),
                  tickBorderData: BorderSide(color: AppTheme.nebulaGray.withValues(alpha: 0.3)),
                  gridBorderData: BorderSide(color: AppTheme.nebulaGray.withValues(alpha: 0.3)),
                  titleTextStyle: const TextStyle(color: AppTheme.starWhite, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestsCard(BuildContext context) {
    final dimensions = AbilityDimension.values;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最佳成绩', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...dimensions.map((d) {
              final best = _bests[d] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(d.label, style: context.textTheme.bodyMedium),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (best / 100).clamp(0, 1),
                          minHeight: 10,
                          backgroundColor: AppTheme.deepNavy,
                          valueColor: AlwaysStoppedAnimation(_colorForDimension(d)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 44,
                      child: Text(
                        best == 0 ? '—' : '${best.toStringAsFixed(0)}',
                        style: context.textTheme.titleMedium?.copyWith(color: AppTheme.neonCyan),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _colorForDimension(AbilityDimension d) {
    switch (d) {
      case AbilityDimension.visualSearch:
        return AppTheme.neonCyan;
      case AbilityDimension.tracking:
        return AppTheme.violetNeural;
      case AbilityDimension.reaction:
        return AppTheme.amberPulse;
      case AbilityDimension.inhibition:
        return AppTheme.alertRed;
      case AbilityDimension.rhythm:
        return AppTheme.successGreen;
    }
  }

  Widget _buildAchievementsCard(BuildContext context) {
    final totalCount = _summary['totalCount'] as int;
    final streak = _summary['streak'] as int;

    final achievements = [
      _Achievement('首次训练', '完成第 1 次训练', totalCount >= 1, Icons.flag),
      _Achievement('十次训练', '累计完成 10 次训练', totalCount >= 10, Icons.military_tech),
      _Achievement('百次训练', '累计完成 100 次训练', totalCount >= 100, Icons.workspace_premium),
      _Achievement('连续三天', '连续训练 3 天', streak >= 3, Icons.local_fire_department),
      _Achievement('连续七天', '连续训练 7 天', streak >= 7, Icons.whatshot),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('成就', style: context.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...achievements.map((a) => _buildAchievementTile(context, a)),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementTile(BuildContext context, _Achievement a) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            a.icon,
            color: a.unlocked ? AppTheme.amberPulse : AppTheme.nebulaGray.withValues(alpha: 0.4),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: a.unlocked ? AppTheme.starWhite : AppTheme.nebulaGray,
                  ),
                ),
                Text(a.desc, style: context.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(
            a.unlocked ? Icons.check_circle : Icons.lock_outline,
            color: a.unlocked ? AppTheme.successGreen : AppTheme.nebulaGray.withValues(alpha: 0.4),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _Achievement {
  final String title;
  final String desc;
  final bool unlocked;
  final IconData icon;

  _Achievement(this.title, this.desc, this.unlocked, this.icon);
}
