import 'package:flutter/material.dart';

enum StoreCategory { avatarColor, avatarFrame, routeColor }

class StoreItem {
  final String id;
  final String name;
  final int price;
  final StoreCategory category;
  final Color color;   // preview color
  final String emoji;

  const StoreItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.color,
    required this.emoji,
  });
}

class StoreItems {
  static const List<StoreItem> all = [
    // ── Avatar colors ─────────────────────────────────────────────────────────
    StoreItem(
      id: 'avatar_blue',
      name: 'Azul Campus',
      price: 50,
      category: StoreCategory.avatarColor,
      color: Color(0xFF1565C0),
      emoji: '🔵',
    ),
    StoreItem(
      id: 'avatar_purple',
      name: 'Morado',
      price: 75,
      category: StoreCategory.avatarColor,
      color: Color(0xFF6A1B9A),
      emoji: '🟣',
    ),
    StoreItem(
      id: 'avatar_green',
      name: 'Verde Bosque',
      price: 75,
      category: StoreCategory.avatarColor,
      color: Color(0xFF2E7D32),
      emoji: '🟢',
    ),
    StoreItem(
      id: 'avatar_red',
      name: 'Rojo Fuego',
      price: 100,
      category: StoreCategory.avatarColor,
      color: Color(0xFFC62828),
      emoji: '🔴',
    ),
    StoreItem(
      id: 'avatar_gold',
      name: 'Oro',
      price: 200,
      category: StoreCategory.avatarColor,
      color: Color(0xFFFFB300),
      emoji: '🌟',
    ),

    // ── Avatar frames ─────────────────────────────────────────────────────────
    StoreItem(
      id: 'frame_star',
      name: 'Marco Estrella',
      price: 100,
      category: StoreCategory.avatarFrame,
      color: Color(0xFFFFD700),
      emoji: '⭐',
    ),
    StoreItem(
      id: 'frame_fire',
      name: 'Marco Fuego',
      price: 150,
      category: StoreCategory.avatarFrame,
      color: Color(0xFFFF6D00),
      emoji: '🔥',
    ),
    StoreItem(
      id: 'frame_crown',
      name: 'Marco Corona',
      price: 300,
      category: StoreCategory.avatarFrame,
      color: Color(0xFFFFD700),
      emoji: '👑',
    ),

    // ── Route colors ──────────────────────────────────────────────────────────
    StoreItem(
      id: 'route_blue',
      name: 'Ruta Azul',
      price: 75,
      category: StoreCategory.routeColor,
      color: Color(0xFF1E88E5),
      emoji: '🔵',
    ),
    StoreItem(
      id: 'route_green',
      name: 'Ruta Verde',
      price: 75,
      category: StoreCategory.routeColor,
      color: Color(0xFF43A047),
      emoji: '🟢',
    ),
    StoreItem(
      id: 'route_purple',
      name: 'Ruta Morada',
      price: 100,
      category: StoreCategory.routeColor,
      color: Color(0xFF8E24AA),
      emoji: '🟣',
    ),
    StoreItem(
      id: 'route_pink',
      name: 'Ruta Rosa',
      price: 100,
      category: StoreCategory.routeColor,
      color: Color(0xFFE91E63),
      emoji: '🌸',
    ),
  ];

  static StoreItem? getById(String id) {
    try {
      return all.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<StoreItem> byCategory(StoreCategory cat) =>
      all.where((i) => i.category == cat).toList();
}
