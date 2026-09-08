import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/models/session_record.dart';
import '../../../data/repositories/training_repository.dart';

/// 节奏分离难度配置
/// 左右节拍比 + 周期（毫秒）
class RhythmLevel {
  final String label;
  final int leftBeats;
  final int rightBeats;
  final int leftPeriodMs;
  final int rightPeriodMs;
  final int tolerance; // 允许的计数误差

  const RhythmLevel({
    required this.label,
    required this.leftBeats,
    required this.rightBeats,
    required this.leftPeriodMs,
    required this.rightPeriodMs,
    this.tolerance = 1,
  });
}

const List<RhythmLevel> _kRhythmLevels = [
  RhythmLevel(label: 'L1', leftBeats: 1, rightBeats: 1, leftPeriodMs: 667, rightPeriodMs: 667, tolerance: 1),
  RhythmLevel(label: 'L2', leftBeats: 2, rightBeats: 1, leftPeriodMs: 800, rightPeriodMs: 400, tolerance: 1),
  RhythmLevel(label: 'L3', leftBeats: 3, rightBeats: 2, leftPeriodMs: 533, rightPeriodMs: 800, tolerance: 1),
  RhythmLevel(label: 'L4', leftBeats: 3, rightBeats: 1, leftPeriodMs: 857, rightPeriodMs: 286, tolerance: 1),
  RhythmLevel(label: 'L5', leftBeats: 4, rightBeats: 3, leftPeriodMs: 643, rightPeriodMs: 857, tolerance: 1),
  RhythmLevel(label: 'L6', leftBeats: 3, rightBeats: 2, leftPeriodMs: 500, rightPeriodMs: 667, tolerance: 0),
];

class _TrialResult {
  final bool correct;
  final int leftError;
  final int rightError;

  _TrialResult({required this.correct, required this.leftError, required this.rightError});
}

/// 节奏分离训练页
/// 当前使用视觉闪烁模拟左右节拍，P3/P5 可替换为 audioplayers 音频节拍
class RhythmGameScreen extends StatefulWidget {
  const RhythmGameScreen({super.key});

  @override
  State<RhythmGameScreen> createState() => _RhythmGameScreenState();
}

class _RhythmGameScreenState extends State<RhythmGameScreen> {
  int _selectedLevelIndex = 0;
  final Random _rng = Random();
  int _currentTrial = 0;
  final int _totalTrials = 20;
  bool _isPlaying = false;
  bool _isAnswering = false;
  int _leftActual = 0;
  int _rightActual = 0;
  int _leftInput = 0;
  int _rightInput = 0;
  Timer? _leftTimer;
  Timer? _rightTimer;
  Timer? _stopTimer;
  bool _leftFlash = false;
  bool _rightFlash = false;
  final List<_TrialResult> _results = [];
  int _leftFlashCount = 0;
  int _rightFlashCount = 0;

  @override
  void initState() {
    super.initState();
    _startGame(0);
  }

  void _startGame(int levelIndex) {
    _selectedLevelIndex = levelIndex;
    _currentTrial = 0;
    _results.clear();
    _isPlaying = false;
    _isAnswering = false;
    _stopAllTimers();
    _nextTrial();
    setState(() {});
  }

  void _stopAllTimers() {
    _leftTimer?.cancel();
    _rightTimer?.cancel();
    _stopTimer?.cancel();
  }

