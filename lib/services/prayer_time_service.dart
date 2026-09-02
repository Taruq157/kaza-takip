import 'package:adhan/adhan.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VakitTimeItem {
  final String name;
  final String key;
  final DateTime time;
  final String timeString;
  final bool isCurrent;

  VakitTimeItem({
    required this.name,
    required this.key,
    required this.time,
    required this.timeString,
    required this.isCurrent,
  });
}

class PrayerDisplayInfo {
  final String locationName;
  final String currentPrayerTitle;
  final String nextPrayerTitle;
  final Duration timeRemainingToNext;
  final String timeRemainingString;
  final List<VakitTimeItem> timeline;
  final double progress;

  PrayerDisplayInfo({
    required this.locationName,
    required this.currentPrayerTitle,
    required this.nextPrayerTitle,
    required this.timeRemainingToNext,
    required this.timeRemainingString,
    required this.timeline,
    required this.progress,
  });
}

class PrayerTimeService {
  static double _lat = 41.0082;
  static double _lng = 28.9784;
  static String _locationName = 'İstanbul, Türkiye';
  static bool hasLoadedLocation = false;

  static double get latitude => _lat;
  static double get longitude => _lng;
  static String get locationName => _locationName;

  static Future<void> initLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _lat = prefs.getDouble('saved_lat') ?? 41.0082;
    _lng = prefs.getDouble('saved_lng') ?? 28.9784;
    _locationName = prefs.getString('saved_location_name') ?? 'İstanbul, Türkiye';

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        hasLoadedLocation = true;
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          hasLoadedLocation = true;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        hasLoadedLocation = true;
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );

      _lat = position.latitude;
      _lng = position.longitude;
      await prefs.setDouble('saved_lat', _lat);
      await prefs.setDouble('saved_lng', _lng);

      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(_lat, _lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final city = (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
              ? p.administrativeArea!
              : ((p.locality != null && p.locality!.isNotEmpty) ? p.locality! : 'Konum');
          final district = (p.subAdministrativeArea != null && p.subAdministrativeArea!.isNotEmpty)
              ? p.subAdministrativeArea!
              : ((p.subLocality != null && p.subLocality!.isNotEmpty) ? p.subLocality! : '');

          _locationName = (district.isNotEmpty && district != city)
              ? '$city, $district'
              : city;
          await prefs.setString('saved_location_name', _locationName);
        }
      } catch (_) {}
    } catch (_) {}
    hasLoadedLocation = true;
  }

  static Future<void> setManualLocation(String name, double lat, double lng) async {
    _locationName = name;
    _lat = lat;
    _lng = lng;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_location_name', name);
    await prefs.setDouble('saved_lat', lat);
    await prefs.setDouble('saved_lng', lng);
  }

  static PrayerDisplayInfo calculatePrayerTimes([DateTime? targetNow]) {
    final now = targetNow ?? DateTime.now();
    final coordinates = Coordinates(_lat, _lng);
    final params = CalculationMethod.turkey.getParameters();
    params.madhab = Madhab.hanafi;

    final dateComponents = DateComponents.from(now);
    final prayerTimes = PrayerTimes(coordinates, dateComponents, params);

    final tomorrowComponents = DateComponents.from(now.add(const Duration(days: 1)));
    final tomorrowPrayerTimes = PrayerTimes(coordinates, tomorrowComponents, params);

    final currentPrayer = prayerTimes.currentPrayer();

    DateTime currentStartTime;
    DateTime nextStartTime;
    String currentTitle;
    String nextTitle;

    switch (currentPrayer) {
      case Prayer.fajr:
        currentStartTime = prayerTimes.fajr;
        nextStartTime = prayerTimes.sunrise;
        currentTitle = 'İmsak / Sabah';
        nextTitle = 'Güneş';
        break;
      case Prayer.sunrise:
        currentStartTime = prayerTimes.sunrise;
        nextStartTime = prayerTimes.dhuhr;
        currentTitle = 'Güneş';
        nextTitle = 'Öğle';
        break;
      case Prayer.dhuhr:
        currentStartTime = prayerTimes.dhuhr;
        nextStartTime = prayerTimes.asr;
        currentTitle = 'Öğle Vakti';
        nextTitle = 'İkindi';
        break;
      case Prayer.asr:
        currentStartTime = prayerTimes.asr;
        nextStartTime = prayerTimes.maghrib;
        currentTitle = 'İkindi Vakti';
        nextTitle = 'Akşam';
        break;
      case Prayer.maghrib:
        currentStartTime = prayerTimes.maghrib;
        nextStartTime = prayerTimes.isha;
        currentTitle = 'Akşam Vakti';
        nextTitle = 'Yatsı';
        break;
      case Prayer.isha:
        currentStartTime = prayerTimes.isha;
        nextStartTime = tomorrowPrayerTimes.fajr;
        currentTitle = 'Yatsı Vakti';
        nextTitle = 'İmsak';
        break;
      case Prayer.none:
      default:
        final yesterdayComponents = DateComponents.from(now.subtract(const Duration(days: 1)));
        final yesterdayPrayerTimes = PrayerTimes(coordinates, yesterdayComponents, params);
        currentStartTime = yesterdayPrayerTimes.isha;
        nextStartTime = prayerTimes.fajr;
        currentTitle = 'Gece / Yatsı';
        nextTitle = 'İmsak';
        break;
    }

    final diff = nextStartTime.difference(now);
    final totalWindow = nextStartTime.difference(currentStartTime).inSeconds;
    final elapsed = now.difference(currentStartTime).inSeconds;
    final progress = totalWindow > 0 ? (elapsed / totalWindow).clamp(0.0, 1.0) : 0.0;

    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    final remainingStr = diff.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';

    final timeFormatter = DateFormat('HH:mm');

    final timeline = [
      VakitTimeItem(
        name: 'İmsak',
        key: 'sabah',
        time: prayerTimes.fajr,
        timeString: timeFormatter.format(prayerTimes.fajr),
        isCurrent: currentPrayer == Prayer.fajr,
      ),
      VakitTimeItem(
        name: 'Güneş',
        key: 'gunes',
        time: prayerTimes.sunrise,
        timeString: timeFormatter.format(prayerTimes.sunrise),
        isCurrent: currentPrayer == Prayer.sunrise,
      ),
      VakitTimeItem(
        name: 'Öğle',
        key: 'ogle',
        time: prayerTimes.dhuhr,
        timeString: timeFormatter.format(prayerTimes.dhuhr),
        isCurrent: currentPrayer == Prayer.dhuhr,
      ),
      VakitTimeItem(
        name: 'İkindi',
        key: 'ikindi',
        time: prayerTimes.asr,
        timeString: timeFormatter.format(prayerTimes.asr),
        isCurrent: currentPrayer == Prayer.asr,
      ),
      VakitTimeItem(
        name: 'Akşam',
        key: 'aksam',
        time: prayerTimes.maghrib,
        timeString: timeFormatter.format(prayerTimes.maghrib),
        isCurrent: currentPrayer == Prayer.maghrib,
      ),
      VakitTimeItem(
        name: 'Yatsı',
        key: 'yatsi',
        time: prayerTimes.isha,
        timeString: timeFormatter.format(prayerTimes.isha),
        isCurrent: currentPrayer == Prayer.isha || currentPrayer == Prayer.none,
      ),
    ];

    return PrayerDisplayInfo(
      locationName: _locationName,
      currentPrayerTitle: currentTitle,
      nextPrayerTitle: nextTitle,
      timeRemainingToNext: diff,
      timeRemainingString: remainingStr,
      timeline: timeline,
      progress: progress,
    );
  }
}
