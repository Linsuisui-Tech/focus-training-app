import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/models/session_record.dart';
import '../../../data/repositories/training_repository.dart';

/// 动态目标追踪难度配置
class TrackingLevel {
  final String label;
  final double targetSize;
  final double speed;
  final int targetCount;
  final Duration gameDuration;

  const TrackingLevel({
    required this.label,
    required this.targetSize,
    required this.speed,
    this.targetCount = 1,
    this.gameDuration = const Duration(seconds: 30),
  });
}

const List<TrackingLevel> _kTrackingLevels = [
  TrackingLevel(label: 'L1', targetSize: 72, speed: 60, targetCount: 1, gameDuration: Duration(seconds: 30)),
  TrackingLevel(label: 'L2', targetSize: 60, speed: 90, targetCount: 1, gameDuration: Duration(seconds: 30)),
  TrackingLevel(label: 'L3', targetSize: 56, speed: 120, targetCount: 2, gameDuration: Duration(seconds: 30)),
  TrackingLevel(label: 'L4', targetSize: 48, speed: 160, targetCount: 2, gameDuration: Duration(seconds: 30)),
  TrackingLevel(label: 'L5', targetSize: 40, speed: 200, targetCount: 3, gameDuration: Duration(seconds: 30)),
  TrackingLevel(label: 'L6', targetSize: 32, speed: 260, targetCount: 3, gameDuration: Duration(seconds: 30)),
];

/// 动态目标追踪训练页
class TrackingGameScreen extends StatefulWidget {
  const TrackingGameScreen({super.key});

  @override
  State<TrackingGameScreen> createState() => _TrackingGameScreenState();
}

class _TrackingTarget {
  double x;
  double y;
  double vx;
  double vy;
  bool hit = false;

  _TrackingTarget({required this.x, required this.y, required this.vx, required this.vy});
}

class _TrackingGameScreenState extends State<TrackingGameScreen> with SingleTickerProviderStateMixin {
  int _selectedLevelIndex = 0;
  late AnimationController _animController;
  late List<_TrackingTarget> _targets;
  int _hits = 0;
  int _misses = 0;
  final List<double> _reactionTimes = []; // 毫秒
  DateTime? _targetAppearTime;
  double _elapsed = 0;
  double _gameDurationSeconds = 30;
  bool _isPlaying = false;
  Timer? _gameTimer;
  Size _playArea = Size.zero;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _animController.addListener(_updateTargets);
    _startGame(0);
  }

  void _startGame(int levelIndex) {
    _selectedLevelIndex = levelIndex;
    final level = _kTrackingLevels[levelIndex];
    _hits = 0;
    _misses = 0;
    _reactionTimes.clear();
    _elapsed = 0;
    _gameDurationSeconds = level.gameDuration.inSeconds.toDouble();
    _isPlaying = true;

    _targets = List.generate(level.targetCount, (_) => _createTarget(level));
    _targetAppearTime = DateTime.now();

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _elapsed += 0.1;
        if (_elapsed >= _gameDurationSeconds) {
          _finishGame();
        }
      });
    });

    setState(() {});
  }

  _TrackingTarget _createTarget(TrackingLevel level) {
    final size = level.targetSize;
    // 首次进入时 _playArea 尚未完成布局（Size.zero），给一个兜底画布尺寸，
    // 避免首个目标生成到负坐标导致不可见。
    final w = _playArea.width <= 0 ? 360.0 : _playArea.width;
    final h = _playArea.height <= 0 ? 480.0 : _playArea.height;
    final maxX = (w - size).clamp(0.0, double.infinity);
    final maxY = (h - size).clamp(0.0, double.infinity);
    return _TrackingTarget(
      x: _rng.nextDouble() * maxX + size / 2,
      y: _rng.nextDouble() * maxY + size / 2,
      vx: (_rng.nextDouble() - 0.5) * 2 * level.speed,
      vy: (_rng.nextDouble() - 0.5) * 2 * level.speed,
    );
  }

  void _updateTargets() {
    if (!_isPlaying || _playArea == Size.zero) return;
    final level = _kTrackingLevels[_selectedLevelIndex];
    final dt = 1 / 60;
    final size = level.targetSize;

    setState(() {
      for (final t in _targets) {
        t.x += t.vx * dt;
        t.y += t.vy * dt;

        // 边界反弹
        if (t.x <= size / 2) {
          t.x = size / 2;
          t.vx = t.vx.abs();
        } else if (t.x >= _playArea.width - size / 2) {
          t.x = _playArea.width - size / 2;
          t.vx = -t.vx.abs();
        }
        if (t.y <= size / 2) {
          t.y = size / 2;
          t.vy = t.vy.abs();
        } else if (t.y >= _playArea.height - size / 2) {
          t.y = _playArea.height - size / 2;
          t.vy = -t.vy.abs();
        }
      }
    });
  }

  void _onTargetHit(int index) {
    if (!_isPlaying) return;
    final now = DateTime.now();
    if (_targetAppearTime != null) {
      _reactionTimes.add(now.difference(_targetAppearTime!).inMilliseconds.toDouble());
    }
    _hits++;
    final level = _kTrackingLevels[_selectedLevelIndex];
    setState(() {
      _targets[index] = _createTarget(level);
      _targetAppearTime = DateTime.now();
    });
  }

  void _onMiss() {
    if (!_isPlaying) return;
    _misses++;
    setState(() {});
  }

  void _finishGame() {
    _isPlaying = false;
    _gameTimer?.cancel();
    _animController.stop();
    setState(() {});
    _saveRecord();
    _showResultDialog();
  }

  void _saveRecord() {
    final accuracy = _calculateAccuracy();
    TrainingRepository.saveRecord(SessionRecord(
      moduleType: TrainingModuleType.tracking,
      difficulty: _selectedLevelIndex + 1,
      score: accuracy * 100,
      metrics: {
        'hits': _hits.toDouble(),
        'misses': _misses.toDouble(),
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
    // 捕获 State 的 context，dialog 关闭后 dialog context 会失效
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
    _animController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('动态目标追踪'),
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
                '${_elapsed.toStringAsFixed(1)}s / ${_gameDurationSeconds.toStringAsFixed(0)}s',
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
                            children: _targets.asMap().entries.map((entry) {
                              final index = entry.key;
                              final target = entry.value;
                              final level = _kTrackingLevels[_selectedLevelIndex];
                              return Positioned(
                                left: target.x - level.targetSize / 2,
                                top: target.y - level.targetSize / 2,
                                child: GestureDetector(
                                  onTap: () => _onTargetHit(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 50),
                                    width: level.targetSize,
                                    height: level.targetSize,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: AppTheme.neuralGradient,
                                      boxShadow: AppTheme.cyanGlow,
                                      border: Border.all(color: AppTheme.starWhite, width: 2),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.adjust,
                                        color: AppTheme.starWhite,
                                        size: level.targetSize * 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
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
        itemCount: _kTrackingLevels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final level = _kTrackingLevels[index];
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
        _buildStat('脱靶', '$_misses'),
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
