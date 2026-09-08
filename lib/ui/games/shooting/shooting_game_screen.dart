import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/models/session_record.dart';
import '../../../data/repositories/training_repository.dart';

/// 反应射击难度配置
class ShootingLevel {
  final String label;
  final double targetSize;
  final double stayDuration; // 目标停留秒数
  final double spawnInterval; // 生成间隔秒数
  final int totalTargets;

  const ShootingLevel({
    required this.label,
    required this.targetSize,
    required this.stayDuration,
    required this.spawnInterval,
    required this.totalTargets,
  });
}

const List<ShootingLevel> _kShootingLevels = [
  ShootingLevel(label: 'L1', targetSize: 80, stayDuration: 2.5, spawnInterval: 2.0, totalTargets: 10),
  ShootingLevel(label: 'L2', targetSize: 64, stayDuration: 2.0, spawnInterval: 1.8, totalTargets: 15),
  ShootingLevel(label: 'L3', targetSize: 56, stayDuration: 1.6, spawnInterval: 1.6, totalTargets: 20),
  ShootingLevel(label: 'L4', targetSize: 48, stayDuration: 1.3, spawnInterval: 1.4, totalTargets: 25),
  ShootingLevel(label: 'L5', targetSize: 40, stayDuration: 1.0, spawnInterval: 1.2, totalTargets: 30),
  ShootingLevel(label: 'L6', targetSize: 32, stayDuration: 0.8, spawnInterval: 1.0, totalTargets: 35),
];

class _ShootingTarget {
  double x;
  double y;
  DateTime spawnTime;
  bool hit = false;

  _ShootingTarget({required this.x, required this.y, required this.spawnTime});
}

/// 反应射击训练页
class ShootingGameScreen extends StatefulWidget {
  const ShootingGameScreen({super.key});

  @override
  State<ShootingGameScreen> createState() => _ShootingGameScreenState();
}

class _ShootingGameScreenState extends State<ShootingGameScreen> {
  int _selectedLevelIndex = 0;
  final Random _rng = Random();
  _ShootingTarget? _currentTarget;
  int _hits = 0;
  int _misses = 0;
  int _combo = 0;
  int _maxCombo = 0;
  final List<double> _reactionTimes = []; // 毫秒
  int _spawnedCount = 0;
  bool _isPlaying = false;
  Timer? _spawnTimer;
  Timer? _countdownTimer;
  double _elapsed = 0;
  double _gameDurationSeconds = 30;
  Size _playArea = Size.zero;

  @override
  void initState() {
    super.initState();
    _startGame(0);
  }

