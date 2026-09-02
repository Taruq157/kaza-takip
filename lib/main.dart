import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/daily_tracker_service.dart';
import 'services/prayer_time_service.dart';
import 'services/widget_service.dart';
import 'widgets/kaza_calculator_sheet.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('tr_TR', null);
  } catch (_) {}
  try {
    await WidgetService.initialize();
    await WidgetService.updateAllWidgets();
  } catch (_) {}
  runApp(const KazaSayiciApp());
}

class SoundService {
  static final AudioPlayer _artirPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _azaltPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _tikPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static final AudioPlayer _tikGeriPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  static bool isMuted = false;

  static void playKazaArtir() {
    if (isMuted) return;
    try {
      _artirPlayer.stop().then((_) => _artirPlayer.play(
            AssetSource('sounds/kaza_artir.mp3'),
            mode: PlayerMode.lowLatency,
          ));
    } catch (_) {}
  }

  static void playKazaAzalt() {
    if (isMuted) return;
    try {
      _azaltPlayer.stop().then((_) => _azaltPlayer.play(
            AssetSource('sounds/kaza_azalt.mp3'),
            mode: PlayerMode.lowLatency,
          ));
    } catch (_) {}
  }

  static void playNamazTik() {
    if (isMuted) return;
    try {
      _tikPlayer.stop().then((_) => _tikPlayer.play(
            AssetSource('sounds/namaz_tik.mp3'),
            mode: PlayerMode.lowLatency,
          ));
    } catch (_) {}
  }

  static void playNamazTikGeri() {
    if (isMuted) return;
    try {
      _tikGeriPlayer.stop().then((_) => _tikGeriPlayer.play(
            AssetSource('sounds/namaz_tik_geri.mp3'),
            mode: PlayerMode.lowLatency,
          ));
    } catch (_) {}
  }
}

class KazaSayiciApp extends StatefulWidget {
  const KazaSayiciApp({super.key});

  @override
  State<KazaSayiciApp> createState() => _KazaSayiciAppState();
}

