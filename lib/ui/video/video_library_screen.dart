import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/audio_service.dart';

/// 专注动画类型
enum FocusAnimationType {
  breathing,
  metronome,
  particles,
  ripple,
}

extension FocusAnimationTypeExt on FocusAnimationType {
  String get title {
    switch (this) {
      case FocusAnimationType.breathing:
        return '呼吸圆环';
      case FocusAnimationType.metronome:
        return '节拍器';
      case FocusAnimationType.particles:
        return '粒子漂流';
      case FocusAnimationType.ripple:
        return '光轨扩散';
    }
  }

  String get subtitle {
    switch (this) {
      case FocusAnimationType.breathing:
        return '跟随节奏吸气呼气，放松身心';
      case FocusAnimationType.metronome:
        return '视觉节拍，训练节奏感';
      case FocusAnimationType.particles:
        return '漂浮粒子，放空思绪';
      case FocusAnimationType.ripple:
        return '扩散涟漪，引导凝视';
    }
  }

  IconData get icon {
    switch (this) {
      case FocusAnimationType.breathing:
        return Icons.air;
      case FocusAnimationType.metronome:
        return Icons.graphic_eq;
      case FocusAnimationType.particles:
        return Icons.blur_on;
      case FocusAnimationType.ripple:
        return Icons.radio_button_unchecked;
    }
  }

  Color get color {
    switch (this) {
      case FocusAnimationType.breathing:
        return AppTheme.successGreen;
      case FocusAnimationType.metronome:
        return AppTheme.amberPulse;
      case FocusAnimationType.particles:
        return AppTheme.neonCyan;
      case FocusAnimationType.ripple:
        return AppTheme.violetNeural;
    }
  }
}

