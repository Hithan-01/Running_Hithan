import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mission.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';
import '../widgets/mission_card.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationService>(
      builder: (context, gamification, _) {
        final activeMissions = gamification.activeMissions;

        // Build lookup of active missions by missionId
        final activeMap = <String, ActiveMission>{};
        for (final am in activeMissions) {
          activeMap[am.missionId] = am;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Misiones',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Diarias'),
                const SizedBox(height: 12),
                _buildMissionList(Missions.dailyMissions, activeMap),
                const SizedBox(height: 24),
                _buildSectionHeader('Semanales'),
                const SizedBox(height: 12),
                _buildMissionList(Missions.weeklyMissions, activeMap),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMissionList(
    List<Mission> missions,
    Map<String, ActiveMission> activeMap,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: missions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final mission = missions[index];
        final active = activeMap[mission.id];
        final isActive = active != null;

        if (isActive) {
          return MissionCard(
            mission: mission,
            currentProgress: active.currentProgress,
            isCompleted: active.isCompleted,
          );
        }

        // Locked / unassigned mission (grayed out)
        return Opacity(
          opacity: 0.45,
          child: MissionCard(
            mission: mission,
            currentProgress: 0,
          ),
        );
      },
    );
  }
}
