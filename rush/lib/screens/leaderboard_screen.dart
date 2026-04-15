import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../models/store_item.dart';
import '../services/sync_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

enum _Period { today, week, month, allTime }
enum _Scope { global, faculty, semester }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  _Period _selected = _Period.week;
  _Scope _scope = _Scope.global;
  late Future<List<LeaderboardEntry>> _leaderboardFuture;
  String? _currentUserId;
  String? _userFaculty;
  int? _userSemester;

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

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    final since = _getPeriodStart();
    final faculty = _scope == _Scope.faculty ? _userFaculty : null;
    final semester = _scope == _Scope.semester ? _userSemester : null;
    _leaderboardFuture = SyncService()
        .fetchLeaderboard(since: since, faculty: faculty, semester: semester)
        .then((data) => _mapEntries(data));
  }

  DateTime? _getPeriodStart() {
    final now = DateTime.now();
    switch (_selected) {
      case _Period.today:
        return DateTime(now.year, now.month, now.day);
      case _Period.week:
        return now.subtract(Duration(days: now.weekday - 1));
      case _Period.month:
        return DateTime(now.year, now.month, 1);
      case _Period.allTime:
        return null;
    }
  }

  List<LeaderboardEntry> _mapEntries(List<Map<String, dynamic>> data) {
    return data.map((d) {
      final distKm = (d['totalDistance'] as num?)?.toDouble() ?? 0.0;
      final avatarColorId = d['equippedAvatarColorId'] as String?;
      final avatarFrameId = d['equippedAvatarFrameId'] as String?;
      return LeaderboardEntry(
        id: d['id'] as String? ?? '',
        name: d['name'] as String? ?? 'Sin nombre',
        xp: (d['xp'] as num?)?.round() ?? 0,
        distanceMeters: (distKm * 1000).round(),
        runs: (d['totalRuns'] as num?)?.round() ?? 0,
        isCurrentUser: (d['id'] as String?) == _currentUserId,
        avatarColor: StoreItems.getById(avatarColorId ?? '')?.color,
        frameColor: StoreItems.getById(avatarFrameId ?? '')?.color,
      );
    }).toList();
  }

  String _periodSubtitle() {
    final now = DateTime.now();
    switch (_selected) {
      case _Period.today:
        const months = [
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

        // Keep current user data in sync
        _currentUserId = user.id;
        _userFaculty = user.faculty;
        _userSemester = user.semester;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: FutureBuilder<List<LeaderboardEntry>>(
            future: _leaderboardFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingScaffold();
              }

              final entries = snapshot.data ?? [];

              // If current user isn't in the Firebase results, add them locally
              final hasMe = entries.any((e) => e.isCurrentUser);
              final equippedTitle = gamification.equippedTitle;
              final myAvatarColor = StoreItems.getById(
                gamification.equippedAvatarColorId ?? '',
              )?.color;
              final myFrameColor = StoreItems.getById(
                gamification.equippedAvatarFrameId ?? '',
              )?.color;
              final allEntries = hasMe
                  ? entries
                  : [
                      ...entries,
                      LeaderboardEntry(
                        id: user.id,
                        name: user.name,
                        xp: user.xp,
                        distanceMeters: user.totalDistance,
                        runs: user.totalRuns,
                        isCurrentUser: true,
                        titleEmoji: equippedTitle?.emoji,
                        titleName: equippedTitle?.name,
                        avatarColor: myAvatarColor,
                        frameColor: myFrameColor,
                      ),
                    ]..sort((a, b) => b.xp.compareTo(a.xp));

              final myRank = allEntries.indexWhere((e) => e.isCurrentUser) + 1;

              return CustomScrollView(
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
                      preferredSize: Size.fromHeight(
                        56 + (_userFaculty != null || _userSemester != null ? 48 : 0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFilterChips(),
                          if (_userFaculty != null || _userSemester != null)
                            _buildScopeChips(user),
                        ],
                      ),
                    ),
                  ),

                  // Period + my rank header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _buildMyRankBanner(
                        myRank: myRank,
                        total: allEntries.length,
                        periodLabel: _periodSubtitle(),
                      ),
                    ),
                  ),

                  // Podium
                  SliverToBoxAdapter(
                    child: _buildPodium(allEntries.take(3).toList()),
                  ),

                  // Empty state (no other users)
                  if (allEntries.length <= 1)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Aún no hay más corredores.\n¡Sé el primero en liderar!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // List (rank 4+)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = allEntries[index + 3];
                          return _buildListItem(entry, index + 4);
                        },
                        childCount:
                            allEntries.length > 3 ? allEntries.length - 3 : 0,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingScaffold() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
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
        const SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ],
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
              onTap: () => setState(() {
                _selected = period;
                _loadLeaderboard();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
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

  Widget _buildScopeChips(dynamic user) {
    final hasFaculty = _userFaculty != null;
    final hasSemester = _userSemester != null;

    final scopes = <_Scope, String>{
      _Scope.global: 'Global',
      if (hasFaculty) _Scope.faculty: 'Mi Facultad',
      if (hasSemester) _Scope.semester: 'Semestre $_userSemester',
    };

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: scopes.entries.map((entry) {
          final isSelected = _scope == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _scope = entry.key;
                _loadLeaderboard();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.secondary.withAlpha(220)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.textMuted.withAlpha(50),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                  ),
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
    if (top3.isEmpty) return const SizedBox.shrink();

    // Pad with placeholder entries if fewer than 3 users
    final padded = List<LeaderboardEntry>.from(top3);
    while (padded.length < 3) {
      padded.add(LeaderboardEntry(
        id: '',
        name: '—',
        xp: 0,
        distanceMeters: 0,
        runs: 0,
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildPodiumItem(padded[1], 2, 80)),
          const SizedBox(width: 6),
          Expanded(child: _buildPodiumItem(padded[0], 1, 110)),
          const SizedBox(width: 6),
          Expanded(child: _buildPodiumItem(padded[2], 3, 64)),
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
    final crowns = {1: '👑', 2: '🥈', 3: '🥉'};
    final rankColor = colors[rank]!;
    final avatarSize = rank == 1 ? 64.0 : 52.0;
    final isEmpty = entry.id.isEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(crowns[rank]!, style: TextStyle(fontSize: rank == 1 ? 22 : 16)),
        const SizedBox(height: 4),
        Container(
          width: avatarSize,
          height: avatarSize,
          decoration: BoxDecoration(
            color: isEmpty
                ? AppColors.surface
                : entry.avatarColor ??
                    (entry.isCurrentUser ? AppColors.primary : AppColors.surface),
            shape: BoxShape.circle,
            border: Border.all(
              color: isEmpty
                  ? AppColors.surface
                  : entry.frameColor ?? rankColor,
              width: rank == 1 ? 3 : 2,
            ),
            boxShadow: isEmpty
                ? null
                : [
                    BoxShadow(
                      color: (entry.frameColor ?? rankColor).withAlpha(80),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Text(
              isEmpty
                  ? '?'
                  : entry.name.isNotEmpty
                      ? entry.name[0].toUpperCase()
                      : '?',
              style: TextStyle(
                fontSize: rank == 1 ? 26 : 20,
                fontWeight: FontWeight.bold,
                color: (entry.isCurrentUser || entry.avatarColor != null)
                    ? Colors.white
                    : AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isEmpty
              ? 'Sin asignar'
              : entry.isCurrentUser
                  ? 'Tú'
                  : entry.name.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isEmpty
                ? AppColors.textMuted
                : entry.isCurrentUser
                    ? AppColors.primary
                    : AppColors.textPrimary,
          ),
        ),
        Text(
          isEmpty ? '— XP' : '${entry.xp} XP',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: standHeight,
          decoration: BoxDecoration(
            color: rankColor.withAlpha(isEmpty ? 15 : 40),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: rankColor.withAlpha(isEmpty ? 60 : 150)),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: entry.avatarColor ??
                  (entry.isCurrentUser ? AppColors.primary : AppColors.background),
              shape: BoxShape.circle,
              border: entry.frameColor != null
                  ? Border.all(color: entry.frameColor!, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: (entry.isCurrentUser || entry.avatarColor != null)
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                if (entry.titleName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${entry.titleEmoji ?? ''} ${entry.titleName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                      Formatters.distance(entry.distanceMeters),
                      AppColors.textMuted,
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final String id;
  final String name;
  final int xp;
  final int distanceMeters;
  final int runs;
  final bool isCurrentUser;
  final String? titleEmoji;
  final String? titleName;
  final Color? avatarColor;
  final Color? frameColor;

  LeaderboardEntry({
    required this.id,
    required this.name,
    required this.xp,
    required this.distanceMeters,
    required this.runs,
    this.isCurrentUser = false,
    this.titleEmoji,
    this.titleName,
    this.avatarColor,
    this.frameColor,
  });
}
