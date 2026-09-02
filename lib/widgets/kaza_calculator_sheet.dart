import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/gender_service.dart';
import '../services/kaza_calculator_service.dart';

class KazaCalculatorSheet extends StatefulWidget {
  final Function(Map<String, int> calculatedCounts, bool overwrite) onApply;
  final VoidCallback? onGenderChanged;

  const KazaCalculatorSheet({
    super.key,
    required this.onApply,
    this.onGenderChanged,
  });

  @override
  State<KazaCalculatorSheet> createState() => _KazaCalculatorSheetState();
}

class _KazaCalculatorSheetState extends State<KazaCalculatorSheet> {
  DateTime _bulugDate = DateTime.now().subtract(const Duration(days: 365 * 10)); // Default 10 years ago
  int _prayedYears = 0;
  int _prayedMonths = 0;
  int _prayedDays = 0;
  bool _isFemale = false;

  final TextEditingController _yearsController = TextEditingController(text: '0');
  final TextEditingController _monthsController = TextEditingController(text: '0');
  final TextEditingController _daysController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadGender();
  }

  Future<void> _loadGender() async {
    final isFem = await GenderService.isFemale();
    if (mounted) {
      setState(() {
        _isFemale = isFem;
      });
    }
  }

  @override
  void dispose() {
    _yearsController.dispose();
    _monthsController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  KazaCalculationResult get _result {
    return KazaCalculatorService.calculate(
      bulugDate: _bulugDate,
      prayedYears: _prayedYears,
      prayedMonths: _prayedMonths,
      prayedDays: _prayedDays,
      isFemale: _isFemale,
    );
  }

  Future<void> _pickBulugDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _bulugDate,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      helpText: 'Ergenlik (Bülûğ) Tarihinizi Seçin',
      confirmText: 'Seç',
      cancelText: 'İptal',
    );
    if (picked != null) {
      setState(() {
        _bulugDate = picked;
      });
    }
  }

  void _showApplyDialog(KazaCalculationResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hesaplanan Kazaları Aktar'),
        content: Text(
          'Her vakit için ${result.kazaDays} adet kaza namazı hesaplandı.\n\nNasıl aktarmak istersiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await GenderService.setGender(_isFemale ? 'kadin' : 'erkek');
              widget.onGenderChanged?.call();
              if (mounted) {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                widget.onApply(result.vakitKazalari, false); // Add to current
              }
            },
            child: const Text('Mevcut Kazalara Ekle'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              await GenderService.setGender(_isFemale ? 'kadin' : 'erkek');
              widget.onGenderChanged?.call();
              if (mounted) {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
                widget.onApply(result.vakitKazalari, true); // Overwrite
              }
            },
            child: const Text('Sayaçları Güncelle'),
          ),
        ],
      ),
    );
  }

  static const _turkishMonths = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  String _formatDateTurkish(DateTime date) {
    return '${date.day} ${_turkishMonths[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = _result;
    final formattedDate = _formatDateTurkish(_bulugDate);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calculate_rounded,
                    color: Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kaza Namazı Hesaplayıcı',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ergenlik, cinsiyet ve kılınan süreye göre hesaplama',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Cinsiyet Seçimi (Erkek / Kadın)
            Text(
              'CİNSİYET SEÇİMİ',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isFemale = false;
                        });
                        GenderService.setGender('erkek');
                        widget.onGenderChanged?.call();
                      },
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isFemale
                              ? (isDark ? const Color(0xFF2563EB) : const Color(0xFF3B82F6))
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.male_rounded,
                              size: 20,
                              color: !_isFemale ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Erkek',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isFemale ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _isFemale = true;
                        });
                        GenderService.setGender('kadin');
                        widget.onGenderChanged?.call();
                      },
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(15)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isFemale
                              ? const Color(0xFFEC4899)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.female_rounded,
                              size: 20,
                              color: _isFemale ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kadın',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isFemale ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isFemale) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withOpacity(isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFEC4899).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.favorite_rounded, color: Color(0xFFEC4899), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kadınlarda her 4 haftanın 1 haftası (ayda ~7 gün / %25) özel gün (hayız) kabul edilerek kaza borcundan muaf tutulur ve otomatik olarak düşülür.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: isDark ? const Color(0xFFFBCFE8) : const Color(0xFF9D174D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 1. Adım: Ergenlik (Bülûğ) Tarihi Seçimi
            Text(
              '1. ERGENLİK (BÜLÛĞ) TARİHİ',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickBulugDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Toplam Süre: ${result.totalObligatedDays} gün (~${(result.totalObligatedDays / 365).toStringAsFixed(1)} yıl)',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar_rounded, size: 20, color: Color(0xFF10B981)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. Adım: Düzenli Kılınan Tahmini Süre
            Text(
              '2. DÜZENLİ KILDIĞINIZ TAHMİNİ SÜRE',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DurationInputField(
                    label: 'Yıl',
                    controller: _yearsController,
                    isDark: isDark,
                    onChanged: (val) {
                      setState(() {
                        _prayedYears = int.tryParse(val) ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DurationInputField(
                    label: 'Ay',
                    controller: _monthsController,
                    isDark: isDark,
                    onChanged: (val) {
                      setState(() {
                        _prayedMonths = int.tryParse(val) ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DurationInputField(
                    label: 'Gün',
                    controller: _daysController,
                    isDark: isDark,
                    onChanged: (val) {
                      setState(() {
                        _prayedDays = int.tryParse(val) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. Bilgilendirme / İhtiyat Notu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Geçmişe dönük kesin tarihi hatırlamıyorsanız, kalbinizin ve kanaatinizin en çok yattığı tahmini süreyi giriniz. İhtiyatlı olmak adına kılınmadığından emin olunmayan süreler kazaya dahil edilebilir.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Hesaplama Sonucu Özeti
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                      : [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_isFemale && result.exemptDays > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Özel Gün (Hayız) Muafiyeti:',
                          style: TextStyle(color: Color(0xFFFBCFE8), fontSize: 12),
                        ),
                        Text(
                          '- ${result.exemptDays} Gün',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFFBCFE8),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 14),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Net Kaza Borcu (Gün)',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${result.kazaDays} Gün',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Toplam Vakit Sayısı (6 Vakit)',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        '${result.totalKazalar} Vakit',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 16),
                  Text(
                    'Sabah, Öğle, İkindi, Akşam, Yatsı ve Vitir için her birine ${result.kazaDays} kaza atanacaktır.',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Aktar Butonu
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showApplyDialog(result),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: const Text(
                  'Bu Sayıları Kazalarıma Aktar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _DurationInputField({
    required this.label,
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
