import 'package:shared_preferences/shared_preferences.dart';

class GenderService {
  static const String _genderKey = 'user_gender';
  static const String _specialDayKey = 'is_special_day_active';

  static Future<String> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_genderKey) ?? 'erkek';
  }

  static Future<bool> isFemale() async {
    final gender = await getGender();
    return gender == 'kadin';
  }

  static Future<void> setGender(String gender) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_genderKey, gender);
  }

  static Future<bool> isSpecialDayActive() async {
    final isFem = await isFemale();
    if (!isFem) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_specialDayKey) ?? false;
  }

  static Future<void> setSpecialDayActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_specialDayKey, active);
  }
}
