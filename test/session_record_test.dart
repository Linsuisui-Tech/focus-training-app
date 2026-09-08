import 'package:flutter_test/flutter_test.dart';

import 'package:focus_training_app/core/constants.dart';
import 'package:focus_training_app/data/models/session_record.dart';
import 'package:focus_training_app/data/models/training_plan.dart';

void main() {
  group('SessionRecord', () {
    test('fromJson/toJson round-trip', () {
      final record = SessionRecord(
        moduleType: TrainingModuleType.schulte,
        difficulty: 3,
        score: 92.5,
        metrics: {'elapsedSeconds': 5.0, 'wrongClicks': 1.0},
        timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000),
        durationSeconds: 20,
      );

      final restored = SessionRecord.fromJson(record.toJson());

      expect(restored.moduleType, TrainingModuleType.schulte);
      expect(restored.difficulty, 3);
      expect(restored.score, 92.5);
      expect(restored.metrics['elapsedSeconds'], 5.0);
      expect(restored.timestamp.millisecondsSinceEpoch, 1700000000000);
      expect(restored.durationSeconds, 20);
    });

    test('abilityDimensionFor maps all modules', () {
      expect(abilityDimensionFor(TrainingModuleType.schulte), AbilityDimension.visualSearch);
      expect(abilityDimensionFor(TrainingModuleType.tracking), AbilityDimension.tracking);
      expect(abilityDimensionFor(TrainingModuleType.shooting), AbilityDimension.reaction);
      expect(abilityDimensionFor(TrainingModuleType.interference), AbilityDimension.inhibition);
      expect(abilityDimensionFor(TrainingModuleType.rhythm), AbilityDimension.rhythm);
    });
  });

  group('TrainingPlan', () {
    test('toJson/fromJson round-trip', () {
      final plan = TrainingPlan(
        id: 'p_test',
        name: '测试计划',
        description: 'desc',
        intensity: IntensityLevel.medium,
        targetScene: FocusScene.work,
        modules: [
          PlanModule(
            type: TrainingModuleType.schulte,
            title: '舒尔特',
            durationSeconds: 120,
            difficulty: 2,
          ),
        ],
      );

      final restored = TrainingPlan.fromJson(plan.toJson());

      expect(restored.id, 'p_test');
      expect(restored.modules.first.type, TrainingModuleType.schulte);
      expect(restored.totalDurationSeconds, 120);
    });
  });
}
