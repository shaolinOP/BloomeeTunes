import 'dart:developer' as dev;
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Direct URL YouTube audio source - gets the direct URL and uses it
class YouTubeDirectAudioSource {
  static Future<AudioSource> create({
    required String videoId,
    required String quality,
    required dynamic tag,
  }) async {
    YoutubeExplode? ytExplode;
    try {
      ytExplode = YoutubeExplode();
      dev.log('YouTubeDirect: Getting direct URL for video: $videoId', name: 'YouTubeDirect');
      
      // Try to get the manifest
      StreamManifest? manifest;
      try {
        manifest = await ytExplode.videos.streams.getManifest(videoId, requireWatchPage: false);
      } catch (e) {
        dev.log('YouTubeDirect: Failed to get manifest: $e', name: 'YouTubeDirect');
        throw Exception('Failed to get video manifest: $e');
      }
      
      final audioStreams = manifest.audioOnly.sortByBitrate();
      if (audioStreams.isEmpty) {
        throw Exception('No audio streams available for video: $videoId');
      }
      
      final selectedStream = quality == 'high' 
          ? audioStreams.last 
          : audioStreams.first;
      
      dev.log('YouTubeDirect: Selected stream URL: ${selectedStream.url}', name: 'YouTubeDirect');
      
      // Create a regular URI audio source with the direct URL
      return AudioSource.uri(
        selectedStream.url,
        tag: tag,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
          'Accept': 'audio/webm,audio/ogg,audio/*,*/*;q=0.1',
          'Accept-Encoding': 'identity',
          'Range': 'bytes=0-',
        },
      );
    } catch (e) {
      dev.log('YouTubeDirect: Error for video $videoId: $e', name: 'YouTubeDirect');
      throw Exception('Failed to create direct YouTube audio source: $e');
    } finally {
      ytExplode?.close();
    }
  }
}