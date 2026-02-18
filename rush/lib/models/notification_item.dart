import 'package:hive_ce/hive.dart';

part 'notification_item.g.dart';

@HiveType(typeId: 9)
class NotificationItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String title;

  @HiveField(3)
  String body;

  @HiveField(4)
  String type; // 'streak', 'achievement', 'mission', 'level_up'

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  bool isRead;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });
}
