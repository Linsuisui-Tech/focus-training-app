import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'constants.dart';
import '../ui/home/home_screen.dart';
import '../ui/training/training_hall_screen.dart';
import '../ui/games/schulte/schulte_game_screen.dart';
import '../ui/games/tracking/tracking_game_screen.dart';
import '../ui/games/shooting/shooting_game_screen.dart';
import '../ui/games/interference/interference_game_screen.dart';
import '../ui/games/rhythm/rhythm_game_screen.dart';
import '../ui/video/video_library_screen.dart';
import '../ui/diet/diet_screen.dart';
import '../ui/plans/plans_screen.dart';
import '../ui/plans/plan_detail_screen.dart';
import '../ui/stats/stats_screen.dart';
import '../ui/settings/settings_screen.dart';

/// 应用路由表
///
/// 使用 GoRouter 实现声明式路由，便于深层链接与页面转场统一管理。
final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.home,
  routes: [
    GoRoute(
      path: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: RouteNames.trainingHall,
      builder: (context, state) => const TrainingHallScreen(),
    ),
    GoRoute(
      path: RouteNames.schulte,
      builder: (context, state) {
        final gridSize = int.tryParse(state.uri.queryParameters['size'] ?? '') ?? 5;
        return SchulteGameScreen(gridSize: gridSize);
      },
    ),
    GoRoute(
      path: RouteNames.tracking,
      builder: (context, state) => const TrackingGameScreen(),
    ),
    GoRoute(
      path: RouteNames.shooting,
      builder: (context, state) => const ShootingGameScreen(),
    ),
    GoRoute(
      path: RouteNames.interference,
      builder: (context, state) => const InterferenceGameScreen(),
    ),
    GoRoute(
      path: RouteNames.rhythm,
      builder: (context, state) => const RhythmGameScreen(),
    ),
    GoRoute(
      path: RouteNames.videoLibrary,
      builder: (context, state) => const VideoLibraryScreen(),
    ),
    GoRoute(
      path: RouteNames.diet,
      builder: (context, state) => const DietScreen(),
    ),
    GoRoute(
      path: RouteNames.plans,
      builder: (context, state) => const PlansScreen(),
    ),
    GoRoute(
      path: RouteNames.planDetail,
      builder: (context, state) {
        final planId = state.uri.queryParameters['id'];
        return PlanDetailScreen(planId: planId);
      },
    ),
    GoRoute(
      path: RouteNames.stats,
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: RouteNames.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

/// 页面转场动画封装
class AppPageTransitions {
  AppPageTransitions._();

  static CustomTransitionPage<T> fade<T>({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
          child: child,
        );
      },
    );
  }
}