class _KazaSayiciAppState extends State<KazaSayiciApp> {
  bool _isDarkMode = true;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kaza Takipçisi',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF0F766E),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF10B981),
        scaffoldBackgroundColor: const Color(0xFF0B1329),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      ),
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class PrayerInfo {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  const PrayerInfo({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final List<PrayerInfo> _prayers = const [
    PrayerInfo(
      key: 'sabah',
      title: 'Sabah',
      subtitle: '2 Rekât Farz',
      icon: Icons.wb_twilight_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    PrayerInfo(
      key: 'ogle',
      title: 'Öğle',
      subtitle: '4 Rekât Farz',
      icon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFEAB308),
    ),
    PrayerInfo(
      key: 'ikindi',
      title: 'İkindi',
      subtitle: '4 Rekât Farz',
      icon: Icons.wb_cloudy_rounded,
      accentColor: Color(0xFFF97316),
    ),
    PrayerInfo(
      key: 'aksam',
      title: 'Akşam',
      subtitle: '3 Rekât Farz',
      icon: Icons.nights_stay_rounded,
      accentColor: Color(0xFF8B5CF6),
    ),
    PrayerInfo(
      key: 'yatsi',
      title: 'Yatsı',
      subtitle: '4 Rekât Farz',
      icon: Icons.dark_mode_rounded,
      accentColor: Color(0xFF6366F1),
    ),
    PrayerInfo(
      key: 'vitir',
      title: 'Vitir',
      subtitle: '3 Rekât Vacip',
      icon: Icons.star_rounded,
      accentColor: Color(0xFF10B981),
    ),
  ];

  final Map<String, int> _counts = {
    'sabah': 0,
    'ogle': 0,
    'ikindi': 0,
    'aksam': 0,
    'yatsi': 0,
    'vitir': 0,
  };

  Map<String, bool> _todayTicks = {
    'sabah': false,
    'ogle': false,
    'ikindi': false,
    'aksam': false,
    'yatsi': false,
    'vitir': false,
  };

  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isRefreshingLocation = false;
  bool _soundMuted = false;

  Timer? _tickerTimer;
  PrayerDisplayInfo? _prayerDisplayInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (var prayer in _prayers) {
      _controllers[prayer.key] = TextEditingController(text: '0');
    }
    _initApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickerTimer?.cancel();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkDailyTransition();
      _updatePrayerTimes();
    }
  }

  Future<void> _initApp() async {
    await _loadCounts();
    await PrayerTimeService.initLocation();
    _updatePrayerTimes();

    // 1-second live countdown timer
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updatePrayerTimes();
      }
    });

    await _checkDailyTransition();
    await WidgetService.updateAllWidgets(prayerInfo: _prayerDisplayInfo, ticks: _todayTicks);
  }

  void _updatePrayerTimes() {
    setState(() {
      _prayerDisplayInfo = PrayerTimeService.calculatePrayerTimes();
    });
  }

  Future<void> _refreshLocation() async {
    if (_isRefreshingLocation) return;
    setState(() {
      _isRefreshingLocation = true;
    });
    HapticFeedback.lightImpact();
    await PrayerTimeService.initLocation();
    if (mounted) {
      setState(() {
        _isRefreshingLocation = false;
        _updatePrayerTimes();
      });
      WidgetService.updateAllWidgets(prayerInfo: _prayerDisplayInfo, ticks: _todayTicks);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Konum güncellendi: ${PrayerTimeService.locationName}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
      );
    }
  }

  Future<void> _checkDailyTransition() async {
    final result = await DailyTrackerService.checkAndProcessDailyTransition();
    final ticks = await DailyTrackerService.getTodayTicks();

    if (mounted) {
      setState(() {
        _todayTicks = ticks;
      });

      if (result.hasTransitioned && result.totalAdded > 0) {
        await _loadCounts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gece 02:00 kuralı: Kılınmayan ${result.totalAdded} vakit kazalarınıza eklendi.',
              ),
              backgroundColor: const Color(0xFFD97706),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final ticks = await DailyTrackerService.getTodayTicks();
    setState(() {
      _soundMuted = prefs.getBool('sound_muted') ?? false;
      SoundService.isMuted = _soundMuted;
      _todayTicks = ticks;
      for (var prayer in _prayers) {
        final val = prefs.getInt('kaza_${prayer.key}') ?? 0;
        _counts[prayer.key] = val;
        _controllers[prayer.key]?.text = val.toString();
      }
      _isLoading = false;
    });
  }

  Future<void> _saveCount(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kaza_$key', value);
  }

  Future<void> _toggleSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundMuted = !_soundMuted;
      SoundService.isMuted = _soundMuted;
    });
    await prefs.setBool('sound_muted', _soundMuted);
    if (!_soundMuted) {
      SoundService.playKazaArtir();
    }
  }

  Future<void> _toggleDailyTick(String key, String title) async {
    HapticFeedback.lightImpact();
    final currentVal = _todayTicks[key] ?? false;
    final newVal = !currentVal;

    setState(() {
      _todayTicks[key] = newVal;
    });

    if (newVal) {
      SoundService.playNamazTik();
    } else {
      SoundService.playNamazTikGeri();
    }
    await DailyTrackerService.setTodayTick(key, newVal);
    WidgetService.updateAllWidgets(prayerInfo: _prayerDisplayInfo, ticks: _todayTicks);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newVal ? Icons.check_circle_rounded : Icons.info_outline,
                color: newVal ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  newVal
                      ? 'Bugünkü $title namazı kılındı olarak işaretlendi.'
                      : 'Bugünkü $title namazı işareti kaldırıldı.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
      );
    }
  }

  void _updateCount(String key, int delta) {
    HapticFeedback.lightImpact();
    if (delta > 0) {
      SoundService.playKazaArtir();
    } else {
      SoundService.playKazaAzalt();
    }
    setState(() {
      final current = _counts[key] ?? 0;
      final newVal = (current + delta).clamp(0, 9999999);
      _counts[key] = newVal;
      _controllers[key]?.text = newVal.toString();
      _saveCount(key, newVal);
    });
  }

  void _setCount(String key, int value) {
    setState(() {
      final newVal = value.clamp(0, 9999999);
      _counts[key] = newVal;
      _controllers[key]?.text = newVal.toString();
      _saveCount(key, newVal);
    });
  }

  void _completeFullDay() {
    bool hasAny = _counts.values.any((v) => v > 0);
    if (!hasAny) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Kılınacak kaza namazı bulunmuyor.',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF334155), width: 1),
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    SoundService.playKazaAzalt();
    setState(() {
      for (var prayer in _prayers) {
        final current = _counts[prayer.key] ?? 0;
        if (current > 0) {
          final newVal = current - 1;
          _counts[prayer.key] = newVal;
          _controllers[prayer.key]?.text = newVal.toString();
          _saveCount(prayer.key, newVal);
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.done_all_rounded, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '1 günlük tüm kaza namazları düşüldü.',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
    );
  }

  void _addFullDay() {
    HapticFeedback.mediumImpact();
    SoundService.playKazaArtir();
    setState(() {
      for (var prayer in _prayers) {
        final current = _counts[prayer.key] ?? 0;
        final newVal = current + 1;
        _counts[prayer.key] = newVal;
        _controllers[prayer.key]?.text = newVal.toString();
        _saveCount(prayer.key, newVal);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '1 günlük kaza namazı tüm vakitlere eklendi.',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
    );
  }

  void _openKazaCalculator() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => KazaCalculatorSheet(
        onApply: (calculatedCounts, overwrite) {
          HapticFeedback.mediumImpact();
          SoundService.playKazaArtir();
          setState(() {
            for (var prayer in _prayers) {
              final addOrSet = calculatedCounts[prayer.key] ?? 0;
              if (overwrite) {
                _counts[prayer.key] = addOrSet;
                _controllers[prayer.key]?.text = addOrSet.toString();
                _saveCount(prayer.key, addOrSet);
              } else {
                final current = _counts[prayer.key] ?? 0;
                final newVal = (current + addOrSet).clamp(0, 9999999);
                _counts[prayer.key] = newVal;
                _controllers[prayer.key]?.text = newVal.toString();
                _saveCount(prayer.key, newVal);
              }
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      overwrite
                          ? 'Kaza sayaçları hesaplanan değerlerle güncellendi.'
                          : 'Hesaplanan kaza namazları mevcut sayaçlara eklendi.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF334155), width: 1),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Sıfırlama Onayı'),
          ],
        ),
        content: const Text(
          'Tüm kaza namazı sayılarını sıfırlamak istediğinize emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              HapticFeedback.heavyImpact();
              setState(() {
                for (var prayer in _prayers) {
                  _counts[prayer.key] = 0;
                  _controllers[prayer.key]?.text = '0';
                  _saveCount(prayer.key, 0);
                }
              });
            },
            child: const Text('Evet, Sıfırla'),
          ),
        ],
      ),
    );
  }

  int get _totalKazalar => _counts.values.fold(0, (sum, val) => sum + val);

  String get _durationEstimate {
    final total = _totalKazalar;
    if (total == 0) return 'Tüm kazalar kılındı!';
    final totalDays = (total / 6).ceil();
    final years = totalDays ~/ 365;
    final remainingDaysAfterYears = totalDays % 365;
    final months = remainingDaysAfterYears ~/ 30;
    final days = remainingDaysAfterYears % 30;

    List<String> parts = [];
    if (years > 0) parts.add('$years Yıl');
    if (months > 0) parts.add('$months Ay');
    if (days > 0 || parts.isEmpty) parts.add('$days Gün');

    return 'Yaklaşık ${parts.join(' ')} (${totalDays.toString()} gün)';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final displayInfo = _prayerDisplayInfo ?? PrayerTimeService.calculatePrayerTimes();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern Compact App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? const Color(0xFF0B1329) : Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Kaza Takipçisi',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: _soundMuted ? 'Sesi Aç' : 'Sesi Kapat',
                icon: Icon(
                  _soundMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  color: _soundMuted ? Colors.grey : const Color(0xFF10B981),
                ),
                onPressed: _toggleSound,
              ),
              IconButton(
                tooltip: 'Tema Değiştir',
                icon: Icon(
                  widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                ),
                onPressed: widget.onToggleTheme,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (value) {
                  if (value == 'reset') {
                    _showResetDialog();
                  } else if (value == 'calculator') {
                    _openKazaCalculator();
                  } else if (value == 'add_day') {
                    _addFullDay();
                  } else if (value == 'refresh_location') {
                    _refreshLocation();
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'calculator',
                    child: Row(
                      children: [
                        Icon(Icons.calculate_rounded, color: Color(0xFF10B981), size: 20),
                        SizedBox(width: 8),
                        Text('Kaza Hesaplayıcı'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'refresh_location',
                    child: Row(
                      children: [
                        Icon(Icons.my_location_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Konumu Yenile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add_day',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Tümüne 1 Gün Ekle'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.restart_alt_rounded, color: Colors.redAccent, size: 20),
                        SizedBox(width: 8),
                        Text('Tümünü Sıfırla', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),

          // 1. Canlı Namaz Vakitleri & Konum Kutusu (Yenileme Butonlu)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: _LivePrayerTimesCard(
                info: displayInfo,
                isDark: isDark,
                isRefreshing: _isRefreshingLocation,
                onRefreshLocation: _refreshLocation,
              ),
            ),
          ),

          // 2. Kaza Namazı Özet Kartı
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF064E3B), const Color(0xFF047857)]
                        : [const Color(0xFF0F766E), const Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F766E).withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Üst Satır: Toplam Sayı & Cami İkonu
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Toplam Kaza Namazı',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_totalKazalar Vakit',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mosque_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Orta Satır: Taşmayan Tam Genişlikli Tahmini Süre Barı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _durationEstimate,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Alt Satır: Butonlar
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _completeFullDay,
                            icon: const Icon(Icons.done_all_rounded, size: 17),
                            label: const Text(
                              '1 Günlük Düş (-1)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F766E),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _openKazaCalculator,
                            icon: const Icon(Icons.calculate_rounded, size: 17),
                            label: const Text(
                              'Kaza Hesapla',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.22),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bilgilendirme Rozeti (02:00 Kuralı)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.nightlight_round, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bugün kılınanları sağ üstteki tikten işaretleyin. Gece 02:00\'de kılınmayanlar otomatik kazaya eklenir.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Başlık
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Row(
                children: [
                  Text(
                    'VAKİTLER VE KAZA LİSTESİ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tik: Bugün Kılındı',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Yenilenen Kusursuz Prayer Cards List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final prayer = _prayers[index];
                  final count = _counts[prayer.key] ?? 0;
                  final isTicked = _todayTicks[prayer.key] ?? false;
                  final controller = _controllers[prayer.key]!;

                  return _PrayerCard(
                    prayer: prayer,
                    count: count,
                    isTicked: isTicked,
                    controller: controller,
                    isDark: isDark,
                    onToggleTick: () => _toggleDailyTick(prayer.key, prayer.title),
                    onIncrement: () => _updateCount(prayer.key, 1),
                    onDecrement: () => _updateCount(prayer.key, -1),
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 0;
                      _setCount(prayer.key, parsed);
                    },
                    onQuickAdd: (addVal) => _updateCount(prayer.key, addVal),
                  );
                },
                childCount: _prayers.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 50),
          ),
        ],
      ),
    );
  }
}

