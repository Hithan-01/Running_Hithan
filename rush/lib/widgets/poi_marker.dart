import 'package:flutter/material.dart';
import '../models/poi.dart';
import '../utils/constants.dart';

class PoiMarkerWidget extends StatelessWidget {
  final Poi poi;
  final bool isVisited;
  final bool isNearby;
  final VoidCallback? onTap;

  const PoiMarkerWidget({
    super.key,
    required this.poi,
    this.isVisited = false,
    this.isNearby = false,
    this.onTap,
  });

  Color get categoryColor {
    switch (poi.category) {
      case PoiCategory.academic:
        return AppColors.poiAcademic;
      case PoiCategory.sports:
        return AppColors.poiSports;
      case PoiCategory.landmark:
        return AppColors.poiLandmark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isVisited ? categoryColor : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: isNearby ? AppColors.success : categoryColor,
                width: isNearby ? 3 : 2,
              ),
              boxShadow: [
                if (isNearby)
                  BoxShadow(
                    color: AppColors.success.withAlpha(128),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Text(
              poi.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(230),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              poi.name,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PoiInfoCard extends StatelessWidget {
  final Poi poi;
  final bool isVisited;
  final VoidCallback? onClose;

  const PoiInfoCard({
    super.key,
    required this.poi,
    this.isVisited = false,
    this.onClose,
  });

  Color get categoryColor {
    switch (poi.category) {
      case PoiCategory.academic:
        return AppColors.poiAcademic;
      case PoiCategory.sports:
        return AppColors.poiSports;
      case PoiCategory.landmark:
        return AppColors.poiLandmark;
    }
  }

  String get categoryName {
    switch (poi.category) {
      case PoiCategory.academic:
        return 'Academico';
      case PoiCategory.sports:
        return 'Deportivo';
      case PoiCategory.landmark:
        return 'Punto de Interes';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: categoryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  poi.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: categoryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            poi.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isVisited ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isVisited ? AppColors.success : AppColors.textMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isVisited ? 'Visitado' : 'No visitado',
                    style: TextStyle(
                      color: isVisited ? AppColors.success : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.secondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${poi.xpReward} XP',
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
        ],
      ),
    );
  }
}
