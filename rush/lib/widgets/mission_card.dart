import 'package:flutter/material.dart';
import '../models/mission.dart';
import '../utils/constants.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final int currentProgress;
  final bool isCompleted;
  final VoidCallback? onTap;

  const MissionCard({
    super.key,
    required this.mission,
    required this.currentProgress,
    this.isCompleted = false,
    this.onTap,
  });

  double get progress {
    if (mission.goalValue <= 0) return 0;
    return (currentProgress / mission.goalValue).clamp(0.0, 1.0);
  }

  String get progressText {
    switch (mission.goalType) {
      case MissionGoalType.distance:
        int currentKm = currentProgress ~/ 1000;
        int goalKm = mission.goalValue ~/ 1000;
        return '$currentKm / $goalKm km';
      case MissionGoalType.duration:
        int currentMin = currentProgress ~/ 60;
        int goalMin = mission.goalValue ~/ 60;
        return '$currentMin / $goalMin min';
      case MissionGoalType.pois:
      case MissionGoalType.runs:
        return '$currentProgress / ${mission.goalValue}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCompleted
                  ? 'Mision completada! ${mission.name}'
                  : '${mission.name} - $progressText',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: isCompleted ? AppColors.success : AppColors.primary,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withAlpha(26)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isCompleted
              ? Border.all(color: AppColors.success, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Mission icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withAlpha(26)
                        : AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    MissionIcons.getIcon(mission.icon),
                    color: isCompleted ? AppColors.success : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mission.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? AppColors.success
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mission.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.xpBarBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppColors.success
                                : AppColors.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  progressText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMissionTypeChip(),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: AppColors.secondary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${mission.xpReward} XP',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionTypeChip() {
    Color chipColor;
    String label;

    switch (mission.type) {
      case MissionType.daily:
        chipColor = AppColors.primary;
        label = 'Diaria';
        break;
      case MissionType.weekly:
        chipColor = AppColors.secondary;
        label = 'Semanal';
        break;
      case MissionType.event:
        chipColor = AppColors.warning;
        label = 'Evento';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
