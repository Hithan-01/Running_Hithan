import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Social',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Semanal'),
            Tab(text: 'Total'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboardList(isWeekly: true),
          _buildLeaderboardList(isWeekly: false),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList({required bool isWeekly}) {
    // In a real app, this would fetch from a backend
    // For MVP, we show the current user and mock data
    return Consumer<GamificationService>(
      builder: (context, gamification, child) {
        final user = gamification.user;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Mock leaderboard data
        final leaderboardData = _getMockLeaderboard(
          currentUserId: user.id,
          currentUserName: user.name,
          currentUserXp: isWeekly ? (user.xp ~/ 4) : user.xp,
          currentUserDistance: isWeekly
              ? (user.totalDistance ~/ 4)
              : user.totalDistance,
        );

        return Column(
          children: [
            // Top 3 podium
            _buildPodium(leaderboardData.take(3).toList()),

            // Rest of the list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: leaderboardData.length - 3,
                itemBuilder: (context, index) {
                  final entry = leaderboardData[index + 3];
                  return _buildLeaderboardItem(entry, index + 4);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  List<LeaderboardEntry> _getMockLeaderboard({
    required String currentUserId,
    required String currentUserName,
    required int currentUserXp,
    required int currentUserDistance,
  }) {
    final mockUsers = [
      LeaderboardEntry(
        id: '1',
        name: 'Carlos M.',
        xp: 2500,
        distance: 45000,
        level: 4,
      ),
      LeaderboardEntry(
        id: '2',
        name: 'Ana G.',
        xp: 2100,
        distance: 38000,
        level: 3,
      ),
      LeaderboardEntry(
        id: '3',
        name: 'Luis R.',
        xp: 1800,
        distance: 32000,
        level: 3,
      ),
      LeaderboardEntry(
        id: '4',
        name: 'Maria S.',
        xp: 1500,
        distance: 28000,
        level: 2,
      ),
      LeaderboardEntry(
        id: '5',
        name: 'Pedro L.',
        xp: 1200,
        distance: 22000,
        level: 2,
      ),
    ];

    // Add current user
    final currentUser = LeaderboardEntry(
      id: currentUserId,
      name: currentUserName,
      xp: currentUserXp,
      distance: currentUserDistance,
      level: context.read<GamificationService>().level,
      isCurrentUser: true,
    );

    final allUsers = [...mockUsers, currentUser];
    allUsers.sort((a, b) => b.xp.compareTo(a.xp));

    return allUsers;
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    if (top3.length < 3) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          _buildPodiumItem(top3[1], 2, 80),
          const SizedBox(width: 8),
          // 1st place
          _buildPodiumItem(top3[0], 1, 100),
          const SizedBox(width: 8),
          // 3rd place
          _buildPodiumItem(top3[2], 3, 60),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int rank, double height) {
    Color rankColor;
    IconData rankIcon;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // Gold
        rankIcon = Icons.emoji_events_rounded;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // Silver
        rankIcon = Icons.emoji_events_rounded;
        break;
      default:
        rankColor = const Color(0xFFCD7F32); // Bronze
        rankIcon = Icons.emoji_events_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar
        Container(
          width: rank == 1 ? 60 : 50,
          height: rank == 1 ? 60 : 50,
          decoration: BoxDecoration(
            color: entry.isCurrentUser ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: rankColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: rank == 1 ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: entry.isCurrentUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          entry.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: entry.isCurrentUser
                ? AppColors.primary
                : AppColors.textPrimary,
          ),
        ),
        Text(
          '${entry.xp} XP',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        // Podium stand
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: rankColor.withAlpha(51),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
            border: Border.all(color: rankColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(rankIcon, color: rankColor, size: 24),
              Text(
                Formatters.ordinal(rank),
                style: TextStyle(
                  color: rankColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? AppColors.primary.withAlpha(26)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: entry.isCurrentUser
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: entry.isCurrentUser
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: entry.isCurrentUser ? AppColors.primary : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: entry.isCurrentUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isCurrentUser ? '${entry.name} (Tu)' : entry.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: entry.isCurrentUser
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Nivel ${entry.level}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // XP and distance
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.xp} XP',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              Text(
                Formatters.distance(entry.distance),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LeaderboardEntry {
  final String id;
  final String name;
  final int xp;
  final int distance;
  final int level;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.id,
    required this.name,
    required this.xp,
    required this.distance,
    required this.level,
    this.isCurrentUser = false,
  });
}
