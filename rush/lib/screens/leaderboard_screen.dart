import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

enum _Period { today, week, month, allTime }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  _Period _selected = _Period.week;

  static const _labels = {
    _Period.today: 'Hoy',
    _Period.week: 'Semana',
    _Period.month: 'Mes',
    _Period.allTime: 'Total',
  };

  static const _icons = {
    _Period.today: Icons.today_rounded,
    _Period.week: Icons.view_week_rounded,
    _Period.month: Icons.calendar_month_rounded,
    _Period.allTime: Icons.all_inclusive_rounded,
  };

  // Returns the header subtitle for the current period
  String _periodSubtitle() {
    final now = DateTime.now();
    switch (_selected) {
      case _Period.today:
        final months = [
          'ene', 'feb', 'mar', 'abr', 'may', 'jun',
          'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
        ];
        return '${now.day} de ${months[now.month - 1]}. de ${now.year}';
      case _Period.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${weekStart.day}/${weekStart.month} – ${weekEnd.day}/${weekEnd.month}/${weekEnd.year}';
      case _Period.month:
        const monthNames = [
          'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
          'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
        ];
        return '${monthNames[now.month - 1]} ${now.year}';
      case _Period.allTime:
        return 'Desde el inicio';
    }
  }

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

        final entries = _getMockLeaderboard(
          userId: user.id,
          userName: user.name,
          userXp: user.xp,
          userDistance: user.totalDistance,
          userRuns: user.totalRuns,
          userLevel: user.level,
          period: _selected,
        );

        final myRank = entries.indexWhere((e) => e.isCurrentUser) + 1;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              // App bar + filters
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: AppColors.background,
                elevation: 0,
                titleSpacing: 20,
                title: const Text(
                  'Ranking',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 22,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: _buildFilterChips(),
                ),
              ),

              // Period + my rank header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _buildMyRankBanner(
                    myRank: myRank,
                    total: entries.length,
                    periodLabel: _periodSubtitle(),
                  ),
                ),
              ),

              // Podium
              SliverToBoxAdapter(
                child: _buildPodium(entries.take(3).toList()),
              ),

              // List (rank 4+)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = entries[index + 3];
                      return _buildListItem(entry, index + 4);
                    },
                    childCount: entries.length > 3 ? entries.length - 3 : 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: _Period.values.map((period) {
          final isSelected = _selected == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selected = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[period]!,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _labels[period]!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMyRankBanner({
    required int myRank,
    required int total,
    required String periodLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(30),
            AppColors.primaryDark.withAlpha(15),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estás en el puesto #$myRank de $total',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                Text(
                  periodLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#$myRank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    if (top3.length < 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildPodiumItem(top3[1], 2, 80)),
          const SizedBox(width: 6),
          Expanded(child: _buildPodiumItem(top3[0], 1, 110)),
          const SizedBox(width: 6),
          Expanded(child: _buildPodiumItem(top3[2], 3, 64)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int rank, double standHeight) {
    final colors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFB0BEC5),
      3: const Color(0xFFBF8A60),
    };
    final crowns = {
      1: '👑',
      2: '🥈',
      3: '🥉',
    };
    final rankColor = colors[rank]!;
    final avatarSize = rank == 1 ? 64.0 : 52.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown / medal
        Text(crowns[rank]!, style: TextStyle(fontSize: rank == 1 ? 22 : 16)),
        const SizedBox(height: 4),
        // Avatar
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: entry.isCurrentUser ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: rankColor, width: rank == 1 ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: rankColor.withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: rank == 1 ? 26 : 20,
                fontWeight: FontWeight.bold,
                color:
                    entry.isCurrentUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.isCurrentUser ? 'Tú' : entry.name.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color:
                entry.isCurrentUser ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        Text(
          '${entry.xp} XP',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        // Podium stand
        Container(
          width: double.infinity,
          height: standHeight,
          decoration: BoxDecoration(
            color: rankColor.withAlpha(40),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: rankColor.withAlpha(150)),
          ),
          child: Center(
            child: Text(
              Formatters.ordinal(rank),
              style: TextStyle(
                color: rankColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(LeaderboardEntry entry, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primary.withAlpha(20)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: entry.isCurrentUser
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: entry.isCurrentUser
                    ? AppColors.primary
                    : AppColors.textMuted,
              ),
            ),
          ),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: entry.isCurrentUser
                  ? AppColors.primary
                  : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: entry.isCurrentUser
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isCurrentUser ? '${entry.name} (Tú)' : entry.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: entry.isCurrentUser
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _statPill(
                      Icons.directions_run_rounded,
                      '${entry.runs}',
                      AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    _statPill(
                      Icons.straighten_rounded,
                      Formatters.distance(entry.distance),
                      AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // XP badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: entry.isCurrentUser
                  ? AppColors.primary.withAlpha(30)
                  : AppColors.secondary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${entry.xp} XP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: entry.isCurrentUser
                    ? AppColors.primary
                    : AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: color),
        ),
      ],
    );
  }

  // ─── Mock data ───────────────────────────────────────────────────────────────

  List<LeaderboardEntry> _getMockLeaderboard({
    required String userId,
    required String userName,
    required int userXp,
    required int userDistance,
    required int userRuns,
    required int userLevel,
    required _Period period,
  }) {
    // Multiplier per period so numbers feel realistic
    final factor = switch (period) {
      _Period.today => 0.08,
      _Period.week => 0.35,
      _Period.month => 1.0,
      _Period.allTime => 3.5,
    };

    final mockUsers = [
      _mock('Carlos M.', 2500, 45000, 18, 4, factor),
      _mock('Ana G.', 2100, 38000, 14, 3, factor),
      _mock('Luis R.', 1800, 32000, 11, 3, factor),
      _mock('Maria S.', 1500, 28000, 9, 2, factor),
      _mock('Pedro L.', 1200, 22000, 7, 2, factor),
    ];

    final me = LeaderboardEntry(
      id: userId,
      name: userName,
      xp: (userXp * factor).round(),
      distance: (userDistance * factor).round(),
      runs: (userRuns * factor).round(),
      level: userLevel,
      isCurrentUser: true,
    );

    return [...mockUsers, me]..sort((a, b) => b.xp.compareTo(a.xp));
  }

  LeaderboardEntry _mock(
    String name,
    int xp,
    int distance,
    int runs,
    int level,
    double factor,
  ) {
    return LeaderboardEntry(
      id: name,
      name: name,
      xp: (xp * factor).round(),
      distance: (distance * factor).round(),
      runs: (runs * factor).round(),
      level: level,
    );
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final String id;
  final String name;
  final int xp;
  final int distance;
  final int runs;
  final int level;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.id,
    required this.name,
    required this.xp,
    required this.distance,
    required this.runs,
    required this.level,
    this.isCurrentUser = false,
  });
}
