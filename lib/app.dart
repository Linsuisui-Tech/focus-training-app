import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

/// 应用根组件
///
/// ProviderScope 包裹整个应用，使 Riverpod 状态管理全局可用。
class FocusTrainingApp extends StatelessWidget {
  const FocusTrainingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'Focus Spark',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        routerConfig: appRouter,
      ),
    );
  }
}
