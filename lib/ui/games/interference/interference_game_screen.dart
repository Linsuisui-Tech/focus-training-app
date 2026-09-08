import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/models/session_record.dart';
import '../../../data/repositories/training_repository.dart';

/// Stroop 颜色条目：名称 + 实际颜色
class _StroopColor {
  final String name;
  final Color color;

  const _StroopColor({required this.name, required this.color});
}

const List<_StroopColor> _kColors = [
  _StroopColor(name: '红', color: Colors.red),
  _StroopColor(name: '蓝', color: Colors.blue),
  _StroopColor(name: '绿', color: Colors.green),
  _StroopColor(name: '黄', color: Colors.yellow),
  _StroopColor(name: '紫', color: Colors.purple),
  _StroopColor(name: '橙', color: Colors.orange),
];

/// 抗干扰识别难度配置
class InterferenceLevel {
  final String label;
  final double congruentRatio; // 一致试次占比
  final double timeLimitMs; // 反应时限

  const InterferenceLevel({
    required this.label,
    required this.congruentRatio,
    required this.timeLimitMs,
  });
}

const List<InterferenceLevel> _kInterferenceLevels = [
  InterferenceLevel(label: 'L1', congruentRatio: 0.70, timeLimitMs: 2000),
  InterferenceLevel(label: 'L2', congruentRatio: 0.50, timeLimitMs: 1800),
  InterferenceLevel(label: 'L3', congruentRatio: 0.40, timeLimitMs: 1600),
  InterferenceLevel(label: 'L4', congruentRatio: 0.30, timeLimitMs: 1400),
  InterferenceLevel(label: 'L5', congruentRatio: 0.25, timeLimitMs: 1200),
  InterferenceLevel(label: 'L6', congruentRatio: 0.20, timeLimitMs: 1000),
];

class _TrialResult {
  final bool congruent;
  final bool correct;
  final double reactionTimeMs;

  _TrialResult({required this.congruent, required this.correct, required this.reactionTimeMs});
}

/// 抗干扰识别训练页（Stroop 变体）
class InterferenceGameScreen extends StatefulWidget {
  const InterferenceGameScreen({super.key});

  @override
  State<InterferenceGameScreen> createState() => _InterferenceGameScreenState();
}