  void _startGame(int levelIndex) {
    _selectedLevelIndex = levelIndex;
    final level = _kShootingLevels[levelIndex];
    _hits = 0;
    _misses = 0;
    _combo = 0;
    _maxCombo = 0;
    _reactionTimes.clear();
    _spawnedCount = 0;
    _elapsed = 0;
    _gameDurationSeconds = level.totalTargets * level.spawnInterval + level.stayDuration;
    _isPlaying = true;
    _currentTarget = null;

    _spawnTimer?.cancel();
    _countdownTimer?.cancel();

    _spawnTarget();
    _spawnTimer = Timer.periodic(Duration(milliseconds: (level.spawnInterval * 1000).round()), (_) {
      if (!_isPlaying) return;
      if (_currentTarget != null && !_currentTarget!.hit) {
        // 上一个没打中，算 miss
        _combo = 0;
        _misses++;
      }
      _spawnTarget();
      setState(() {});
    });

    _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _elapsed += 0.1;
        if (_elapsed >= _gameDurationSeconds || _spawnedCount >= level.totalTargets + 1) {
          _finishGame();
        }
      });
    });

    setState(() {});
  }

  void _spawnTarget() {
    final level = _kShootingLevels[_selectedLevelIndex];
    if (_spawnedCount >= level.totalTargets) {
      return;
    }
    _spawnedCount++;
    _currentTarget = _ShootingTarget(
      x: _rng.nextDouble() * (_playArea.width - level.targetSize) + level.targetSize / 2,
      y: _rng.nextDouble() * (_playArea.height - level.targetSize) + level.targetSize / 2,
      spawnTime: DateTime.now(),
    );
  }

  void _onTargetHit() {
    if (!_isPlaying || _currentTarget == null || _currentTarget!.hit) return;
    final now = DateTime.now();
    final reaction = now.difference(_currentTarget!.spawnTime).inMilliseconds.toDouble();
    _reactionTimes.add(reaction);
    _currentTarget!.hit = true;
    _hits++;
    _combo++;
    if (_combo > _maxCombo) _maxCombo = _combo;
    setState(() {});

    // 立即生成下一个
    _spawnTimer?.cancel();
    final level = _kShootingLevels[_selectedLevelIndex];
    if (_spawnedCount >= level.totalTargets) {
      _finishGame();
      return;
    }
    _spawnTarget();
    _spawnTimer = Timer.periodic(Duration(milliseconds: (level.spawnInterval * 1000).round()), (_) {
      if (!_isPlaying) return;
      if (_currentTarget != null && !_currentTarget!.hit) {
        _combo = 0;
        _misses++;
      }
      _spawnTarget();
      setState(() {});
    });
    setState(() {});
  }

  void _onMiss() {
    if (!_isPlaying) return;
    _combo = 0;
    _misses++;
    setState(() {});
  }

  void _finishGame() {
    _isPlaying = false;
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {});
    _saveRecord();
    _showResultDialog();
  }

  void _saveRecord() {
    final accuracy = _calculateAccuracy();
    TrainingRepository.saveRecord(SessionRecord(
      moduleType: TrainingModuleType.shooting,
      difficulty: _selectedLevelIndex + 1,
      score: accuracy * 100,
      metrics: {
        'hits': _hits.toDouble(),
        'misses': _misses.toDouble(),
        'maxCombo': _maxCombo.toDouble(),
        'avgReactionTime': double.parse(_calculateAverageReactionTime().toStringAsFixed(0)),
      },
      timestamp: DateTime.now(),
      durationSeconds: _elapsed.round(),
    ));
  }

  double _calculateAccuracy() {
    final total = _hits + _misses;
    if (total == 0) return 0;
    return _hits / total;
  }

  double _calculateAverageReactionTime() {
    if (_reactionTimes.isEmpty) return 0;
    return _reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length;
  }

  void _showResultDialog() {
    final accuracy = _calculateAccuracy();
    final avgReaction = _calculateAverageReactionTime();
    final stateContext = context;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.panelNavy,
        title: Text('训练完成', style: Theme.of(dialogContext).textTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('命中次数', '$_hits'),
            _buildResultRow('脱靶次数', '$_misses'),
            _buildResultRow('最高连击', '$_maxCombo'),
            _buildResultRow('准确率', '${(accuracy * 100).toStringAsFixed(1)}%'),
            _buildResultRow('平均反应时', '${avgReaction.toStringAsFixed(0)}ms'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _startGame(_selectedLevelIndex);
            },
            child: const Text('再来一次'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              stateContext.pop();
            },
            child: const Text('返回大厅'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: context.textTheme.bodyMedium),
          Text(value, style: context.textTheme.titleMedium?.copyWith(color: AppTheme.neonCyan)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = _kShootingLevels[_selectedLevelIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('反应射击'),
        actions: [
          IconButton(
            onPressed: () => _startGame(_selectedLevelIndex),
            icon: const Icon(Icons.refresh),
            tooltip: '重新开始',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_elapsed.toStringAsFixed(1)}s',
                style: context.textTheme.titleMedium?.copyWith(color: AppTheme.neonCyan),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLevelSelector(),
                const SizedBox(height: 12),
                _buildStatsBar(),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _playArea = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        onTap: _onMiss,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.deepNavy,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
                          ),
                          child: Stack(
                            children: [
                              if (_currentTarget != null && !_currentTarget!.hit)
                                Positioned(
                                  left: _currentTarget!.x - level.targetSize / 2,
                                  top: _currentTarget!.y - level.targetSize / 2,
                                  child: GestureDetector(
                                    onTap: _onTargetHit,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 100),
                                      width: level.targetSize,
                                      height: level.targetSize,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            AppTheme.amberPulse,
                                            AppTheme.alertRed,
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.amberPulse.withValues(alpha: 0.5),
                                            blurRadius: 16,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                        border: Border.all(color: AppTheme.starWhite, width: 2),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.gps_fixed,
                                          color: AppTheme.starWhite,
                                          size: level.targetSize * 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelSelector() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _kShootingLevels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final level = _kShootingLevels[index];
          final isSelected = index == _selectedLevelIndex;
          return ChoiceChip(
            label: Text(
              level.label,
              style: TextStyle(
                color: isSelected ? AppTheme.spaceBlack : AppTheme.starWhite,
              ),
            ),
            selected: isSelected,
            selectedColor: AppTheme.neonCyan,
            backgroundColor: AppTheme.panelNavy,
            onSelected: (_) => _startGame(index),
          );
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    final accuracy = _calculateAccuracy();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat('命中', '$_hits'),
        _buildStat('连击', '$_combo'),
        _buildStat('准确率', '${(accuracy * 100).toStringAsFixed(0)}%'),
      ],
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: context.textTheme.titleLarge?.copyWith(color: AppTheme.neonCyan)),
        Text(label, style: context.textTheme.bodySmall),
      ],
    );
  }
}
