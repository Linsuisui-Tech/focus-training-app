import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/repositories/training_repository.dart';

/// 首页：今日计划卡片 + 快速开始 + 数据概览
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _summary = {'totalCount': 0, 'totalSeconds': 0, 'streak': 0};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final s = await TrainingRepository.getSummary();
    if (!mounted) return;
    setState(() => _summary = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildTodayPlanCard(context),
                      const SizedBox(height: 24),
                      _buildQuickStartGrid(context),
                      const SizedBox(height: 24),
                      _buildStatsPreview(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Focus Spark',
              style: GoogleFonts.orbitron(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppTheme.starWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '点亮你的专注力',
              style: context.textTheme.bodyMedium?.copyWith(color: AppTheme.nebulaGray),
            ),
          ],
        ),
        IconButton(
          onPressed: () => context.push(RouteNames.settings),
          icon: const Icon(Icons.settings_outlined, color: AppTheme.neonCyan),
        ),
      ],
    );
  }

  Widget _buildTodayPlanCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.neuralGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.cyanGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日推荐：视觉强化',
            style: context.textTheme.titleLarge?.copyWith(color: AppTheme.spaceBlack),
          ),
          const SizedBox(height: 8),
          Text(
            '15 分钟 · 中强度 · 提升视觉搜索与追踪',
            style: context.textTheme.bodyMedium?.copyWith(color: AppTheme.spaceBlack.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push(RouteNames.trainingHall),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.spaceBlack,
                foregroundColor: AppTheme.neonCyan,
              ),
              child: const Text('开始训练'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartGrid(BuildContext context) {
    final items = [
      _QuickItem('舒尔特方格', Icons.grid_on, RouteNames.schulte),
      _QuickItem('动态追踪', Icons.track_changes, RouteNames.tracking),
      _QuickItem('反应射击', Icons.adjust, RouteNames.shooting),
      _QuickItem('训练计划', Icons.calendar_today, RouteNames.plans),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: items.map((item) => _buildQuickCard(context, item)).toList(),
    );
  }

  Widget _buildQuickCard(BuildContext context, _QuickItem item) {
    return Card(
      child: InkWell(
        onTap: () => context.push(item.route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, color: AppTheme.neonCyan, size: 32),
              const SizedBox(height: 12),
              Text(item.title, style: context.textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsPreview(BuildContext context) {
    final totalCount = (_summary['totalCount'] ?? 0) as int;
    final totalMinutes = ((_summary['totalSeconds'] ?? 0) as int) ~/ 60;
    final streak = (_summary['streak'] ?? 0) as int;
    return Card(
      child: InkWell(
        onTap: () => context.push(RouteNames.stats),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('累计专注', style: context.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      '$totalMinutes 分钟 · $totalCount 次',
                      style: context.textTheme.headlineSmall?.copyWith(color: AppTheme.neonCyan),
                    ),
                    const SizedBox(height: 4),
                    Text('连续 $streak 天', style: context.textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.trending_up, color: AppTheme.successGreen, size: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(RouteNames.home);
          case 1:
            context.push(RouteNames.trainingHall);
          case 2:
            context.push(RouteNames.plans);
          case 3:
            context.push(RouteNames.stats);
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: '首页'),
        BottomNavigationBarItem(icon: Icon(Icons.sports_esports_outlined), label: '训练'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: '计划'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: '统计'),
      ],
    );
  }
}

class _QuickItem {
  final String title;
  final IconData icon;
  final String route;

  _QuickItem(this.title, this.icon, this.route);
}
