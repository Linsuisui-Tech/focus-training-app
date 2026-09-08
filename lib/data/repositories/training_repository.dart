import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/session_record.dart';

/// 训练记录存储仓库
///
/// 用 SharedPreferences 存 JSON 字符串（训练记录量小，无需重型数据库）。
/// 提供记录保存、读取、统计聚合能力。
class TrainingRepository {
  TrainingRepository._();

  static const String _recordsKey = 'training_records';

  /// 保存一条训练记录（追加到列表末尾）
  static Future<void> saveRecord(SessionRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getRecords();
    records.add(record);
    await prefs.setString(
      _recordsKey,
      jsonEncode(records.map((r) => r.toJson()).toList()),
    );
  }

  /// 读取全部训练记录（按时间倒序）
  static Future<List<SessionRecord>> getRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recordsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (_) {
      return [];
    }
  }

  /// 获取某个能力维度的平均得分（0-100）
  static Future<Map<AbilityDimension, double>> getAbilityAverages() async {
    final records = await getRecords();
    final sums = <AbilityDimension, double>{};
    final counts = <AbilityDimension, int>{};

    for (final r in records) {
      final dim = abilityDimensionFor(r.moduleType);
      sums[dim] = (sums[dim] ?? 0) + r.score;
      counts[dim] = (counts[dim] ?? 0) + 1;
    }

    final result = <AbilityDimension, double>{};
    for (final dim in AbilityDimension.values) {
      final count = counts[dim] ?? 0;
      result[dim] = count == 0 ? 0 : (sums[dim]! / count);
    }
    return result;
  }

  /// 获取某个能力维度的最高分（用于排行榜）
  static Future<Map<AbilityDimension, double>> getAbilityBests() async {
    final records = await getRecords();
    final bests = <AbilityDimension, double>{};

    for (final r in records) {
      final dim = abilityDimensionFor(r.moduleType);
      if (r.score > (bests[dim] ?? 0)) {
        bests[dim] = r.score;
      }
    }
    return bests;
  }

  /// 统计汇总：总次数、总时长、连续训练天数
  static Future<Map<String, dynamic>> getSummary() async {
    final records = await getRecords();
    final totalCount = records.length;
    final totalSeconds = records.fold<int>(0, (sum, r) => sum + r.durationSeconds);

    // 连续训练天数（从今天往前数）
    final days = records.map((r) {
      final d = r.timestamp;
      return DateTime(d.year, d.month, d.day);
    }).toSet();

    int streak = 0;
    var cursor = DateTime.now();
    final today = DateTime(cursor.year, cursor.month, cursor.day);
    cursor = today;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return {
      'totalCount': totalCount,
      'totalSeconds': totalSeconds,
      'streak': streak,
      'activeDays': days.length,
    };
  }

  /// 清除全部训练记录
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recordsKey);
  }
}
