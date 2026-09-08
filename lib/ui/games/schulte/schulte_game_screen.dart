import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../../../data/models/session_record.dart';
import '../../../data/repositories/training_repository.dart';

/// 舒尔特方格难度配置
///
/// 对应截图要求：
/// L1: 3×3 升序
/// L2: 4×4 升序
/// L3: 5×5 升序
/// L4: 5×5 降序（2s/格）
/// L5: 5×5 首尾交替（1.5s/格）
/// L6: 6×6 首尾交替（1s/格）
class SchulteLevel {
  final String label;
  final int gridSize;
  final SchulteMode mode;
  final double? timeLimitPerCell; // 秒，null 表示不限时

  const SchulteLevel({
    required this.label,
    required this.gridSize,
    this.mode = SchulteMode.ascending,
    this.timeLimitPerCell,
  });
}

enum SchulteMode {
  ascending,
  descending,
  alternating,
}

extension SchulteModeExt on SchulteMode {
  String get label {
    switch (this) {
      case SchulteMode.ascending:
        return '升序';
      case SchulteMode.descending:
        return '降序';
      case SchulteMode.alternating:
        return '首尾交替';
    }
  }
}

const List<SchulteLevel> _kSchulteLevels = [
  SchulteLevel(label: 'L1', gridSize: 3, mode: SchulteMode.ascending),
  SchulteLevel(label: 'L2', gridSize: 4, mode: SchulteMode.ascending),
  SchulteLevel(label: 'L3', gridSize: 5, mode: SchulteMode.ascending),
  SchulteLevel(label: 'L4', gridSize: 5, mode: SchulteMode.descending, timeLimitPerCell: 2.0),
  SchulteLevel(label: 'L5', gridSize: 5, mode: SchulteMode.alternating, timeLimitPerCell: 1.5),
  SchulteLevel(label: 'L6', gridSize: 6, mode: SchulteMode.alternating, timeLimitPerCell: 1.0),
];

/// 颜色干扰模式的调色板（数字随机着色，制造视觉干扰）
const List<Color> _kColorPalette = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.yellow,
  Colors.purple,
  Colors.orange,
  Colors.cyan,
  Colors.pink,
];

/// 舒尔特方格训练页
class SchulteGameScreen extends StatefulWidget {
  final int gridSize;

  const SchulteGameScreen({super.key, this.gridSize = 5});

  @override
  State<SchulteGameScreen> createState() => _SchulteGameScreenState();
}

class _SchulteGameScreenState extends State<SchulteGameScreen> {
  int _selectedLevelIndex = 2; // 默认 L3
  late int _currentGridSize;
  late List<int> _targetSequence;
  late List<int> _displayNumbers;
  int _currentIndex = 0;
  int _wrongClicks = 0;
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  double _elapsedSeconds = 0;
  bool _isFinished = false;
  final List<double> _correctTimestamps = []; // 记录每次正确点击的秒数
  double? _cellDeadline; // 当前格子的截止时间
  Timer? _countdownTimer;

  // 附加模式
  bool _guideEnabled = false; // 引导模式：高亮下一个目标数字
  bool _colorDistractEnabled = false; // 颜色干扰：数字随机颜色
  late List<Color> _cellColors; // 颜色干扰模式下每个格子的颜色

  @override
  void initState() {
    super.initState();
    _selectedLevelIndex = _kSchulteLevels.indexWhere((l) => l.gridSize == widget.gridSize);
    if (_selectedLevelIndex < 0) _selectedLevelIndex = 2;
    _startGame(_selectedLevelIndex);
  }

