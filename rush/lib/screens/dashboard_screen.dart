import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../models/mission.dart';
import '../widgets/circular_step_gauge.dart';
import '../widgets/mission_card.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../services/database_service.dart';
import 'map_screen.dart';
import 'missions_screen.dart';
import 'notification_center_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';

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
                      currentSteps: estimatedSteps,
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

                  // Activity / Charts Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildActivitySection(user.id),
                  ),

                  const SizedBox(height: 100),
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
          // Notification icon with unread badge
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationCenterScreen(),
                ),
              );
              if (context.mounted) setState(() {});
            },
            child: _buildBellIcon(gamification),
          ),

          // Center badges (XP, Coins, Streak)
          Row(
            children: [
              _buildXpBadge(
                value: '${gamification.xp}',
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              _buildHeaderBadge(
                icon: Icons.toll_rounded,
                value: '${gamification.coins}',
                color: const Color(0xFFFFB300),
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
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
              if (context.mounted) setState(() {});
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

  Widget _buildBellIcon(GamificationService gamification) {
    final userId = gamification.user?.id;
    final unreadCount =
        userId != null ? DatabaseService.getUnreadCount(userId) : 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(
          Icons.notifications_outlined,
          color: AppColors.textPrimary,
          size: 26,
        ),
        if (unreadCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
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

  Widget _buildActivitySection(String userId) {
    final runs = DatabaseService.getAllRuns(userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Actividad reciente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: const Text(
                'Ver todo',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (runs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                'Aún no hay carreras registradas',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildMiniBarChart(runs)),
                const SizedBox(width: 12),
                Expanded(child: _buildMiniPaceTrend(runs)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMiniBarChart(List runs) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return DateTime(d.year, d.month, d.day);
    });
    final distPerDay = <DateTime, double>{for (final d in days) d: 0};
    for (final run in runs) {
      final day = DateTime(run.createdAt.year, run.createdAt.month, run.createdAt.day);
      if (distPerDay.containsKey(day)) {
        distPerDay[day] = distPerDay[day]! + run.distance / 1000.0;
      }
    }
    final values = days.map((d) => distPerDay[d]!).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    const labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('7 días', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final km = values[i];
                final isToday = i == 6;
                final frac = maxVal > 0 ? km / maxVal : 0.0;
                final barH = 8.0 + frac * 56.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: barH,
                          decoration: BoxDecoration(
                            color: km == 0
                                ? AppColors.background
                                : isToday
                                    ? AppColors.primary
                                    : AppColors.primary.withAlpha(100),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[days[i].weekday - 1],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? AppColors.primary : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPaceTrend(List runs) {
    final withPace = runs
        .where((r) => (r.avgPace as double) > 0 && r.distance >= 500)
        .toList()
        .reversed
        .take(8)
        .toList()
        .reversed
        .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 6)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ritmo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: withPace.length < 2
                ? const Center(child: Text('Sin datos', style: TextStyle(color: AppColors.textMuted, fontSize: 11)))
                : CustomPaint(
                    size: const Size(double.infinity, 80),
                    painter: _MiniPacePainter(
                      paces: withPace.map((r) => r.avgPace as double).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                withPace.isNotEmpty ? _fmtPace(withPace.first.avgPace) : '--',
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
              const Text('min/km', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
              Text(
                withPace.isNotEmpty ? _fmtPace(withPace.last.avgPace) : '--',
                style: const TextStyle(fontSize: 9, color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtPace(double pace) {
    final min = pace.floor();
    final sec = ((pace - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
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

// ─── Mini pace line painter (dashboard) ──────────────────────────────────────

class _MiniPacePainter extends CustomPainter {
  final List<double> paces;
  _MiniPacePainter({required this.paces});

  @override
  void paint(Canvas canvas, Size size) {
    if (paces.length < 2) return;
    final minP = paces.reduce((a, b) => a < b ? a : b);
    final maxP = paces.reduce((a, b) => a > b ? a : b);
    final range = (maxP - minP).clamp(0.5, double.infinity);
    final xStep = size.width / (paces.length - 1);

    List<Offset> pts = [];
    for (int i = 0; i < paces.length; i++) {
      final x = i * xStep;
      final y = size.height * 0.1 + (1 - (paces[i] - minP) / range) * size.height * 0.8;
      pts.add(Offset(x, y));
    }

    final fill = Path()..moveTo(pts.first.dx, size.height);
    for (final p in pts) { fill.lineTo(p.dx, p.dy); }
    fill..lineTo(pts.last.dx, size.height)..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary.withAlpha(70), AppColors.primary.withAlpha(5)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      path.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(path, line);

    canvas.drawCircle(pts.last, 4, Paint()..color = AppColors.primary);
    canvas.drawCircle(pts.last, 7, Paint()..color = AppColors.primary.withAlpha(40));
  }

  @override
  bool shouldRepaint(_MiniPacePainter old) => old.paces != paces;
}
