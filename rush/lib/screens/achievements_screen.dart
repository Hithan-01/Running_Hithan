import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../models/achievement.dart';
import '../models/store_item.dart';
import '../utils/constants.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
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
    return Consumer<GamificationService>(
      builder: (context, gamification, child) {
        final unlockedCount = Achievements.all
            .where((a) => gamification.isAchievementUnlocked(a.id))
            .length;
        final total = Achievements.all.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Logros & Tienda',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.background,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Logros'),
                Tab(text: 'Tienda'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Logros ──────────────────────────────────────────────
              _LogrosTab(
                gamification: gamification,
                unlockedCount: unlockedCount,
                total: total,
              ),

              // ── Tab 2: Tienda ──────────────────────────────────────────────
              _TiendaTab(gamification: gamification),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGROS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _LogrosTab extends StatelessWidget {
  final GamificationService gamification;
  final int unlockedCount;
  final int total;

  const _LogrosTab({
    required this.gamification,
    required this.unlockedCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: _buildProgressHeader(unlockedCount, total),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final achievement = Achievements.all[index];
                final isUnlocked =
                    gamification.isAchievementUnlocked(achievement.id);
                return _AchievementCard(
                  achievement: achievement,
                  isUnlocked: isUnlocked,
                );
              },
              childCount: Achievements.all.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.82,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressHeader(int unlocked, int total) {
    final progress = total > 0 ? unlocked / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu progreso',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$unlocked de $total desbloqueados',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.textMuted.withAlpha(40),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TIENDA TAB
// ─────────────────────────────────────────────────────────────────────────────

class _TiendaTab extends StatelessWidget {
  final GamificationService gamification;

  const _TiendaTab({required this.gamification});

  @override
  Widget build(BuildContext context) {
    final coins = gamification.coins;

    return CustomScrollView(
      slivers: [
        // Coins header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: _buildCoinsHeader(coins),
          ),
        ),

        // Avatar Colors
        SliverToBoxAdapter(
          child: _buildCategoryHeader('Color de Avatar', Icons.palette_rounded),
        ),
        SliverToBoxAdapter(
          child: _buildItemsRow(
            context,
            StoreItems.byCategory(StoreCategory.avatarColor),
          ),
        ),

        // Avatar Frames
        SliverToBoxAdapter(
          child: _buildCategoryHeader('Marco de Avatar', Icons.crop_free_rounded),
        ),
        SliverToBoxAdapter(
          child: _buildItemsRow(
            context,
            StoreItems.byCategory(StoreCategory.avatarFrame),
          ),
        ),

        // Route Colors
        SliverToBoxAdapter(
          child: _buildCategoryHeader('Color de Ruta', Icons.route_rounded),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: _buildItemsRow(
              context,
              StoreItems.byCategory(StoreCategory.routeColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoinsHeader(int coins) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B4F00), Color(0xFFFFB300)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.toll_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RUSH Coins',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$coins',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'Gana monedas',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                'corriendo y completando',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              Text(
                'misiones',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsRow(BuildContext context, List<StoreItem> items) {
    return SizedBox(
      height: 170,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _StoreItemCard(item: item, gamification: gamification);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STORE ITEM CARD
// ─────────────────────────────────────────────────────────────────────────────

class _StoreItemCard extends StatelessWidget {
  final StoreItem item;
  final GamificationService gamification;

  const _StoreItemCard({required this.item, required this.gamification});

  bool get _isPurchased => gamification.hasItem(item.id);

  bool get _isEquipped {
    switch (item.category) {
      case StoreCategory.avatarColor:
        return gamification.equippedAvatarColorId == item.id;
      case StoreCategory.avatarFrame:
        return gamification.equippedAvatarFrameId == item.id;
      case StoreCategory.routeColor:
        return gamification.equippedRouteColorId == item.id;
    }
  }

  bool get _canAfford => gamification.coins >= item.price;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: _isEquipped
            ? Border.all(color: AppColors.primary, width: 2)
            : _isPurchased
                ? Border.all(color: AppColors.success, width: 1.5)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Preview circle
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: item.color,
              shape: item.category == StoreCategory.avatarFrame
                  ? BoxShape.circle
                  : BoxShape.circle,
              border: item.category == StoreCategory.avatarFrame
                  ? Border.all(color: item.color, width: 4)
                  : null,
            ),
            child: Center(
              child: Text(
                item.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),

          // Name
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),

          // Button
          _buildButton(context),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    if (_isEquipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Equipado',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_isPurchased) {
      return GestureDetector(
        onTap: () => _equip(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Equipar',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
        ),
      );
    }

    // Not purchased — show price button
    return GestureDetector(
      onTap: _canAfford ? () => _confirmPurchase(context) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _canAfford
              ? const Color(0xFFFFB300).withAlpha(30)
              : AppColors.textMuted.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.toll_rounded,
              size: 11,
              color: _canAfford
                  ? const Color(0xFFFFB300)
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 3),
            Text(
              '${item.price}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _canAfford
                    ? const Color(0xFFFFB300)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPurchase(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          item.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(item.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.toll_rounded,
                  color: Color(0xFFFFB300),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.price} RUSH Coins',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB300),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Comprar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final purchased = await gamification.purchaseItem(item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              purchased != null
                  ? '${item.emoji} ${item.name} comprado y equipado!'
                  : 'No tienes suficientes coins.',
            ),
            backgroundColor:
                purchased != null ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _equip(BuildContext context) async {
    await gamification.equipStoreItem(item);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.emoji} ${item.name} equipado!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACHIEVEMENT CARD
// ─────────────────────────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementCard({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: isUnlocked
              ? Border.all(color: AppColors.secondary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.secondary.withAlpha(26)
                    : AppColors.textMuted.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked
                    ? AchievementIcons.getIcon(achievement.icon)
                    : Icons.lock_rounded,
                size: 26,
                color: isUnlocked ? AppColors.secondary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                achievement.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isUnlocked
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
            if (isUnlocked) ...[
              const SizedBox(height: 4),
              Text(
                '+${achievement.xpReward} XP',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.secondary.withAlpha(26)
                    : AppColors.textMuted.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUnlocked
                    ? AchievementIcons.getIcon(achievement.icon)
                    : Icons.lock_rounded,
                size: 48,
                color: isUnlocked ? AppColors.secondary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              achievement.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? AppColors.success.withAlpha(26)
                    : AppColors.secondary.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUnlocked
                        ? Icons.check_circle_rounded
                        : Icons.star_rounded,
                    color: isUnlocked ? AppColors.success : AppColors.secondary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isUnlocked
                        ? 'Desbloqueado'
                        : '+${achievement.xpReward} XP',
                    style: TextStyle(
                      color: isUnlocked
                          ? AppColors.success
                          : AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
