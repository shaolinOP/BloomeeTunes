import 'dart:convert';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:http/http.dart';
import 'helpers.dart';

abstract class YTMusicServices {
  YTMusicServices() : super() {
    init();
  }
  Future<void> init() async {
    headers = await initializeHeaders();
    context = await initializeContext();

    if (!headers.containsKey('X-Goog-Visitor-Id')) {
      headers['X-Goog-Visitor-Id'] = await getVisitorId(headers) ?? '';
    }
  }

  refreshContext() async {
    context = await initializeContext();
  }

  Future<void> refreshHeaders() async {
    headers = await initializeHeaders();
  }

  Future<void> resetVisitorId() async {
    Map<String, String> newHeaders = Map.from(headers);
    newHeaders.remove('X-Goog-Visitor-Id');
    final response = await sendGetRequest(httpsYtmDomain, newHeaders);
    final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
    RegExpMatch? matches = reg.firstMatch(response.body);
    String? visitorId;
    if (matches != null) {
      final ytcfg = json.decode(matches.group(1).toString());
      visitorId = ytcfg['VISITOR_DATA']?.toString();
      // await Hive.box('SETTINGS').put('VISITOR_ID', visitorId);
      visitorId != null
          ? await BloomeeDBService.putAPICache("VISITOR_ID", visitorId)
          : null;
    }
    refreshHeaders();
  }

  static const ytmDomain = 'music.youtube.com';
  static const httpsYtmDomain = 'https://music.youtube.com';
  static const baseApiEndpoint = '/youtubei/v1/';
  static const String ytmParams =
      '?alt=json&key=AIzaSyDK3iBpDP9nHVTk2qL73FLJICfOC3c51Og';
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36';

  Map<String, String> headers = {};
  int? signatureTimestamp;
  Map<String, dynamic> context = {};

  Future<Response> sendGetRequest(
    String url,
    Map<String, String>? headers,
  ) async {
    final Uri uri = Uri.parse(url);
    final Response response = await get(uri, headers: headers);
    return response;
  }

  Future<Response> addPlayingStats(String videoId, Duration time) async {
    final Uri uri = Uri.parse(
        'https://music.youtube.com/api/stats/watchtime?ns=yt&ver=2&c=WEB_REMIX&cmt=${(time.inMilliseconds / 1000)}&docid=$videoId');
    final Response response = await get(uri, headers: headers);
    return response;
  }

  Future<String?> getVisitorId(Map<String, String>? headers) async {
    try {
      final response = await sendGetRequest(httpsYtmDomain, headers);
      String responseBody;
      
      // Handle potential UTF-8 encoding issues
      try {
        responseBody = response.body;
      } catch (e) {
        // If UTF-8 decoding fails, try with latin1 and then convert
        responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
      }
      
      final reg = RegExp(r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;');
      final matches = reg.firstMatch(responseBody);
    String? visitorId;
    if (matches != null) {
      final ytcfg = json.decode(matches.group(1).toString());
      visitorId = ytcfg['VISITOR_DATA']?.toString();
      // await Hive.box('SETTINGS').put('VISITOR_ID', visitorId);
      visitorId != null
          ? await BloomeeDBService.putAPICache("VISITOR_ID", visitorId)
          : null;
    }
    // return await Hive.box('SETTINGS').get('VISITOR_ID');
    return await BloomeeDBService.getAPICache("VISITOR_ID");
    } catch (e) {
      print('Error getting visitor ID: $e');
      // Return cached visitor ID if available
      return await BloomeeDBService.getAPICache("VISITOR_ID");
    }
  }

  Future<Map> sendRequest(String endpoint, Map<String, dynamic> body,
      {Map<String, String>? headers, String additionalParams = ''}) async {
    try {
      body = {...body, ...context};

      this.headers.addAll(headers ?? {});
      final Uri uri = Uri.parse(httpsYtmDomain +
          baseApiEndpoint +
          endpoint +
          ytmParams +
          additionalParams);
      
      print('YTMusic API: Sending request to $uri');
      final response =
          await post(uri, headers: this.headers, body: jsonEncode(body));

      print('YTMusic API: Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map;
      } else {
        print('YTMusic API Error: ${response.statusCode} - ${response.body}');
        return {'error': 'HTTP ${response.statusCode}', 'body': response.body};
      }
    } catch (e) {
      print('YTMusic API Exception: $e');
      return {'error': e.toString()};
    }
  }
}
