import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

/// 设置页：所有开关都会真正生效并写入本地存储
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _gunSoundEnabled = false;
  bool _cloudSyncEnabled = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _soundEnabled = prefs.getBool(AppConstants.prefSoundEnabled) ?? true;
      _vibrationEnabled = prefs.getBool(AppConstants.prefVibrationEnabled) ?? true;
      _gunSoundEnabled = prefs.getBool(AppConstants.prefGunSoundEnabled) ?? false;
      _cloudSyncEnabled = prefs.getBool(AppConstants.prefCloudSyncEnabled) ?? false;
      _loaded = true;
    });
  }

  Future<void> _setBool(String key, bool value, void Function(bool) apply) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (!mounted) return;
    setState(() => apply(value));
  }

  Future<void> _confirmClearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.panelNavy,
        title: const Text('清除本地数据？'),
        content: const Text('所有训练记录、自定义计划与偏好设置都会被重置，且不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.alertRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    setState(() {
      _soundEnabled = true;
      _vibrationEnabled = true;
      _gunSoundEnabled = false;
      _cloudSyncEnabled = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('本地数据已清除')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('设置')),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
          child: const Center(child: CircularProgressIndicator(color: AppTheme.neonCyan)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.deepSpaceGradient),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionTitle(context, '音频与反馈'),
            _buildSwitchTile(
              context,
              '音效',
              Icons.volume_up,
              _soundEnabled,
              (v) => _setBool(AppConstants.prefSoundEnabled, v, (val) => _soundEnabled = val),
            ),
            _buildSwitchTile(
              context,
              '设备震动',
              Icons.vibration,
              _vibrationEnabled,
              (v) => _setBool(AppConstants.prefVibrationEnabled, v, (val) => _vibrationEnabled = val),
            ),
            _buildSwitchTile(
              context,
              '枪械音效（射击训练）',
              Icons.gps_fixed,
              _gunSoundEnabled,
              (v) => _setBool(AppConstants.prefGunSoundEnabled, v, (val) => _gunSoundEnabled = val),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, '数据与同步'),
            _buildSwitchTile(
              context,
              '云端同步（预留接口）',
              Icons.cloud_off,
              _cloudSyncEnabled,
              (v) => _setBool(AppConstants.prefCloudSyncEnabled, v, (val) => _cloudSyncEnabled = val),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_outline, color: AppTheme.alertRed),
                title: Text('清除本地数据', style: context.textTheme.titleMedium),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.neonCyan),
                onTap: _confirmClearData,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle(context, '关于'),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.nebulaGray),
              title: Text('版本', style: context.textTheme.titleMedium),
              trailing: Text(AppConstants.appVersion, style: context.textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: context.textTheme.titleSmall?.copyWith(color: AppTheme.neonCyan)),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    IconData icon,
    bool value,
    Future<void> Function(bool) onChanged,
  ) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, color: AppTheme.neonCyan),
        title: Text(title, style: context.textTheme.titleMedium),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.neonCyan,
      ),
    );
  }
}
