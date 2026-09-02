import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaza_sayici/main.dart';
import 'package:kaza_sayici/services/daily_tracker_service.dart';
import 'package:kaza_sayici/services/gender_service.dart';
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

  test('KazaCalculatorService computes male and female kaza debt correctly', () {
    final bulug = DateTime(2020, 1, 1);
    final current = DateTime(2025, 1, 1); // 1827 days

    // Male calculation (no exemption)
    final maleResult = KazaCalculatorService.calculate(
      bulugDate: bulug,
      currentDate: current,
      prayedYears: 2,
      prayedMonths: 0,
      prayedDays: 0,
      isFemale: false,
    );

    expect(maleResult.totalObligatedDays, 1827);
    expect(maleResult.totalPrayedDays, 730);
    expect(maleResult.exemptDays, 0);
    expect(maleResult.kazaDays, 1097);
    expect(maleResult.totalKazalar, 1097 * 6);

    // Female calculation (25% exemption from unprayed days: 1097 ~/ 4 = 274 days exempt)
    final femaleResult = KazaCalculatorService.calculate(
      bulugDate: bulug,
      currentDate: current,
      prayedYears: 2,
      prayedMonths: 0,
      prayedDays: 0,
      isFemale: true,
    );

    expect(femaleResult.totalObligatedDays, 1827);
    expect(femaleResult.totalPrayedDays, 730);
    expect(femaleResult.exemptDays, 274);
    expect(femaleResult.kazaDays, 1097 - 274); // 823 days
    expect(femaleResult.totalKazalar, 823 * 6);
  });

  test('GenderService and Special Day mode persistence', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await GenderService.getGender(), 'erkek');
    expect(await GenderService.isFemale(), false);
    expect(await GenderService.isSpecialDayActive(), false);

    await GenderService.setGender('kadin');
    expect(await GenderService.isFemale(), true);

    await GenderService.setSpecialDayActive(true);
    expect(await GenderService.isSpecialDayActive(), true);

    await GenderService.setSpecialDayActive(false);
    expect(await GenderService.isSpecialDayActive(), false);
  });
}
