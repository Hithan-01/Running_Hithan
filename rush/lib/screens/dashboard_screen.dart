import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../models/mission.dart';
import '../widgets/circular_step_gauge.dart';
import '../widgets/mission_card.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'map_screen.dart';
import 'missions_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationService>(
      builder: (context, gamification, child) {
        final user = gamification.user;

        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        // Calculate steps from total distance (approximate: 1 km = 1300 steps)
        final int estimatedSteps = ((user.totalDistance / 1000) * 1300).round();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with XP and profile
                  _buildHeader(gamification, user.name),

                  // Circular Step Gauge
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CircularStepGauge(
                      currentSteps: estimatedSteps > 0
                          ? estimatedSteps
                          : 7250, // Mock data if no real data
                      goalSteps: 20000,
                      currentXP: user.xp - user.xpForCurrentLevel,
                      xpToNextLevel: user.xpForNextLevel - user.xpForCurrentLevel,
                    ),
                  ),

                  // Start Run Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStartButton(context),
                  ),

                  const SizedBox(height: 24),

                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildStatsRow(gamification),
                  ),

                  const SizedBox(height: 24),

                  // Missions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildMissionsSection(gamification),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(GamificationService gamification, String name) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Notification icon - just the icon, no container
          const Icon(
            Icons.notifications_outlined,
            color: AppColors.textPrimary,
            size: 26,
          ),

          // Center badges (XP, Rank, Streak)
          Row(
            children: [
              _buildXpBadge(
                value: '${gamification.xp}',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              _buildHeaderBadge(
                icon: Icons.leaderboard_rounded,
                value: '${gamification.level}th',
                color: _getRankColor(gamification.level),
              ),
              const SizedBox(width: 8),
              _buildHeaderBadge(
                icon: Icons.local_fire_department_rounded,
                value: '${gamification.user!.currentStreak}',
                color: AppColors.primary,
              ),
            ],
          ),

          // Profile avatar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withAlpha(26),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textMuted.withAlpha(40), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpBadge({required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textMuted.withAlpha(40), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'XP',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) {
      return const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      return const Color(0xFFC0C0C0); // Silver
    } else if (rank == 3) {
      return const Color(0xFFCD7F32); // Bronze
    } else {
      return AppColors.textSecondary;
    }
  }

  Widget _buildStartButton(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        child: ElevatedButton(
          onPressed: () => _startRun(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Iniciar carrera',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _startRun(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen()),
    );
  }

  Widget _buildStatsRow(GamificationService gamification) {
    final stats = gamification.getStats();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.emoji_events_rounded,
            label: 'Lvl. ${gamification.level}',
            sublabel: gamification.levelName,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.local_fire_department_rounded,
            label: '${gamification.user!.currentStreak}',
            sublabel: 'RACHA',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.place_rounded,
            label: Formatters.distance(stats['totalDistance'] ?? 0),
            sublabel: 'DISTANCIA',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsSection(GamificationService gamification) {
    final activeMissions = gamification.activeMissions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Misiones del Dia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MissionsScreen()),
                );
              },
              child: const Text(
                'Ver todas',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeMissions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.textMuted,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No hay misiones activas',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeMissions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final activeMission = activeMissions[index];
                final mission = Missions.getById(activeMission.missionId);
                if (mission == null) return const SizedBox.shrink();

                return MissionCard(
                  mission: mission,
                  currentProgress: activeMission.currentProgress,
                  isCompleted: activeMission.isCompleted,
                  compact: true,
                );
              },
            ),
          ),
      ],
    );
  }
}
