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
    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Historial actualizado'),
          duration: Duration(seconds: 1),
          backgroundColor: AppColors.success,
        ),
      );
    }
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
          appBar: AppBar(
            title: const Text(
              'Historial',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.background,
            elevation: 0,
          ),
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            child: runs.isEmpty
                ? _buildEmptyState()
                : _buildRunsList(runs, gamification),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_run,
            size: 80,
            color: AppColors.textMuted.withAlpha(128),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin carreras aun',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Inicia tu primera carrera para ver tu historial',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunsList(List runs, GamificationService gamification) {
    // Group runs by date
    final groupedRuns = <String, List>{};

    for (final run in runs) {
      final dateKey = Formatters.date(run.createdAt);
      groupedRuns.putIfAbsent(dateKey, () => []).add(run);
    }

    final sortedKeys = groupedRuns.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dateRuns = groupedRuns[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _getRelativeDateHeader(dateRuns.first.createdAt),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // Runs for this date
            ...dateRuns.map((run) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Dismissible(
                    key: Key(run.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await _showDeleteConfirmation(context, run);
                    },
                    onDismissed: (direction) {
                      _deleteRun(run);
                    },
                    child: RunSummaryCard(
                      distance: run.distance,
                      duration: run.duration,
                      pace: run.avgPace,
                      xpEarned: run.xpEarned,
                      poisVisited: run.poisVisited.length,
                      date: run.createdAt,
                      onTap: () => _showRunDetails(run),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, dynamic run) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Eliminar carrera',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Estas seguro de que quieres eliminar esta carrera? Esta accion no se puede deshacer.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
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
    // Could navigate to a detailed run view
    // For MVP, the card shows enough info
  }
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
            // Stats panel
            RunStatsPanel(
              distance: run.distance,
              duration: run.duration,
              pace: run.avgPace,
            ),
            const SizedBox(height: 24),

            // Run info
            _buildInfoSection(),
            const SizedBox(height: 24),

            // POIs visited
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
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
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
