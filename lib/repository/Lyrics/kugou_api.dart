import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:Bloomee/model/lyrics_models.dart';

const String kugouBaseUrl = "http://lyrics.kugou.com";
const String kugouSearchUrl = "/search";
const String kugouDownloadUrl = "/download";

class KuGouAPI {
  static Future<Lyrics> getLyrics(
    String title,
    String artist, {
    int? duration,
  }) async {
    try {
      final searchResults = await _searchLyrics(title, artist, duration: duration);
      if (searchResults.isNotEmpty) {
        final bestMatch = searchResults.first;
        final lyricsContent = await _downloadLyrics(bestMatch['id'], bestMatch['accesskey']);
        
        return Lyrics(
          id: bestMatch['id'].toString(),
          artist: artist,
          title: title,
          lyricsPlain: lyricsContent['content'] ?? '',
          lyricsSynced: lyricsContent['content'],
          provider: LyricsProvider.kugou,
          duration: duration?.toString(),
        );
      }
    } catch (e) {
      log('KuGou API error: $e', name: 'KuGouAPI');
    }
    
    return Lyrics(
      id: '',
      artist: artist,
      title: title,
      lyricsPlain: 'Lyrics not found',
      provider: LyricsProvider.kugou,
    );
  }

  static Future<List<Map<String, dynamic>>> _searchLyrics(
    String title,
    String artist, {
    int? duration,
  }) async {
    final query = '$artist - $title';
    final searchParams = {
      'ver': '1',
      'man': 'yes',
      'client': 'pc',
      'keyword': query,
    };

    if (duration != null) {
      searchParams['duration'] = (duration * 1000).toString(); // Convert to milliseconds
    }

    final uri = Uri.parse('$kugouBaseUrl$kugouSearchUrl').replace(
      queryParameters: searchParams,
    );

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200 && data['candidates'] != null) {
          return List<Map<String, dynamic>>.from(data['candidates']);
        }
      }
    } catch (e) {
      log('KuGou search error: $e', name: 'KuGouAPI');
    }

    return [];
  }

  static Future<Map<String, dynamic>> _downloadLyrics(
    dynamic id,
    String accessKey,
  ) async {
    final downloadParams = {
      'ver': '1',
      'client': 'pc',
      'id': id.toString(),
      'accesskey': accessKey,
      'fmt': 'lrc',
      'charset': 'utf8',
    };

    final uri = Uri.parse('$kugouBaseUrl$kugouDownloadUrl').replace(
      queryParameters: downloadParams,
    );

    try {
      final response = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 200) {
          return data;
        }
      }
    } catch (e) {
      log('KuGou download error: $e', name: 'KuGouAPI');
    }

    return {};
  }

  static Future<List<Lyrics>> getAllLyrics(
    String title,
    String artist, {
    int? duration,
  }) async {
    final results = <Lyrics>[];
    
    try {
      final searchResults = await _searchLyrics(title, artist, duration: duration);
      
      for (final result in searchResults.take(5)) { // Limit to top 5 results
        try {
          final lyricsContent = await _downloadLyrics(result['id'], result['accesskey']);
          
          if (lyricsContent['content'] != null && lyricsContent['content'].isNotEmpty) {
            results.add(Lyrics(
              id: result['id'].toString(),
              artist: result['singer'] ?? artist,
              title: result['song'] ?? title,
              lyricsPlain: lyricsContent['content'],
              lyricsSynced: lyricsContent['content'],
              provider: LyricsProvider.kugou,
              duration: duration?.toString(),
            ));
          }
        } catch (e) {
          log('Error processing KuGou result: $e', name: 'KuGouAPI');
        }
      }
    } catch (e) {
      log('KuGou getAllLyrics error: $e', name: 'KuGouAPI');
    }
    
    return results;
  }
}