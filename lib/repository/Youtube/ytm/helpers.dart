import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';

Future<Map<String, String>> initializeHeaders({String language = 'en'}) async {
  Map<String, String> h = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36",
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate, br',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    "Origin": "https://music.youtube.com",
    "Referer": "https://music.youtube.com/",
    'cookie': 'CONSENT=YES+cb.20210328-17-p0.en+FX+1',
    'Accept-Language': '$language,en;q=0.9',
    'sec-ch-ua': '"Not_A Brand";v="8", "Chromium";v="134", "Google Chrome";v="134"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Windows"',
    'sec-fetch-dest': 'empty',
    'sec-fetch-mode': 'cors',
    'sec-fetch-site': 'same-origin',
  };
  // String? visitorId = Hive.box('SETTINGS').get('VISITOR_ID');
  String? visitorId = await BloomeeDBService.getAPICache("VISITOR_ID");
  if (visitorId != null) {
    h['X-Goog-Visitor-Id'] = visitorId;
  }
  return h;
}

Future<Map<String, dynamic>> initializeContext() async {
  final DateTime now = DateTime.now();
  final String year = now.year.toString();
  final String month = now.month.toString().padLeft(2, '0');
  final String day = now.day.toString().padLeft(2, '0');
  final String date = year + month + day;
  return {
    'context': {
      'client': {
        "hl": "en",
        "gl": await BloomeeDBService.getSettingStr(GlobalStrConsts.countryCode,
            defaultValue: "US"),
        'clientName': 'WEB_REMIX',
        'clientVersion': '1.$date.01.00',
        'osName': 'Windows',
        'osVersion': '10.0',
        'platform': 'DESKTOP',
        'clientFormFactor': 'UNKNOWN_FORM_FACTOR',
        'userInterfaceTheme': 'USER_INTERFACE_THEME_DARK',
        'timeZone': 'UTC',
        'browserName': 'Chrome',
        'browserVersion': '134.0.0.0',
        'acceptHeader': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'deviceMake': '',
        'deviceModel': '',
        'utcOffsetMinutes': 0,
      },
      'user': {
        'lockedSafetyMode': false
      },
      'request': {
        'useSsl': true,
        'internalExperimentFlags': [],
        'consistencyTokenJars': []
      }
    }
  };
}

dynamic nav(dynamic root, List<dynamic> items, {bool noneIfAbsent = false}) {
  try {
    for (var k in items) {
      root = root?[k];
    }
    return root;
  } catch (err) {
    if (noneIfAbsent) {
      return null;
    } else {
      rethrow;
    }
  }
}

String getContinuationString(dynamic ctoken) {
  return "&ctoken=$ctoken&continuation=$ctoken";
}
