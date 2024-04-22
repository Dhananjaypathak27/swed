import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {

  addStringToPref(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  addBoolToPref(String key, bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, value);
  }

  Future<String> getStringFromPref(String key) async {
    //Return String
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String stringValue = prefs.getString(key)??"101";
    return stringValue;
  }

  Future<bool> getBoolFromPref(String key) async {
    //Return bool
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool value = prefs.getBool(key)??false;
    return value;
  }


  clearPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

}