class _InterferenceGameScreenState extends State<InterferenceGameScreen> {
  int _selectedLevelIndex = 0;
  final Random _rng = Random();
  int _currentTrial = 0;
  final int _totalTrials = 30;
  _StroopColor? _currentWord;
  _StroopColor? _currentInk;
  bool? _isCongruent;
  final List<_TrialResult> _results = [];
  DateTime? _trialStartTime;
  Timer? _countdownTimer;
  double _remainingMs = 0;
  bool _isPlaying = false;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _startGame(0);
  }

  void _startGame(int levelIndex) {
    _selectedLevelIndex = levelIndex;
    _currentTrial = 0;
    _results.clear();
    _feedback = null;
    _isPlaying = true;
    _countdownTimer?.cancel();
    _nextTrial();
    setState(() {});
  }

  void _nextTrial() {
    if (_currentTrial >= _totalTrials) {
      _finishGame();
      return;
    }
    _currentTrial++;
    final level = _kInterferenceLevels[_selectedLevelIndex];
    _isCongruent = _rng.nextDouble() < level.congruentRatio;

    if (_isCongruent!) {
      // 一致：字义和颜色相同
      final color = _kColors[_rng.nextInt(_kColors.length)];
      _currentWord = color;
      _currentInk = color;
    } else {
      // 不一致：字义和颜色不同
      final wordIndex = _rng.nextInt(_kColors.length);
      int inkIndex = _rng.nextInt(_kColors.length);
      while (inkIndex == wordIndex) {
        inkIndex = _rng.nextInt(_kColors.length);
      }
      _currentWord = _kColors[wordIndex];
      _currentInk = _kColors[inkIndex];
    }

    _trialStartTime = DateTime.now();
    _remainingMs = level.timeLimitMs;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _remainingMs -= 50;
        if (_remainingMs <= 0) {
          _remainingMs = 0;
          _countdownTimer?.cancel();
          _handleTimeout();
        }
      });
    });
    setState(() {});
  }

  void _handleTimeout() {
    if (!_isPlaying) return;
    _results.add(_TrialResult(
      congruent: _isCongruent!,
      correct: false,
      reactionTimeMs: _kInterferenceLevels[_selectedLevelIndex].timeLimitMs,
    ));
    _feedback = '超时';
    _nextTrialWithDelay();
  }

  void _onColorSelected(_StroopColor selected) {
    if (!_isPlaying || _trialStartTime == null) return;
    _countdownTimer?.cancel();
    final now = DateTime.now();
    final reaction = now.difference(_trialStartTime!).inMilliseconds.toDouble();
    final correct = selected.name == _currentInk!.name;

    _results.add(_TrialResult(
      congruent: _isCongruent!,
      correct: correct,
      reactionTimeMs: reaction,
    ));

    _feedback = correct ? '正确' : '错误';
    _nextTrialWithDelay();
  }

  void _nextTrialWithDelay() {
    setState(() {});
    Future.delayed(const Duration(milliseconds: 400), () {
      _feedback = null;
      _nextTrial();
    });
  }

  void _finishGame() {
    _isPlaying = false;
    _countdownTimer?.cancel();
    setState(() {});
    _saveRecord();
    _showResultDialog();
  }

  void _saveRecord() {
    final accuracy = _calculateAccuracy();
    TrainingRepository.saveRecord(SessionRecord(
      moduleType: TrainingModuleType.interference,
      difficulty: _selectedLevelIndex + 1,
      score: accuracy * 100,
      metrics: {
        'medianReactionTime': double.parse(_calculateMedianReactionTime().toStringAsFixed(0)),
        'conflictCost': double.parse(_calculateConflictCost().toStringAsFixed(0)),
      },
      timestamp: DateTime.now(),
      durationSeconds: _totalTrials * 3,
    ));
  }

  double _calculateAccuracy() {
    if (_results.isEmpty) return 0;
    final correct = _results.where((r) => r.correct).length;
    return correct / _results.length;
  }

  double _calculateMedianReactionTime({bool congruentOnly = false}) {
    final times = _results
        .where((r) => congruentOnly ? r.congruent : true)
        .where((r) => r.correct)
        .map((r) => r.reactionTimeMs)
        .toList();
    if (times.isEmpty) return 0;
    times.sort();
    final mid = times.length ~/ 2;
    if (times.length.isOdd) return times[mid];
    return (times[mid - 1] + times[mid]) / 2;
  }

  double _calculateConflictCost() {
    final congruent = _calculateMedianReactionTime(congruentOnly: true);
    final incongruent = _results
        .where((r) => !r.congruent && r.correct)
        .map((r) => r.reactionTimeMs)
        .toList();
    if (incongruent.isEmpty || congruent == 0) return 0;
    incongruent.sort();
    final mid = incongruent.length ~/ 2;
    final incongruentMedian = incongruent.length.isOdd ? incongruent[mid] : (incongruent[mid - 1] + incongruent[mid]) / 2;
    return incongruentMedian - congruent;
  }

  void _showResultDialog() {
    final accuracy = _calculateAccuracy();
    final median = _calculateMedianReactionTime();
    final conflict = _calculateConflictCost();
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
            _buildResultRow('正确反应中位数', '${median.toStringAsFixed(0)}ms'),
            _buildResultRow('不一致冲突耗时', '${conflict.toStringAsFixed(0)}ms'),
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
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = _kInterferenceLevels[_selectedLevelIndex];
    final ratio = _remainingMs / level.timeLimitMs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('抗干扰识别'),
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
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: ratio.clamp(0, 1),
                  backgroundColor: AppTheme.panelNavy,
                  valueColor: AlwaysStoppedAnimation(
                    ratio < 0.3 ? AppTheme.alertRed : AppTheme.amberPulse,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentWord != null)
                          Text(
                            _currentWord!.name,
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              color: _currentInk!.color,
                              shadows: [
                                Shadow(
                                  color: _currentInk!.color.withValues(alpha: 0.6),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                        if (_feedback != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: Text(
                              _feedback!,
                              style: context.textTheme.headlineMedium?.copyWith(
                                color: _feedback == '正确' ? AppTheme.successGreen : AppTheme.alertRed,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildColorButtons(),
                const SizedBox(height: 16),
                Text(
                  '选择字的颜色，不要读字',
                  style: context.textTheme.bodySmall,
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
        itemCount: _kInterferenceLevels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final level = _kInterferenceLevels[index];
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

  Widget _buildColorButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: _kColors.map((color) {
        return ElevatedButton(
          onPressed: _feedback == null ? () => _onColorSelected(color) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.color,
            foregroundColor: Colors.white,
            minimumSize: const Size(80, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(color.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        );
      }).toList(),
    );
  }
}
