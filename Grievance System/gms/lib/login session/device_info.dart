import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, String>> getLoginInfo() async {
  final deviceInfoPlugin = DeviceInfoPlugin();
  String browser = 'Unknown';
  String ip = 'Unknown';
  String location = 'Unknown';

  try {
    final webInfo = await deviceInfoPlugin.webBrowserInfo;
    browser = '${webInfo.browserName.name} ${webInfo.userAgent ?? ""}';
  } catch (_) {}

  try {
    final ipRes = await http.get(Uri.parse('https://api.ipify.org?format=json'));
    ip = json.decode(ipRes.body)['ip'];

    final locationRes = await http.get(Uri.parse('https://ipapi.co/$ip/json/'));
    final locData = json.decode(locationRes.body);
    location = '${locData["city"]}, ${locData["region"]}, ${locData["country_name"]}';
  } catch (_) {}

  return {
    'browser': browser,
    'ip': ip,
    'location': location,
  };
}