  void _nextTrial() {
    if (_currentTrial >= _totalTrials) {
      _finishGame();
      return;
    }
    _currentTrial++;
    _leftInput = 0;
    _rightInput = 0;
    _isPlaying = true;
    _isAnswering = false;
    _leftFlash = false;
    _rightFlash = false;
    _leftFlashCount = 0;
    _rightFlashCount = 0;

    final level = _kRhythmLevels[_selectedLevelIndex];

    // 随机生成实际节拍数，保持与难度比例大致一致但略有变化
    final base = _rng.nextInt(4) + 4; // 4~7
    _leftActual = (base * level.leftBeats / (level.leftBeats + level.rightBeats)).round().clamp(2, 12);
    _rightActual = base - _leftActual;

    // 总时长：按较慢的一边计算，确保能完整播放
    final leftDuration = _leftActual * level.leftPeriodMs;
    final rightDuration = _rightActual * level.rightPeriodMs;
    final totalDuration = max(leftDuration, rightDuration) + 500;

    // 左右两路各自按节奏闪烁，用计数精确限制为 _leftActual / _rightActual 次，
    // 保证“用户看到的闪烁数”与“判定答案”严格一致（此前会多出一次而判错）。
    var leftCount = 0;
    _leftTimer = Timer.periodic(Duration(milliseconds: level.leftPeriodMs), (t) {
      if (leftCount >= _leftActual) {
        t.cancel();
        return;
      }
      setState(() {
        _leftFlash = true;
        _leftFlashCount++;
      });
      leftCount++;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _leftFlash = false);
      });
    });

    var rightCount = 0;
    _rightTimer = Timer.periodic(Duration(milliseconds: level.rightPeriodMs), (t) {
      if (rightCount >= _rightActual) {
        t.cancel();
        return;
      }
      setState(() {
        _rightFlash = true;
        _rightFlashCount++;
      });
      rightCount++;
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _rightFlash = false);
      });
    });

    _stopTimer = Timer(Duration(milliseconds: totalDuration), () {
      _stopAllTimers();
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _isAnswering = true;
        });
      }
    });

    setState(() {});
  }

  void _submitAnswer() {
    if (!_isAnswering) return;
    final level = _kRhythmLevels[_selectedLevelIndex];
    final leftError = (_leftInput - _leftActual).abs();
    final rightError = (_rightInput - _rightActual).abs();
    final correct = leftError <= level.tolerance && rightError <= level.tolerance;

    _results.add(_TrialResult(
      correct: correct,
      leftError: leftError,
      rightError: rightError,
    ));

    setState(() {
      _isAnswering = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.panelNavy,
        title: Text(correct ? '正确' : '错误', style: Theme.of(dialogContext).textTheme.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('左侧实际', '$_leftActual'),
            _buildResultRow('你的答案', '$_leftInput'),
            _buildResultRow('右侧实际', '$_rightActual'),
            _buildResultRow('你的答案', '$_rightInput'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _nextTrial();
            },
            child: const Text('下一题'),
          ),
        ],
      ),
    );
  }

  double _calculateAccuracy() {
    if (_results.isEmpty) return 0;
    final correct = _results.where((r) => r.correct).length;
    return correct / _results.length;
  }

  double _calculateMedianBeatError() {
    final errors = _results.map((r) => (r.leftError + r.rightError).toDouble()).toList();
    if (errors.isEmpty) return 0;
    errors.sort();
    final mid = errors.length ~/ 2;
    if (errors.length.isOdd) return errors[mid];
    return (errors[mid - 1] + errors[mid]) / 2;
  }

  void _finishGame() {
    _stopAllTimers();
    setState(() {});
    _saveRecord();
    _showFinalResultDialog();
  }

  void _saveRecord() {
    final accuracy = _calculateAccuracy();
    TrainingRepository.saveRecord(SessionRecord(
      moduleType: TrainingModuleType.rhythm,
      difficulty: _selectedLevelIndex + 1,
      score: accuracy * 100,
      metrics: {
        'medianBeatError': double.parse(_calculateMedianBeatError().toStringAsFixed(1)),
      },
      timestamp: DateTime.now(),
      durationSeconds: _totalTrials * 8,
    ));
  }

  void _showFinalResultDialog() {
    final accuracy = _calculateAccuracy();
    final medianError = _calculateMedianBeatError();
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
            _buildResultRow('准确率', '${(accuracy * 100).toStringAsFixed(1)}%'),
            _buildResultRow('节拍误差中位数', '${medianError.toStringAsFixed(1)} 拍'),
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
    _stopAllTimers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = _calculateAccuracy();
    return Scaffold(
      appBar: AppBar(
        title: const Text('节奏分离'),
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
                '$_currentTrial/$_totalTrials',
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
                _buildStatsBar(accuracy),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildRhythmZone(
                          label: '左侧节奏',
                          flash: _leftFlash,
                          color: AppTheme.neonCyan,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRhythmZone(
                          label: '右侧节奏',
                          flash: _rightFlash,
                          color: AppTheme.violetNeural,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isAnswering) _buildAnswerPanel(),
                if (!_isPlaying && !_isAnswering && _currentTrial < _totalTrials)
                  ElevatedButton(
                    onPressed: () => _nextTrial(),
                    child: const Text('开始'),
                  ),
                const SizedBox(height: 16),
                Text(
                  '左右区域会按不同节奏闪烁，结束后分别输入左右闪烁次数',
                  style: context.textTheme.bodySmall,
                  textAlign: TextAlign.center,
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
        itemCount: _kRhythmLevels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final level = _kRhythmLevels[index];
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

  Widget _buildStatsBar(double accuracy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat('准确率', '${(accuracy * 100).toStringAsFixed(0)}%'),
        _buildStat('左节拍', '$_leftFlashCount'),
        _buildStat('右节拍', '$_rightFlashCount'),
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

  Widget _buildRhythmZone({required String label, required bool flash, required Color color}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            flash ? color : color.withValues(alpha: 0.15),
            AppTheme.panelNavy,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: flash ? color : color.withValues(alpha: 0.3),
          width: flash ? 3 : 1.5,
        ),
        boxShadow: flash
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: context.textTheme.titleLarge?.copyWith(
            color: flash ? AppTheme.starWhite : color,
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('输入你看到的闪烁次数', style: context.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCounter('左侧', _leftInput, (delta) {
                  setState(() => _leftInput = (_leftInput + delta).clamp(0, 99));
                }),
                const SizedBox(width: 32),
                _buildCounter('右侧', _rightInput, (delta) {
                  setState(() => _rightInput = (_rightInput + delta).clamp(0, 99));
                }),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitAnswer,
                child: const Text('提交'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int value, void Function(int) onChanged) {
    return Column(
      children: [
        Text(label, style: context.textTheme.bodyMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () => onChanged(-1),
              icon: const Icon(Icons.remove, color: AppTheme.neonCyan),
            ),
            Container(
              width: 48,
              alignment: Alignment.center,
              child: Text('$value', style: context.textTheme.headlineSmall),
            ),
            IconButton(
              onPressed: () => onChanged(1),
              icon: const Icon(Icons.add, color: AppTheme.neonCyan),
            ),
          ],
        ),
      ],
    );
  }
}
