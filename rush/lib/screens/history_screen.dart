import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/gamification_service.dart';
import '../services/database_service.dart';
import '../widgets/run_stats_panel.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationService>(
      builder: (context, gamification, child) {
        final user = gamification.user;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final runs = DatabaseService.getAllRuns(user.id);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: CustomScrollView(
              slivers: [
                // App bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppColors.background,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  title: const Text(
                    'Actividad',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.filter_list_rounded,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),

                // Weekly summary card
                SliverToBoxAdapter(
                  child: _buildWeeklySummary(runs),
                ),

                // Runs list or empty state
                if (runs.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  _buildRunsSliverList(runs),

                // Bottom padding for nav bar
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklySummary(List runs) {
    // Calculate this week's stats
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekRuns = runs.where((r) {
      return r.createdAt.isAfter(DateTime(weekStart.year, weekStart.month, weekStart.day));
    }).toList();

    int weekDistance = 0;
    int weekDuration = 0;
    for (final r in weekRuns) {
      weekDistance += r.distance as int;
      weekDuration += r.duration as int;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2A3A), Color(0xFF2A3A4E)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Esta semana',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${weekRuns.length} ${weekRuns.length == 1 ? 'carrera' : 'carreras'}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    value: (weekDistance / 1000).toStringAsFixed(1),
                    unit: 'km',
                    label: 'Distancia',
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: Colors.white12,
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    value: Formatters.duration(weekDuration),
                    unit: '',
                    label: 'Tiempo',
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: Colors.white12,
                ),
                Expanded(
                  child: _buildSummaryMetric(
                    value: weekRuns.isNotEmpty
                        ? Formatters.pace(weekDuration > 0 && weekDistance > 0
                            ? (weekDuration / 60) / (weekDistance / 1000)
                            : 0)
                        : '--:--',
                    unit: '/km',
                    label: 'Ritmo prom.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String value,
    required String unit,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2, left: 2),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white54,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_run_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Sin actividades',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inicia tu primera carrera\npara ver tu historial aqui',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunsSliverList(List runs) {
    // Group runs by date
    final groupedRuns = <String, List>{};
    for (final run in runs) {
      final dateKey = _getRelativeDateHeader(run.createdAt);
      groupedRuns.putIfAbsent(dateKey, () => []).add(run);
    }

    final sections = groupedRuns.entries.toList();

    // Flatten into a list of items (headers + run cards)
    final List<_ListItem> items = [];
    for (final section in sections) {
      items.add(_ListItem(isHeader: true, headerTitle: section.key));
      for (final run in section.value) {
        items.add(_ListItem(isHeader: false, run: run));
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = items[index];
            if (item.isHeader) {
              return Padding(
                padding: EdgeInsets.only(
                  top: index == 0 ? 0 : 20,
                  bottom: 12,
                ),
                child: Text(
                  item.headerTitle!,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRunCard(item.run),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildRunCard(dynamic run) {
    final double km = (run.distance as int) / 1000;

    return Dismissible(
      key: Key(run.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _showDeleteConfirmation(context, run),
      onDismissed: (_) => _deleteRun(run),
      child: GestureDetector(
        onTap: () => _showRunDetails(run),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: activity type + time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.directions_run_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Carrera',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      Formatters.time(run.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            // XP badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '+${run.xpEarned} XP',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Distance - hero metric
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              km.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                height: 1,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 4, left: 4),
                              child: Text(
                                'km',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Stats row
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _buildCardStat(
                                Icons.timer_outlined,
                                Formatters.duration(run.duration),
                                'Tiempo',
                              ),
                              Container(
                                width: 1,
                                height: 28,
                                margin: const EdgeInsets.symmetric(horizontal: 12),
                                color: AppColors.textMuted.withAlpha(40),
                              ),
                              _buildCardStat(
                                Icons.speed_rounded,
                                Formatters.pace(run.avgPace),
                                'Ritmo',
                              ),
                              if ((run.poisVisited as List).isNotEmpty) ...[
                                Container(
                                  width: 1,
                                  height: 28,
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                  color: AppColors.textMuted.withAlpha(40),
                                ),
                                _buildCardStat(
                                  Icons.place_rounded,
                                  '${(run.poisVisited as List).length}',
                                  'POIs',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardStat(IconData icon, String value, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRelativeDateHeader(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Esta semana';
    if (diff < 30) return 'Este mes';
    return Formatters.date(date);
  }

  void _showRunDetails(dynamic run) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RunDetailScreen(run: run)),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, dynamic run) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Eliminar carrera',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Esta accion no se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _deleteRun(dynamic run) {
    DatabaseService.deleteRun(run.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Carrera eliminada'),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.error,
      ),
    );
    setState(() {});
  }
}

// Simple helper for flattened list
class _ListItem {
  final bool isHeader;
  final String? headerTitle;
  final dynamic run;

  _ListItem({required this.isHeader, this.headerTitle, this.run});
}

class RunDetailScreen extends StatelessWidget {
  final dynamic run;

  const RunDetailScreen({super.key, required this.run});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          Formatters.date(run.createdAt),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RunStatsPanel(
              distance: run.distance,
              duration: run.duration,
              pace: run.avgPace,
            ),
            const SizedBox(height: 24),
            _buildInfoSection(),
            const SizedBox(height: 24),
            if (run.poisVisited.isNotEmpty) _buildPoisSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.calendar_today_rounded,
            'Fecha',
            Formatters.dateTime(run.createdAt),
          ),
          _buildInfoRow(
            Icons.star_rounded,
            'XP Ganados',
            '+${run.xpEarned} XP',
          ),
          _buildInfoRow(
            Icons.place_rounded,
            'POIs Visitados',
            '${run.poisVisited.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'POIs Visitados',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (run.poisVisited as List).map<Widget>((poiId) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                poiId.toString(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
