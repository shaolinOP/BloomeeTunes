import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:Bloomee/model/lyrics_models.dart';

class YouTubeMusicAPI {
  static const String _baseUrl = 'https://music.youtube.com';
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';

  static Future<Lyrics> getLyrics(
    String videoId,
    String title,
    String artist,
  ) async {
    try {
      // First, get the watch page to find lyrics endpoint
      final watchData = await _getWatchData(videoId);
      if (watchData != null && watchData['lyricsEndpoint'] != null) {
        final lyricsContent = await _getLyricsFromEndpoint(watchData['lyricsEndpoint']);
        
        if (lyricsContent != null && lyricsContent.isNotEmpty) {
          return Lyrics(
            id: videoId,
            artist: artist,
            title: title,
            lyricsPlain: lyricsContent,
            provider: LyricsProvider.youtubeMusic,
          );
        }
      }
    } catch (e) {
      log('YouTube Music API error: $e', name: 'YouTubeMusicAPI');
    }
    
    return Lyrics(
      id: videoId,
      artist: artist,
      title: title,
      lyricsPlain: 'Lyrics not found',
      provider: LyricsProvider.youtubeMusic,
    );
  }

  static Future<Map<String, dynamic>?> _getWatchData(String videoId) async {
    try {
      final url = '$_baseUrl/youtubei/v1/next?key=$_apiKey';
      final headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'X-Goog-Api-Key': _apiKey,
      };

      final body = json.encode({
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': '1.0',
          }
        },
        'videoId': videoId,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Navigate through the response to find lyrics endpoint
        final contents = data['contents']?['singleColumnMusicWatchNextResultsRenderer']
            ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];
        
        if (contents != null) {
          for (final tab in contents) {
            final tabRenderer = tab['tabRenderer'];
            if (tabRenderer?['title']?['runs']?[0]?['text'] == 'Lyrics') {
              final endpoint = tabRenderer['endpoint']?['browseEndpoint'];
              if (endpoint != null) {
                return {'lyricsEndpoint': endpoint};
              }
            }
          }
        }
      }
    } catch (e) {
      log('Error getting watch data: $e', name: 'YouTubeMusicAPI');
    }
    
    return null;
  }

  static Future<String?> _getLyricsFromEndpoint(Map<String, dynamic> endpoint) async {
    try {
      final url = '$_baseUrl/youtubei/v1/browse?key=$_apiKey';
      final headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'X-Goog-Api-Key': _apiKey,
      };

      final body = json.encode({
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': '1.0',
          }
        },
        'browseId': endpoint['browseId'],
        'params': endpoint['params'],
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Navigate through the response to find lyrics text
        final contents = data['contents']?['sectionListRenderer']?['contents'];
        if (contents != null) {
          for (final content in contents) {
            final musicDescriptionShelf = content['musicDescriptionShelfRenderer'];
            if (musicDescriptionShelf != null) {
              final description = musicDescriptionShelf['description'];
              if (description?['runs'] != null) {
                final lyricsText = description['runs']
                    .map((run) => run['text'])
                    .join('');
                return lyricsText;
              }
            }
          }
        }
      }
    } catch (e) {
      log('Error getting lyrics from endpoint: $e', name: 'YouTubeMusicAPI');
    }
    
    return null;
  }

  static Future<Lyrics> getLyricsBySearch(
    String title,
    String artist,
  ) async {
    try {
      // Search for the song first
      final searchResults = await _searchSong(title, artist);
      if (searchResults.isNotEmpty) {
        final firstResult = searchResults.first;
        final videoId = firstResult['videoId'];
        if (videoId != null) {
          return await getLyrics(videoId, title, artist);
        }
      }
    } catch (e) {
      log('YouTube Music search error: $e', name: 'YouTubeMusicAPI');
    }
    
    return Lyrics(
      id: '',
      artist: artist,
      title: title,
      lyricsPlain: 'Lyrics not found',
      provider: LyricsProvider.youtubeMusic,
    );
  }

  static Future<List<Map<String, dynamic>>> _searchSong(
    String title,
    String artist,
  ) async {
    try {
      final query = '$artist $title';
      final url = '$_baseUrl/youtubei/v1/search?key=$_apiKey';
      final headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'X-Goog-Api-Key': _apiKey,
      };

      final body = json.encode({
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': '1.0',
          }
        },
        'query': query,
        'params': 'Eg-KAQwIARAAGAAgACgAMABqChAEEAUQAxAKEAk%3D', // Music filter
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = <Map<String, dynamic>>[];
        
        final contents = data['contents']?['tabbedSearchResultsRenderer']
            ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
        
        if (contents != null) {
          for (final section in contents) {
            final musicShelf = section['musicShelfRenderer'];
            if (musicShelf?['contents'] != null) {
              for (final item in musicShelf['contents']) {
                final musicResponsiveListItem = item['musicResponsiveListItemRenderer'];
                if (musicResponsiveListItem != null) {
                  final videoId = musicResponsiveListItem['playNavigationEndpoint']
                      ?['watchEndpoint']?['videoId'];
                  if (videoId != null) {
                    results.add({'videoId': videoId});
                  }
                }
              }
            }
          }
        }
        
        return results;
      }
    } catch (e) {
      log('Error searching song: $e', name: 'YouTubeMusicAPI');
    }
    
    return [];
  }
}