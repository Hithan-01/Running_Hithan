import 'package:hive_ce/hive.dart';
import 'package:rush/models/run.dart';
import 'package:rush/models/poi.dart';
import 'package:rush/models/user.dart';
import 'package:rush/models/notification_item.dart';
import 'package:rush/models/mission.dart';
import 'package:rush/models/achievement.dart';

extension HiveRegistrar on HiveInterface {
  void registerAdapters() {
    registerAdapter(RunAdapter());
    registerAdapter(RunPointAdapter());
    registerAdapter(PoiAdapter());
    registerAdapter(VisitedPoiAdapter());
    registerAdapter(UserAdapter());
    registerAdapter(NotificationItemAdapter());
    registerAdapter(MissionAdapter());
    registerAdapter(ActiveMissionAdapter());
    registerAdapter(AchievementAdapter());
    registerAdapter(UnlockedAchievementAdapter());
  }
}
