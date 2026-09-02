import 'dart:async';
import 'package:home_widget/home_widget.dart';
import 'daily_tracker_service.dart';
import 'prayer_time_service.dart';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'toggletick') {
    final key = uri?.queryParameters['key'] ?? 'ogle';
    final ticks = await DailyTrackerService.getTodayTicks();
    final currentVal = ticks[key] ?? false;
    final newVal = !currentVal;
    await DailyTrackerService.setTodayTick(key, newVal);

    // Update widget data immediately
    final updatedTicks = await DailyTrackerService.getTodayTicks();
    final prayerInfo = PrayerTimeService.calculatePrayerTimes();
    await WidgetService.updateAllWidgets(prayerInfo: prayerInfo, ticks: updatedTicks);
  }
}

class WidgetService {
  static const String _prayerTimesWidget = 'PrayerTimesWidgetProvider';
  static const String _currentTickWidget = 'CurrentPrayerTickWidgetProvider';

  static Future<void> initialize() async {
    try {
      await HomeWidget.registerInteractivityCallback(backgroundCallback);
    } catch (_) {}
  }

  static String _mapCurrentToVakitKey(String currentPrayerTitle) {
    final lower = currentPrayerTitle.toLowerCase();
    if (lower.contains('imsak') || lower.contains('sabah')) return 'imsak';
    if (lower.contains('güneş') || lower.contains('gunes')) return 'gunes';
    if (lower.contains('öğle') || lower.contains('ogle')) return 'ogle';
    if (lower.contains('ikindi')) return 'ikindi';
    if (lower.contains('akşam') || lower.contains('aksam')) return 'aksam';
    if (lower.contains('yatsı') || lower.contains('yatsi')) return 'yatsi';
    return 'ogle';
  }

  static String _mapCurrentToDailyPrayerKey(String currentPrayerTitle) {
    final lower = currentPrayerTitle.toLowerCase();
    if (lower.contains('imsak') || lower.contains('sabah') || lower.contains('güneş') || lower.contains('gunes')) return 'sabah';
    if (lower.contains('öğle') || lower.contains('ogle')) return 'ogle';
    if (lower.contains('ikindi')) return 'ikindi';
    if (lower.contains('akşam') || lower.contains('aksam')) return 'aksam';
    if (lower.contains('yatsı') || lower.contains('yatsi')) return 'yatsi';
    return 'ogle';
  }

  static Future<void> updateAllWidgets({
    PrayerDisplayInfo? prayerInfo,
    Map<String, bool>? ticks,
  }) async {
    try {
      final info = prayerInfo ?? PrayerTimeService.calculatePrayerTimes();
      final todayTicks = ticks ?? await DailyTrackerService.getTodayTicks();

      final activeVakitKey = _mapCurrentToVakitKey(info.currentPrayerTitle);
      final activeDailyPrayerKey = _mapCurrentToDailyPrayerKey(info.currentPrayerTitle);
      final isTicked = todayTicks[activeDailyPrayerKey] ?? false;

      // Extract times from timeline
      String timeImsak = '04:50';
      String timeGunes = '06:20';
      String timeOgle = '13:05';
      String timeIkindi = '17:40';
      String timeAksam = '19:40';
      String timeYatsi = '21:05';

      for (final item in info.timeline) {
        if (item.key == 'imsak') timeImsak = item.timeString;
        if (item.key == 'gunes') timeGunes = item.timeString;
        if (item.key == 'ogle') timeOgle = item.timeString;
        if (item.key == 'ikindi') timeIkindi = item.timeString;
        if (item.key == 'aksam') timeAksam = item.timeString;
        if (item.key == 'yatsi') timeYatsi = item.timeString;
      }

      // 1. Data for 4x2 Prayer Times Widget
      await HomeWidget.saveWidgetData<String>('widget_location_name', PrayerTimeService.locationName);
      await HomeWidget.saveWidgetData<String>('widget_current_prayer', 'Şu an: ${info.currentPrayerTitle}');
      await HomeWidget.saveWidgetData<String>('widget_countdown_title', '${info.nextPrayerTitle}\'e Kalan');
      await HomeWidget.saveWidgetData<String>('widget_countdown_time', info.timeRemainingString);

      await HomeWidget.saveWidgetData<String>('time_imsak', timeImsak);
      await HomeWidget.saveWidgetData<String>('time_gunes', timeGunes);
      await HomeWidget.saveWidgetData<String>('time_ogle', timeOgle);
      await HomeWidget.saveWidgetData<String>('time_ikindi', timeIkindi);
      await HomeWidget.saveWidgetData<String>('time_aksam', timeAksam);
      await HomeWidget.saveWidgetData<String>('time_yatsi', timeYatsi);
      await HomeWidget.saveWidgetData<String>('active_vakit_key', activeVakitKey);

      // 2. Data for 2x1 Current Prayer Tick Widget
      await HomeWidget.saveWidgetData<String>('active_prayer_key', activeDailyPrayerKey);
      await HomeWidget.saveWidgetData<String>('active_prayer_name', '${info.currentPrayerTitle} Namazı');
      await HomeWidget.saveWidgetData<String>('active_prayer_time', '${PrayerTimeService.locationName} • Kaza Takipçisi');
      await HomeWidget.saveWidgetData<bool>('active_prayer_ticked', isTicked);

      // Trigger Widget updates
      await HomeWidget.updateWidget(name: _prayerTimesWidget, androidName: _prayerTimesWidget);
      await HomeWidget.updateWidget(name: _currentTickWidget, androidName: _currentTickWidget);
    } catch (_) {}
  }
}