/// Canlı Namaz Vakitleri, Konum ve Geri Sayım Kartı (Konum Yenile Butonu ile)
class _LivePrayerTimesCard extends StatelessWidget {
  final PrayerDisplayInfo info;
  final bool isDark;
  final bool isRefreshing;
  final VoidCallback onRefreshLocation;

  const _LivePrayerTimesCard({
    required this.info,
    required this.isDark,
    required this.isRefreshing,
    required this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D38) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF263556) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Konum Başlığı ve Yenile Butonu
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            info.locationName,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Konum Yenile Butonu
                        InkWell(
                          onTap: isRefreshing ? null : onRefreshLocation,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: isRefreshing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Şu an: ${info.currentPrayerTitle}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              // Geri Sayım Rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${info.nextPrayerTitle}\'e Kalan',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      info.timeRemainingString,
                      style: GoogleFonts.spaceMono(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Vakit İlerleme Çubuğu
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: info.progress,
              minHeight: 5,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),

          const SizedBox(height: 12),

          // Vakitler Yatay Çizelgesi (İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: info.timeline.map((vakit) {
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: vakit.isCurrent
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF1A2644) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: vakit.isCurrent
                          ? const Color(0xFF10B981)
                          : (isDark ? const Color(0xFF2E3E66) : const Color(0xFFE2E8F0)),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        vakit.name,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: vakit.isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: vakit.isCurrent
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vakit.timeString,
                        style: GoogleFonts.outfit(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: vakit.isCurrent
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yenilenen Kusursuz Düzenli Prayer Card (Sağ Üstte Günlük Tik Butonu)
class _PrayerCard extends StatelessWidget {
  final PrayerInfo prayer;
  final int count;
  final bool isTicked;
  final TextEditingController controller;
  final bool isDark;
  final VoidCallback onToggleTick;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<String> onChanged;
  final Function(int) onQuickAdd;

  const _PrayerCard({
    required this.prayer,
    required this.count,
    required this.isTicked,
    required this.controller,
    required this.isDark,
    required this.onToggleTick,
    required this.onIncrement,
    required this.onDecrement,
    required this.onChanged,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF131D38) : Colors.white;
    final borderColor = isDark ? const Color(0xFF263556) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isTicked ? const Color(0xFF10B981).withOpacity(0.7) : borderColor,
          width: isTicked ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTicked
                ? const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.08)
                : Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // 1. ÜST SATIR: Vakit Başlığı (Sol) + Günlük Namaz Tiki (Sağ Üst - Kırmızı İşaretli Yer)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sol: Vakit İkonu + Başlık + Rekât Bilgisi
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: prayer.accentColor.withOpacity(isDark ? 0.18 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        prayer.icon,
                        color: prayer.accentColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prayer.title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          prayer.subtitle,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Sağ Üst: Günlük Namaz Tiki (Bugün yazısı kaldırıldı, tam daire estetik tik butonu)
                InkWell(
                  onTap: onToggleTick,
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isTicked
                          ? const Color(0xFF10B981)
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isTicked
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF3B4D71) : const Color(0xFFCBD5E1)),
                        width: 1.5,
                      ),
                      boxShadow: isTicked
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      isTicked ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                      color: isTicked ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Ayırıcı çizgi
            Divider(
              height: 1,
              thickness: 0.8,
              color: isDark ? const Color(0xFF1E2B4B) : const Color(0xFFF1F5F9),
            ),

            const SizedBox(height: 10),

            // 2. ALT SATIR: Hızlı Kaza Ekleme Çipleri (Sol) + Kaza Sayaç Kontrolleri [-] [0] [+] (Sağ)
            Row(
              children: [
                // Sol: Hızlı Kaza Ekleme (+5, +10, +30)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuickChip(
                      label: '+5',
                      onTap: () => onQuickAdd(5),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 5),
                    _QuickChip(
                      label: '+10',
                      onTap: () => onQuickAdd(10),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 5),
                    _QuickChip(
                      label: '+30',
                      onTap: () => onQuickAdd(30),
                      isDark: isDark,
                    ),
                  ],
                ),

                const Spacer(),

                // Sağ: [-] [ Sayı ] [+]
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Icons.remove_rounded,
                      color: count > 0 ? Colors.redAccent : Colors.grey,
                      onPressed: count > 0 ? onDecrement : null,
                      isDark: isDark,
                      tooltip: '1 Kaza Azalt',
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 70,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0B1329) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? const Color(0xFF2E3E66) : const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(7),
                        ],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: onChanged,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.add_rounded,
                      color: const Color(0xFF10B981),
                      onPressed: onIncrement,
                      isDark: isDark,
                      tooltip: '1 Kaza Artır',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isDark;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.isDark,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 40,
          height: 42,
          decoration: BoxDecoration(
            color: isEnabled
                ? color.withOpacity(isDark ? 0.18 : 0.12)
                : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEnabled ? color.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isEnabled ? color : (isDark ? Colors.grey[600] : Colors.grey[400]),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _QuickChip({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0B1329) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? const Color(0xFF2E3E66) : const Color(0xFFCBD5E1),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}
