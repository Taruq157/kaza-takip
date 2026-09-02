class KazaCalculationResult {
  final int totalObligatedDays;
  final int totalPrayedDays;
  final int kazaDays;
  final int exemptDays;
  final bool isFemale;
  final Map<String, int> vakitKazalari;

  const KazaCalculationResult({
    required this.totalObligatedDays,
    required this.totalPrayedDays,
    required this.kazaDays,
    this.exemptDays = 0,
    this.isFemale = false,
    required this.vakitKazalari,
  });

  int get totalKazalar => vakitKazalari.values.fold(0, (sum, val) => sum + val);
}

class KazaCalculatorService {
  /// Calculate kaza debt based on bulug (puberty/accountability) date and prayed periods.
  /// If [isFemale] is true, 1 week out of every 4 weeks (25% muafiyet) is deducted from unprayed days.
  static KazaCalculationResult calculate({
    required DateTime bulugDate,
    DateTime? currentDate,
    int prayedYears = 0,
    int prayedMonths = 0,
    int prayedDays = 0,
    bool isFemale = false,
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
      final rawUnprayed = (totalObligatedDays - specificDays).clamp(0, 9999999);
      final rawExempt = isFemale ? (rawUnprayed ~/ 4) : 0;
      final kazaCount = (rawUnprayed - rawExempt).clamp(0, 9999999);
      vakitKazalari[key] = kazaCount;
    }

    final rawGeneralUnprayed = (totalObligatedDays - generalPrayedDays).clamp(0, 9999999);
    final exemptDays = isFemale ? (rawGeneralUnprayed ~/ 4) : 0;
    final kazaDays = (rawGeneralUnprayed - exemptDays).clamp(0, 9999999);

    return KazaCalculationResult(
      totalObligatedDays: totalObligatedDays,
      totalPrayedDays: generalPrayedDays,
      kazaDays: kazaDays,
      exemptDays: exemptDays,
      isFemale: isFemale,
      vakitKazalari: vakitKazalari,
    );
  }
}