  void _startGame(int levelIndex) {
    final level = _kSchulteLevels[levelIndex];
    final rng = Random();
    _selectedLevelIndex = levelIndex;
    _currentGridSize = level.gridSize;

    // 生成目标序列
    switch (level.mode) {
      case SchulteMode.ascending:
        _targetSequence = List.generate(_currentGridSize * _currentGridSize, (i) => i + 1);
      case SchulteMode.descending:
        _targetSequence = List.generate(_currentGridSize * _currentGridSize, (i) => _currentGridSize * _currentGridSize - i);
      case SchulteMode.alternating:
        _targetSequence = _generateAlternatingSequence(_currentGridSize * _currentGridSize);
    }

    // 生成显示数字：目标序列的随机排列
    _displayNumbers = List.of(_targetSequence)..shuffle(rng);

    // 颜色干扰模式：为每个数字分配随机颜色
    _cellColors = List.generate(
      _displayNumbers.length,
      (_) => _kColorPalette[rng.nextInt(_kColorPalette.length)],
    );

    _currentIndex = 0;
    _wrongClicks = 0;
    _correctTimestamps.clear();
    _isFinished = false;
    _elapsedSeconds = 0;
    _stopwatch.reset();
    _stopwatch.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        _elapsedSeconds = _stopwatch.elapsedMilliseconds / 1000.0;
      });
    });

    _cellDeadline = level.timeLimitPerCell == null ? null : level.timeLimitPerCell;
    _countdownTimer?.cancel();
    if (level.timeLimitPerCell != null) {
      _countdownTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (_isFinished) return;
        setState(() {
          _cellDeadline = _cellDeadline! - 0.1;
          if (_cellDeadline! <= 0) {
            _cellDeadline = 0;
            _wrongClicks++;
            _cellDeadline = level.timeLimitPerCell;
          }
        });
      });
    }

    setState(() {});
  }

  List<int> _generateAlternatingSequence(int n) {
    final result = <int>[];
    int left = 1;
    int right = n;
    while (left <= right) {
      result.add(left++);
      if (left <= right) result.add(right--);
    }
    return result;
  }

  void _onCellTap(int number) {
    if (_isFinished) return;
    if (number == _targetSequence[_currentIndex]) {
      _correctTimestamps.add(_elapsedSeconds);
      _currentIndex++;
      final level = _kSchulteLevels[_selectedLevelIndex];
      _cellDeadline = level.timeLimitPerCell;
      if (_currentIndex >= _targetSequence.length) {
        _finishGame();
      } else {
        setState(() {});
      }
    } else {
      _wrongClicks++;
      setState(() {});
    }
  }

  void _finishGame() {
    _stopwatch.stop();
    _timer?.cancel();
    _countdownTimer?.cancel();
    _isFinished = true;
    setState(() {});
    _saveRecord();
    _showResultDialog();
  }

  void _saveRecord() {
    final accuracy = _calculateAccuracy();
    TrainingRepository.saveRecord(SessionRecord(
      moduleType: TrainingModuleType.schulte,
      difficulty: _selectedLevelIndex + 1,
      score: accuracy * 100,
      metrics: {
        'elapsedSeconds': double.parse(_elapsedSeconds.toStringAsFixed(2)),
        'wrongClicks': _wrongClicks.toDouble(),
        'medianPlateTime': double.parse(_calculateMedianPlateTime().toStringAsFixed(2)),
      },
      timestamp: DateTime.now(),
      durationSeconds: _elapsedSeconds.round(),
    ));
  }

  double _calculateMedianPlateTime() {
    if (_correctTimestamps.length < 2) return 0;
    final diffs = <double>[];
    for (int i = 1; i < _correctTimestamps.length; i++) {
      diffs.add(_correctTimestamps[i] - _correctTimestamps[i - 1]);
    }
    diffs.sort();
    final mid = diffs.length ~/ 2;
    if (diffs.length.isOdd) return diffs[mid];
    return (diffs[mid - 1] + diffs[mid]) / 2;
  }

  double _calculateAccuracy() {
    final totalClicks = _currentIndex + _wrongClicks;
    if (totalClicks == 0) return 0;
    return _currentIndex / totalClicks;
  }

  void _showResultDialog() {
    final accuracy = _calculateAccuracy();
    final medianPlate = _calculateMedianPlateTime();
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
            _buildResultRow('完成时间', '${_elapsedSeconds.toStringAsFixed(2)}s'),
            _buildResultRow('错误点击', '$_wrongClicks 次'),
            _buildResultRow('准确率', '${(accuracy * 100).toStringAsFixed(1)}%'),
            _buildResultRow('中位盘时', '${medianPlate.toStringAsFixed(2)}s'),
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
    _timer?.cancel();
    _countdownTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final level = _kSchulteLevels[_selectedLevelIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('舒尔特方格 ${level.label}'),
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
                '${_elapsedSeconds.toStringAsFixed(1)}s',
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
                const SizedBox(height: 8),
                _buildModeSelector(),
                const SizedBox(height: 8),
                _buildStatsBar(),
                if (level.timeLimitPerCell != null) _buildCountdownBar(level),
                const SizedBox(height: 16),
                Expanded(child: _buildGrid()),
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
        itemCount: _kSchulteLevels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final level = _kSchulteLevels[index];
          final isSelected = index == _selectedLevelIndex;
          return ChoiceChip(
            label: Text(
              '${level.label} ${level.gridSize}×${level.gridSize} ${level.mode.label}',
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

  Widget _buildModeSelector() {
    return Row(
      children: [
        _buildModeChip(
          '引导模式',
          '高亮下一个数字',
          Icons.lightbulb_outline,
          _guideEnabled,
          (v) => setState(() => _guideEnabled = v),
        ),
        const SizedBox(width: 8),
        _buildModeChip(
          '颜色干扰',
          '数字随机着色',
          Icons.palette_outlined,
          _colorDistractEnabled,
          (v) => setState(() => _colorDistractEnabled = v),
        ),
      ],
    );
  }

  Widget _buildModeChip(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: value ? AppTheme.neonCyan.withValues(alpha: 0.15) : AppTheme.panelNavy,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: value ? AppTheme.neonCyan : AppTheme.nebulaGray.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: value ? AppTheme.neonCyan : AppTheme.nebulaGray, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: value ? AppTheme.neonCyan : AppTheme.starWhite,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(subtitle, style: context.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    final accuracy = _calculateAccuracy();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStat('进度', '$_currentIndex/${_targetSequence.length}'),
        _buildStat('错误', '$_wrongClicks'),
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

  Widget _buildCountdownBar(SchulteLevel level) {
    final max = level.timeLimitPerCell!;
    final ratio = (_cellDeadline ?? max) / max;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: LinearProgressIndicator(
        value: ratio.clamp(0, 1),
        backgroundColor: AppTheme.panelNavy,
        valueColor: AlwaysStoppedAnimation(
          ratio < 0.3 ? AppTheme.alertRed : AppTheme.amberPulse,
        ),
        minHeight: 8,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildGrid() {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _currentGridSize,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _displayNumbers.length,
        itemBuilder: (context, index) {
          final number = _displayNumbers[index];
          final isDone = _targetSequence.indexOf(number) < _currentIndex;
          final isGuided = _guideEnabled &&
              !_isFinished &&
              number == _targetSequence[_currentIndex];
          return _buildCell(number, isDone, index, isGuided);
        },
      ),
    );
  }

  Widget _buildCell(int number, bool isDone, int index, bool isGuided) {
    final digitColor = _colorDistractEnabled && !isDone
        ? _cellColors[index]
        : (isDone ? AppTheme.successGreen : AppTheme.starWhite);

    final borderColor = isDone
        ? AppTheme.successGreen
        : isGuided
            ? AppTheme.amberPulse
            : AppTheme.neonCyan.withValues(alpha: 0.3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isDone ? AppTheme.successGreen.withValues(alpha: 0.2) : AppTheme.panelNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isGuided ? 3 : 1.5,
        ),
        boxShadow: isGuided
            ? [
                BoxShadow(
                  color: AppTheme.amberPulse.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : (isDone ? null : AppTheme.cardShadow),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDone ? null : () => _onCellTap(number),
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: Text(
              '$number',
              style: GoogleFonts.notoSansSc(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: digitColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
