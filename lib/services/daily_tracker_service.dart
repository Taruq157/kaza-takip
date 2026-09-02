import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'gender_service.dart';

class DailyTransitionResult {
  final bool hasTransitioned;
  final Map<String, int> addedKazalar;
  final int daysMissed;
  final bool wasExempt;

  DailyTransitionResult({
    required this.hasTransitioned,
    required this.addedKazalar,
    required this.daysMissed,
    this.wasExempt = false,
  });

  int get totalAdded => addedKazalar.values.fold(0, (sum, val) => sum + val);
}

class DailyTrackerService {
  static const List<String> prayerKeys = [
    'sabah',
    'ogle',
    'ikindi',
    'aksam',
    'yatsi',
    'vitir',
  ];

  /// The day boundary is at 02:00 AM.
  /// If now is 01:30 AM on 2nd September, logical date is 1st September.
  /// If now is 02:05 AM on 2nd September, logical date is 2nd September.
  static DateTime getLogicalDate([DateTime? target]) {
    final now = target ?? DateTime.now();
    if (now.hour < 2) {
      final prev = now.subtract(const Duration(days: 1));
      return DateTime(prev.year, prev.month, prev.day);
    }
    return DateTime(now.year, now.month, now.day);
  }

  static String formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Check if the day has transitioned past 02:00 AM and add unticked prayers to kaza counts.
  /// If the user is female and Special Day (Regl) mode is active, prayers are exempt from kaza debt.
  static Future<DailyTransitionResult> checkAndProcessDailyTransition() async {
    final prefs = await SharedPreferences.getInstance();
    final todayLogical = getLogicalDate();
    final todayKey = formatDateKey(todayLogical);

    final lastActiveKey = prefs.getString('last_logical_date');
    if (lastActiveKey == null) {
      // First time launch: Initialize with today
      await prefs.setString('last_logical_date', todayKey);
      return DailyTransitionResult(
        hasTransitioned: false,
        addedKazalar: {},
        daysMissed: 0,
      );
    }

    if (lastActiveKey == todayKey) {
      // Already up to date for today
      return DailyTransitionResult(
        hasTransitioned: false,
        addedKazalar: {},
        daysMissed: 0,
      );
    }

    // A transition occurred! (1 or more days passed)
    DateTime lastDate;
    try {
      final parts = lastActiveKey.split('-').map(int.parse).toList();
      lastDate = DateTime(parts[0], parts[1], parts[2]);
    } catch (_) {
      lastDate = todayLogical.subtract(const Duration(days: 1));
    }

    final isSpecialExempt = await GenderService.isSpecialDayActive();

    final addedKazalar = <String, int>{
      'sabah': 0,
      'ogle': 0,
      'ikindi': 0,
      'aksam': 0,
      'yatsi': 0,
      'vitir': 0,
    };

    int daysMissed = 0;
    DateTime cursor = lastDate;

    // Process from lastDate up to todayLogical - 1 day
    while (cursor.isBefore(todayLogical)) {
      final cursorKey = formatDateKey(cursor);
      final rawTicks = prefs.getString('ticks_$cursorKey');
      Map<String, dynamic> ticks = {};
      if (rawTicks != null) {
        try {
          ticks = jsonDecode(rawTicks) as Map<String, dynamic>;
        } catch (_) {}
      }

      // Only add to kaza if not in special exemption mode
      if (!isSpecialExempt) {
        for (final key in prayerKeys) {
          final isTicked = ticks[key] == true;
          if (!isTicked) {
            addedKazalar[key] = (addedKazalar[key] ?? 0) + 1;
          }
        }
      }

      daysMissed++;
      cursor = cursor.add(const Duration(days: 1));
    }

    // Apply added kazalar to stored kaza counts if not exempt
    if (!isSpecialExempt) {
      for (final key in prayerKeys) {
        final add = addedKazalar[key] ?? 0;
        if (add > 0) {
          final currentCount = prefs.getInt('kaza_$key') ?? 0;
          await prefs.setInt('kaza_$key', currentCount + add);
        }
      }
    }

    // Update last logical date
    await prefs.setString('last_logical_date', todayKey);

    return DailyTransitionResult(
      hasTransitioned: true,
      addedKazalar: addedKazalar,
      daysMissed: daysMissed,
      wasExempt: isSpecialExempt,
    );
  }

  /// Get ticks for today's logical date
  static Future<Map<String, bool>> getTodayTicks() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = formatDateKey(getLogicalDate());
    final raw = prefs.getString('ticks_$todayKey');
    if (raw == null) {
      return {for (var k in prayerKeys) k: false};
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return {for (var k in prayerKeys) k: map[k] == true};
    } catch (_) {
      return {for (var k in prayerKeys) k: false};
    }
  }

  /// Set a tick for today's logical date
  static Future<void> setTodayTick(String prayerKey, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = formatDateKey(getLogicalDate());
    final currentTicks = await getTodayTicks();
    currentTicks[prayerKey] = value;
    await prefs.setString('ticks_$todayKey', jsonEncode(currentTicks));
  }
}
