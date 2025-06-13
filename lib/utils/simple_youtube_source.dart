import 'dart:developer' as dev;
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Simple YouTube audio source that directly uses YouTube Explode
/// This is a fallback implementation inspired by Harmony Music
class SimpleYouTubeAudioSource extends StreamAudioSource {
  final String videoId;
  final String quality;
  final YoutubeExplode ytExplode;

  SimpleYouTubeAudioSource({
    required this.videoId,
    required this.quality,
    super.tag,
  }) : ytExplode = YoutubeExplode();

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    try {
      dev.log('SimpleYT: Getting streams for video: $videoId', name: 'SimpleYT');
      
      final manifest = await ytExplode.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.sortByBitrate();
      
      if (audioStreams.isEmpty) {
        throw Exception('No audio streams available for video: $videoId');
      }
      
      final selectedStream = quality == 'high' 
          ? audioStreams.last 
          : audioStreams.first;
      
      dev.log('SimpleYT: Selected stream - ${selectedStream.codec?.mimeType ?? 'unknown'} ${selectedStream.bitrate?.bitsPerSecond ?? 0}', name: 'SimpleYT');
      
      start ??= 0;
      
      // Null safety checks
      final streamSize = selectedStream.size?.totalBytes;
      if (streamSize == null) {
        throw Exception('Stream size is null for video: $videoId');
      }
      
      if (end != null && end > streamSize) {
        end = streamSize;
      }

      final stream = ytExplode.videos.streams.get(
        selectedStream,
        start: start,
        end: end,
      );

      final mimeType = selectedStream.codec?.mimeType ?? 'audio/mp4';

      return StreamAudioResponse(
        sourceLength: streamSize,
        contentLength: end != null ? end - start : streamSize - start,
        offset: start,
        stream: stream,
        contentType: mimeType,
      );
    } catch (e) {
      dev.log('SimpleYT: Error for video $videoId: $e', name: 'SimpleYT');
      throw Exception('Failed to load YouTube audio: $e');
    }
  }

  void dispose() {
    ytExplode.close();
  }
}