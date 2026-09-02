import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaza_sayici/main.dart';
import 'package:kaza_sayici/services/daily_tracker_service.dart';
import 'package:kaza_sayici/services/kaza_calculator_service.dart';
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
    expect(find.text('Kaza Hesapla'), findsOneWidget);
  });

  test('DailyTrackerService logical date calculation before/after 2 AM', () {
    final nightTime = DateTime(2026, 9, 2, 1, 30);
    final logicalNight = DailyTrackerService.getLogicalDate(nightTime);
    expect(logicalNight.year, 2026);
    expect(logicalNight.month, 9);
    expect(logicalNight.day, 1);

    final morningTime = DateTime(2026, 9, 2, 2, 5);
    final logicalMorning = DailyTrackerService.getLogicalDate(morningTime);
    expect(logicalMorning.year, 2026);
    expect(logicalMorning.month, 9);
    expect(logicalMorning.day, 2);
  });

  test('KazaCalculatorService computes kaza debt correctly', () {
    final bulug = DateTime(2020, 1, 1);
    final current = DateTime(2025, 1, 1); // Exactly 5 years = 1827 days (including leap)

    // Prayed 2 years, 0 months, 0 days
    final result = KazaCalculatorService.calculate(
      bulugDate: bulug,
      currentDate: current,
      prayedYears: 2,
      prayedMonths: 0,
      prayedDays: 0,
    );

    expect(result.totalObligatedDays, 1827);
    expect(result.totalPrayedDays, 730);
    expect(result.kazaDays, 1097);
    expect(result.vakitKazalari['sabah'], 1097);
    expect(result.vakitKazalari['vitir'], 1097);
    expect(result.totalKazalar, 1097 * 6);
  });
}
