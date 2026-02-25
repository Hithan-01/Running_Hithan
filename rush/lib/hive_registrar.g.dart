import 'package:hive_ce/hive.dart';
import 'package:rush/models/achievement.dart';
import 'package:rush/models/mission.dart';
import 'package:rush/models/notification_item.dart';
import 'package:rush/models/poi.dart';
import 'package:rush/models/run.dart';
import 'package:rush/models/user.dart';

extension HiveRegistrar on HiveInterface {
  void registerAdapters() {
    registerAdapter(AchievementAdapter());
    registerAdapter(UnlockedAchievementAdapter());
    registerAdapter(MissionAdapter());
    registerAdapter(ActiveMissionAdapter());
    registerAdapter(NotificationItemAdapter());
    registerAdapter(PoiAdapter());
    registerAdapter(VisitedPoiAdapter());
    registerAdapter(RunAdapter());
    registerAdapter(RunPointAdapter());
    registerAdapter(UserAdapter());
  }
}
