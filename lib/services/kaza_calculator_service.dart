class KazaCalculationResult {
  final int totalObligatedDays;
  final int totalPrayedDays;
  final int kazaDays;
  final Map<String, int> vakitKazalari;

  const KazaCalculationResult({
    required this.totalObligatedDays,
    required this.totalPrayedDays,
    required this.kazaDays,
    required this.vakitKazalari,
  });

  int get totalKazalar => vakitKazalari.values.fold(0, (sum, val) => sum + val);
}

class KazaCalculatorService {
  /// Calculate kaza debt based on bulug (puberty/accountability) date and prayed periods.
  static KazaCalculationResult calculate({
    required DateTime bulugDate,
    DateTime? currentDate,
    int prayedYears = 0,
    int prayedMonths = 0,
    int prayedDays = 0,
    Map<String, int>? specificVakitPrayedDays,
  }) {
    final now = currentDate ?? DateTime.now();
    final difference = now.difference(bulugDate);
    final totalObligatedDays = difference.inDays > 0 ? difference.inDays : 0;

    // Convert prayed years/months/days to total general prayed days
    final generalPrayedDays = (prayedYears * 365) + (prayedMonths * 30) + prayedDays;

    final vakitKeys = ['sabah', 'ogle', 'ikindi', 'aksam', 'yatsi', 'vitir'];
    final vakitKazalari = <String, int>{};

    for (final key in vakitKeys) {
      final specificDays = specificVakitPrayedDays?[key] ?? generalPrayedDays;
      final kazaCount = (totalObligatedDays - specificDays).clamp(0, 9999999);
      vakitKazalari[key] = kazaCount;
    }

    final kazaDays = (totalObligatedDays - generalPrayedDays).clamp(0, 9999999);

    return KazaCalculationResult(
      totalObligatedDays: totalObligatedDays,
      totalPrayedDays: generalPrayedDays,
      kazaDays: kazaDays,
      vakitKazalari: vakitKazalari,
    );
  }
}
