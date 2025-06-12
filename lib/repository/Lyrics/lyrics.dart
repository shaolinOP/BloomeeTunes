import 'dart:developer';
import 'package:Bloomee/model/lyrics_models.dart';
import 'package:Bloomee/repository/Lyrics/lrcnet_api.dart';
import 'package:Bloomee/repository/Lyrics/kugou_api.dart';
import 'package:Bloomee/repository/Lyrics/youtube_music_api.dart';
import 'package:Bloomee/repository/Lyrics/youtube_subtitle_api.dart';

class LyricsRepository {
  static const List<LyricsProvider> _defaultProviderOrder = [
    LyricsProvider.lrcnet,
    LyricsProvider.kugou,
    LyricsProvider.youtubeMusic,
    LyricsProvider.youtubeSubtitle,
  ];

  static Future<Lyrics> getLyrics(
    String title,
    String artist, {
    String? album,
    Duration? duration,
    String? videoId,
    LyricsProvider provider = LyricsProvider.none,
    List<LyricsProvider>? providerOrder,
  }) async {
    final providers = providerOrder ?? _defaultProviderOrder;
    
    // If a specific provider is requested, try it first
    if (provider != LyricsProvider.none) {
      try {
        final result = await _getLyricsFromProvider(
          provider,
          title,
          artist,
          album: album,
          duration: duration,
          videoId: videoId,
        );
        if (result.lyricsPlain.isNotEmpty && result.lyricsPlain != 'Lyrics not found') {
          return result;
        }
      } catch (e) {
        log('Error with preferred provider $provider: $e', name: 'LyricsRepository');
      }
    }

    // Try all providers in order until we find lyrics
    for (final currentProvider in providers) {
      if (currentProvider == provider) continue; // Skip if already tried
      
      try {
        final result = await _getLyricsFromProvider(
          currentProvider,
          title,
          artist,
          album: album,
          duration: duration,
          videoId: videoId,
        );
        
        if (result.lyricsPlain.isNotEmpty && result.lyricsPlain != 'Lyrics not found') {
          log('Found lyrics using provider: $currentProvider', name: 'LyricsRepository');
          return result;
        }
      } catch (e) {
        log('Error with provider $currentProvider: $e', name: 'LyricsRepository');
        continue;
      }
    }

    // If no lyrics found, return empty result
    return Lyrics(
      id: '',
      artist: artist,
      title: title,
      lyricsPlain: 'Lyrics not found',
      provider: LyricsProvider.none,
    );
  }

  static Future<Lyrics> _getLyricsFromProvider(
    LyricsProvider provider,
    String title,
    String artist, {
    String? album,
    Duration? duration,
    String? videoId,
  }) async {
    switch (provider) {
      case LyricsProvider.lrcnet:
        return await getLRCNetAPILyrics(
          title,
          artist: artist,
          album: album,
          duration: duration?.inSeconds.toString(),
        );
      
      case LyricsProvider.kugou:
        return await KuGouAPI.getLyrics(
          title,
          artist,
          duration: duration?.inSeconds,
        );
      
      case LyricsProvider.youtubeMusic:
        if (videoId != null) {
          return await YouTubeMusicAPI.getLyrics(videoId, title, artist);
        } else {
          return await YouTubeMusicAPI.getLyricsBySearch(title, artist);
        }
      
      case LyricsProvider.youtubeSubtitle:
        if (videoId != null) {
          return await YouTubeSubtitleAPI.getLyrics(videoId, title, artist);
        } else {
          return await YouTubeSubtitleAPI.getLyricsBySearch(title, artist);
        }
      
      default:
        throw Exception('Unsupported provider: $provider');
    }
  }

  static Future<List<Lyrics>> searchLyrics(
    String title,
    String artist, {
    String? album,
    Duration? duration,
    LyricsProvider provider = LyricsProvider.none,
    List<LyricsProvider>? providerOrder,
  }) async {
    final providers = providerOrder ?? _defaultProviderOrder;
    final allResults = <Lyrics>[];

    // If a specific provider is requested, search only that provider
    if (provider != LyricsProvider.none) {
      try {
        final results = await _searchLyricsFromProvider(
          provider,
          title,
          artist,
          album: album,
          duration: duration,
        );
        allResults.addAll(results);
      } catch (e) {
        log('Error searching with provider $provider: $e', name: 'LyricsRepository');
      }
    } else {
      // Search all providers
      for (final currentProvider in providers) {
        try {
          final results = await _searchLyricsFromProvider(
            currentProvider,
            title,
            artist,
            album: album,
            duration: duration,
          );
          allResults.addAll(results);
        } catch (e) {
          log('Error searching with provider $currentProvider: $e', name: 'LyricsRepository');
          continue;
        }
      }
    }

    return allResults;
  }

  static Future<List<Lyrics>> _searchLyricsFromProvider(
    LyricsProvider provider,
    String title,
    String artist, {
    String? album,
    Duration? duration,
  }) async {
    switch (provider) {
      case LyricsProvider.lrcnet:
        return await searchLRCNetLyrics(
          title,
          artistName: artist,
          albumName: album,
        );
      
      case LyricsProvider.kugou:
        return await KuGouAPI.getAllLyrics(
          title,
          artist,
          duration: duration?.inSeconds,
        );
      
      case LyricsProvider.youtubeMusic:
      case LyricsProvider.youtubeSubtitle:
        // For YouTube providers, we can only get one result per search
        final result = await _getLyricsFromProvider(
          provider,
          title,
          artist,
          album: album,
          duration: duration,
        );
        return result.lyricsPlain.isNotEmpty && result.lyricsPlain != 'Lyrics not found'
            ? [result]
            : [];
      
      default:
        return [];
    }
  }

  /// Get all available lyrics from all providers
  static Future<Map<LyricsProvider, List<Lyrics>>> getAllAvailableLyrics(
    String title,
    String artist, {
    String? album,
    Duration? duration,
    String? videoId,
  }) async {
    final results = <LyricsProvider, List<Lyrics>>{};
    
    for (final provider in _defaultProviderOrder) {
      try {
        final providerResults = await _searchLyricsFromProvider(
          provider,
          title,
          artist,
          album: album,
          duration: duration,
        );
        
        if (providerResults.isNotEmpty) {
          results[provider] = providerResults;
        }
      } catch (e) {
        log('Error getting lyrics from $provider: $e', name: 'LyricsRepository');
      }
    }
    
    return results;
  }
}
