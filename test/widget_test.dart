import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaza_sayici/main.dart';
import 'package:kaza_sayici/services/daily_tracker_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('KazaSayiciApp loads smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const KazaSayiciApp());
    await tester.pumpAndSettle();

    expect(find.text('Kaza Takipçisi'), findsWidgets);
    expect(find.text('Sabah'), findsWidgets);
    expect(find.text('Öğle'), findsWidgets);
    expect(find.text('İkindi'), findsWidgets);
    expect(find.text('Akşam'), findsWidgets);
    expect(find.text('Yatsı'), findsWidgets);
    expect(find.text('Vitir'), findsOneWidget);
    expect(find.text('Toplam Kaza Namazı'), findsOneWidget);
  });

  test('DailyTrackerService logical date calculation before/after 2 AM', () {
    // 01:30 AM on 2026-09-02 should be logical date 2026-09-01
    final nightTime = DateTime(2026, 9, 2, 1, 30);
    final logicalNight = DailyTrackerService.getLogicalDate(nightTime);
    expect(logicalNight.year, 2026);
    expect(logicalNight.month, 9);
    expect(logicalNight.day, 1);

    // 02:05 AM on 2026-09-02 should be logical date 2026-09-02
    final morningTime = DateTime(2026, 9, 2, 2, 5);
    final logicalMorning = DailyTrackerService.getLogicalDate(morningTime);
    expect(logicalMorning.year, 2026);
    expect(logicalMorning.month, 9);
    expect(logicalMorning.day, 2);
  });
}
