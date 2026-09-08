import 'dart:ffi';
import 'dart:io' show File;import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/services.dart' show rootBundle, SystemSound, SystemSoundType;
import 'package:path_provider/path_provider.dart';

/// 音频服务：播放短音效
///
/// Windows 端用 FFI 调用 winmm.dll 的 PlaySoundA 播放本地 WAV 文件，
/// 比 Beep 蜂鸣更接近真实音效，且不依赖 audioplayers（避免 nuget 构建问题）。
/// 其他平台（Android/iOS）用 SystemSound 系统提示音兜底。
class AudioService {
  AudioService._();

  // PlaySound 标志位
  static const int _sndAsync = 0x0001; // 异步播放
  static const int _sndFilename = 0x00020000; // 播放文件
  static const int _sndNoDefault = 0x0002; // 找不到时不播默认音

  static int Function(Pointer<Utf8>, Pointer<Void>, int)? _playSoundA;
  static bool _initTried = false;
  static String? _cachedWavPath;

  static void _init() {
    if (_initTried) return;
    _initTried = true;
    if (defaultTargetPlatform != TargetPlatform.windows) return;
    try {
      final winmm = DynamicLibrary.open('winmm.dll');
      _playSoundA = winmm.lookupFunction<
          Int32 Function(Pointer<Utf8>, Pointer<Void>, Uint32),
          int Function(Pointer<Utf8>, Pointer<Void>, int)>('PlaySoundA');
    } catch (_) {
      _playSoundA = null;
    }
  }

  /// 把 WAV 资源从 asset 解压到临时目录，返回文件路径（缓存）
  static Future<String?> _getWavPath() async {
    if (_cachedWavPath != null) return _cachedWavPath;
    try {
      final data = await rootBundle.load('assets/audio/tick.wav');
      final bytes = data.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tick.wav');
      await file.writeAsBytes(bytes);
      _cachedWavPath = file.path;
      return _cachedWavPath;
    } catch (_) {
      return null;
    }
  }

  /// 播放一声短促的"哒"声（节拍器 / 点击反馈用）
  static Future<void> playTick() async {
    _init();
    final playSound = _playSoundA;
    if (playSound != null) {
      final path = await _getWavPath();
      if (path != null) {
        final pathPtr = path.toNativeUtf8();
        try {
          playSound(pathPtr, nullptr, _sndAsync | _sndFilename | _sndNoDefault);
        } catch (_) {
          // PlaySound 失败，回退到系统提示音
        } finally {
          malloc.free(pathPtr);
          return;
        }
      }
    }
    await SystemSound.play(SystemSoundType.click);
  }
}