/// 专注力训练视频库：程序化交互动画，无外部视频文件依赖
class VideoLibraryScreen extends StatelessWidget {
  const VideoLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('专注视频库')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: FocusAnimationType.values.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final type = FocusAnimationType.values[index];
            return Card(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FocusAnimationPlayerScreen(type: type),
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type.icon, color: type.color, size: 48),
                      const SizedBox(height: 16),
                      Text(type.title, style: context.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(
                        type.subtitle,
                        style: context.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 专注动画播放页
class FocusAnimationPlayerScreen extends StatefulWidget {
  final FocusAnimationType type;

  const FocusAnimationPlayerScreen({super.key, required this.type});

  @override
  State<FocusAnimationPlayerScreen> createState() => _FocusAnimationPlayerScreenState();
}

class _FocusAnimationPlayerScreenState extends State<FocusAnimationPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPlaying = true;
  double _speed = 1.0;

  // 节拍器专用状态
  Timer? _metronomeTimer;
  bool _isBeat = false;

  /// 节拍器 BPM：1x = 60 BPM（每秒 1 拍），0.5x~2x 对应 30~120 BPM
  double get _bpm => 60.0 * _speed;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
    if (widget.type == FocusAnimationType.metronome) {
      _startMetronome();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _metronomeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// 节拍器：按 BPM 周期闪烁并播放提示音
  void _startMetronome() {
    _metronomeTimer?.cancel();
    final intervalMs = (60000 / _bpm).round();
    _metronomeTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      setState(() => _isBeat = true);
      AudioService.playTick();
      Future.delayed(const Duration(milliseconds: 90), () {
        if (mounted) setState(() => _isBeat = false);
      });
    });
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
    _isBeat = false;
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (widget.type == FocusAnimationType.metronome) {
        if (_isPlaying) {
          _startMetronome();
        } else {
          _stopMetronome();
        }
      } else {
        if (_isPlaying) {
          _controller.repeat();
        } else {
          _controller.stop();
        }
      }
    });
  }

  void _adjustSpeed(double delta) {
    setState(() {
      _speed = (_speed + delta).clamp(0.5, 2.0);
      if (widget.type == FocusAnimationType.metronome) {
        if (_isPlaying) _startMetronome();
      } else {
        _controller.stop();
        _controller.duration = Duration(milliseconds: (8000 / _speed).round());
        if (_isPlaying) _controller.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMetronome = widget.type == FocusAnimationType.metronome;
    return Scaffold(
      backgroundColor: AppTheme.spaceBlack,
      appBar: AppBar(
        title: Text(widget.type.title),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: isMetronome
                  ? _buildMetronome(context)
                  : AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => _buildAnimation(context),
                    ),
            ),
          ),
          _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildAnimation(BuildContext context) {
    switch (widget.type) {
      case FocusAnimationType.breathing:
        return _buildBreathing(context);
      case FocusAnimationType.metronome:
        return _buildMetronome(context);
      case FocusAnimationType.particles:
        return _buildParticles(context);
      case FocusAnimationType.ripple:
        return _buildRipple(context);
    }
  }

  Widget _buildBreathing(BuildContext context) {
    // 用正弦曲线模拟呼吸：0→1 膨胀，1→0 收缩
    final t = _controller.value;
    final phase = sin(t * 2 * pi);
    final scale = 0.5 + (phase + 1) / 2 * 0.5; // 0.5 ~ 1.0
    return CustomPaint(
      size: const Size(240, 240),
      painter: _BreathingPainter(scale, widget.type.color),
    );
  }

  Widget _buildMetronome(BuildContext context) {
    // 节拍器：用 _isBeat 状态驱动（由 Timer 控制），与动画 controller 解耦
    return AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isBeat
            ? widget.type.color.withValues(alpha: 0.9)
            : widget.type.color.withValues(alpha: 0.1),
        boxShadow: _isBeat
            ? [
                BoxShadow(
                  color: widget.type.color.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_bpm.round()}',
              style: const TextStyle(color: AppTheme.spaceBlack, fontWeight: FontWeight.w900, fontSize: 44),
            ),
            Text(
              'BPM',
              style: TextStyle(color: AppTheme.spaceBlack.withValues(alpha: 0.7), fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticles(BuildContext context) {
    return CustomPaint(
      size: const Size(280, 280),
      painter: _ParticlesPainter(_controller.value, widget.type.color),
    );
  }

  Widget _buildRipple(BuildContext context) {
    return CustomPaint(
      size: const Size(240, 240),
      painter: _RipplePainter(_controller.value, widget.type.color),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _adjustSpeed(-0.25),
                icon: const Icon(Icons.remove_circle, color: AppTheme.neonCyan),
                iconSize: 44,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.panelNavy,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.neonCyan, width: 1.5),
                ),
                child: Text(
                  '${_speed.toStringAsFixed(2)}x',
                  style: context.textTheme.titleLarge?.copyWith(color: AppTheme.neonCyan),
                ),
              ),
              IconButton(
                onPressed: () => _adjustSpeed(0.25),
                icon: const Icon(Icons.add_circle, color: AppTheme.neonCyan),
                iconSize: 44,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: _togglePlay,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              label: Text(_isPlaying ? '暂停' : '播放'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 呼吸圆环画笔
class _BreathingPainter extends CustomPainter {
  final double scale;
  final Color color;

  _BreathingPainter(this.scale, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 * 0.9;

    // 外圈光晕
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius, glowPaint);

    // 主圆环（随呼吸缩放）
    final ringRadius = maxRadius * scale;
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, ringRadius, ringPaint);

    // 中心填充
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, ringRadius * 0.6, fillPaint);
  }

  @override
  bool shouldRepaint(_BreathingPainter oldDelegate) =>
      oldDelegate.scale != scale || oldDelegate.color != color;
}

/// 粒子画笔
class _ParticlesPainter extends CustomPainter {
  final double t;
  final Color color;

  // 粒子参数只生成一次（static），避免每帧重复随机计算
  static final List<_Particle> _particles = _generateParticles();

  _ParticlesPainter(this.t, this.color);

  static List<_Particle> _generateParticles() {
    final rng = Random(42);
    return List.generate(40, (_) {
      return _Particle(
        baseAngle: rng.nextDouble() * 2 * pi,
        orbitRadius: 30 + rng.nextDouble() * 100,
        speed: rng.nextDouble() * 0.5 + 0.2,
        radius: 2 + rng.nextDouble() * 4,
        opacity: 0.3 + rng.nextDouble() * 0.6,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in _particles) {
      final orbitAngle = p.baseAngle + t * 2 * pi * p.speed;
      final dx = center.dx + cos(orbitAngle) * p.orbitRadius;
      final dy = center.dy + sin(orbitAngle) * p.orbitRadius * 0.7;

      final paint = Paint()
        ..color = color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dx, dy), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) => oldDelegate.t != t;
}

class _Particle {
  final double baseAngle;
  final double orbitRadius;
  final double speed;
  final double radius;
  final double opacity;

  const _Particle({
    required this.baseAngle,
    required this.orbitRadius,
    required this.speed,
    required this.radius,
    required this.opacity,
  });
}

/// 涟漪画笔
class _RipplePainter extends CustomPainter {
  final double t;
  final Color color;

  _RipplePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 三层涟漪，相位错开
    for (int i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final radius = maxRadius * phase;
      final opacity = (1.0 - phase) * 0.6;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(center, radius, paint);
    }

    // 中心光点
    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, centerPaint);
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) => oldDelegate.t != t;
}
