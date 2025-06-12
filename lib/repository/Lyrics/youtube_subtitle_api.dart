import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:Bloomee/model/lyrics_models.dart';

class YouTubeSubtitleAPI {
  static const String _baseUrl = 'https://www.youtube.com';

  static Future<Lyrics> getLyrics(
    String videoId,
    String title,
    String artist,
  ) async {
    try {
      final subtitles = await _getSubtitles(videoId);
      if (subtitles.isNotEmpty) {
        return Lyrics(
          id: videoId,
          artist: artist,
          title: title,
          lyricsPlain: subtitles,
          provider: LyricsProvider.youtubeSubtitle,
        );
      }
    } catch (e) {
      log('YouTube Subtitle API error: $e', name: 'YouTubeSubtitleAPI');
    }
    
    return Lyrics(
      id: videoId,
      artist: artist,
      title: title,
      lyricsPlain: 'Subtitles not found',
      provider: LyricsProvider.youtubeSubtitle,
    );
  }

  static Future<String> _getSubtitles(String videoId) async {
    try {
      // First, get the video page to extract subtitle information
      final videoPageUrl = '$_baseUrl/watch?v=$videoId';
      final response = await http.get(
        Uri.parse(videoPageUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final pageContent = response.body;
        
        // Extract player response from the page
        final playerResponseMatch = RegExp(r'"playerResponse":"([^"]+)"')
            .firstMatch(pageContent);
        
        if (playerResponseMatch != null) {
          final playerResponseJson = playerResponseMatch.group(1)!
              .replaceAll(r'\"', '"')
              .replaceAll(r'\\', '\\');
          
          final playerResponse = json.decode(playerResponseJson);
          final captionTracks = playerResponse['captions']?['playerCaptionsTracklistRenderer']
              ?['captionTracks'];
          
          if (captionTracks != null && captionTracks.isNotEmpty) {
            // Look for English captions first, then any available
            Map<String, dynamic>? selectedTrack;
            
            for (final track in captionTracks) {
              if (track['languageCode'] == 'en' || 
                  track['languageCode']?.startsWith('en') == true) {
                selectedTrack = track;
                break;
              }
            }
            
            // If no English track found, use the first available
            selectedTrack ??= captionTracks[0];
            
            if (selectedTrack != null) {
              final captionUrl = selectedTrack['baseUrl'];
              if (captionUrl != null) {
                return await _downloadSubtitles(captionUrl);
              }
            }
          }
        }
      }
    } catch (e) {
      log('Error getting subtitles: $e', name: 'YouTubeSubtitleAPI');
    }
    
    return '';
  }

  static Future<String> _downloadSubtitles(String captionUrl) async {
    try {
      // Add format parameter to get plain text
      final url = captionUrl.contains('?') 
          ? '$captionUrl&fmt=srv3'
          : '$captionUrl?fmt=srv3';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        return _parseSubtitleXml(response.body);
      }
    } catch (e) {
      log('Error downloading subtitles: $e', name: 'YouTubeSubtitleAPI');
    }
    
    return '';
  }

  static String _parseSubtitleXml(String xmlContent) {
    try {
      final lines = <String>[];
      
      // Simple XML parsing for subtitle text
      final textMatches = RegExp(r'<text[^>]*>([^<]+)</text>')
          .allMatches(xmlContent);
      
      for (final match in textMatches) {
        final text = match.group(1);
        if (text != null && text.trim().isNotEmpty) {
          // Decode HTML entities
          final decodedText = text
              .replaceAll('&amp;', '&')
              .replaceAll('&lt;', '<')
              .replaceAll('&gt;', '>')
              .replaceAll('&quot;', '"')
              .replaceAll('&#39;', "'")
              .replaceAll('&nbsp;', ' ');
          
          lines.add(decodedText.trim());
        }
      }
      
      return lines.join('\n');
    } catch (e) {
      log('Error parsing subtitle XML: $e', name: 'YouTubeSubtitleAPI');
      return '';
    }
  }

  static Future<Lyrics> getLyricsBySearch(
    String title,
    String artist,
  ) async {
    try {
      // Search for the song on YouTube
      final searchResults = await _searchVideo(title, artist);
      if (searchResults.isNotEmpty) {
        final firstResult = searchResults.first;
        final videoId = firstResult['videoId'];
        if (videoId != null) {
          return await getLyrics(videoId, title, artist);
        }
      }
    } catch (e) {
      log('YouTube search error: $e', name: 'YouTubeSubtitleAPI');
    }
    
    return Lyrics(
      id: '',
      artist: artist,
      title: title,
      lyricsPlain: 'Subtitles not found',
      provider: LyricsProvider.youtubeSubtitle,
    );
  }

  static Future<List<Map<String, dynamic>>> _searchVideo(
    String title,
    String artist,
  ) async {
    try {
      final query = Uri.encodeComponent('$artist $title lyrics');
      final searchUrl = '$_baseUrl/results?search_query=$query';
      
      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      );

      if (response.statusCode == 200) {
        final pageContent = response.body;
        final results = <Map<String, dynamic>>[];
        
        // Extract video IDs from the search results
        final videoIdMatches = RegExp(r'"videoId":"([^"]+)"')
            .allMatches(pageContent);
        
        final seenIds = <String>{};
        for (final match in videoIdMatches) {
          final videoId = match.group(1);
          if (videoId != null && !seenIds.contains(videoId)) {
            seenIds.add(videoId);
            results.add({'videoId': videoId});
            
            // Limit to first 5 results
            if (results.length >= 5) break;
          }
        }
        
        return results;
      }
    } catch (e) {
      log('Error searching video: $e', name: 'YouTubeSubtitleAPI');
    }
    
    return [];
  }
}