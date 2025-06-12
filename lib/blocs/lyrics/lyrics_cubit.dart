import 'dart:async';
import 'dart:developer';
import 'package:Bloomee/blocs/mediaPlayer/bloomee_player_cubit.dart';
import 'package:Bloomee/model/lyrics_models.dart';
import 'package:Bloomee/model/songModel.dart';
import 'package:Bloomee/repository/Lyrics/lyrics.dart';
import 'package:Bloomee/routes_and_consts/global_conts.dart';
import 'package:Bloomee/routes_and_consts/global_str_consts.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'lyrics_state.dart';

class LyricsCubit extends Cubit<LyricsState> {
  StreamSubscription? _mediaItemSubscription;
  LyricsCubit(BloomeePlayerCubit playerCubit) : super(LyricsInitial()) {
    _mediaItemSubscription =
        playerCubit.bloomeePlayer.mediaItem.stream.listen((v) {
      if (v != null) {
        getLyrics(mediaItem2MediaItemModel(v));
      }
    });
  }

  void getLyrics(MediaItemModel mediaItem) async {
    if (state.mediaItem == mediaItem && state is LyricsLoaded) {
      return;
    } else {
      emit(LyricsLoading(mediaItem));
      Lyrics? lyrics = await BloomeeDBService.getLyrics(mediaItem.id);
      if (lyrics == null) {
        try {
          // Extract video ID for YouTube sources
          String? videoId;
          if (mediaItem.extras?['source'] == 'youtube') {
            videoId = mediaItem.id.replaceAll('youtube', '');
          }
          
          lyrics = await LyricsRepository.getLyrics(
            mediaItem.title, 
            mediaItem.artist ?? "",
            album: mediaItem.album, 
            duration: mediaItem.duration,
            videoId: videoId,
          );
          
          if (lyrics.lyricsSynced == "No Lyrics Found") {
            lyrics = lyrics.copyWith(lyricsSynced: null);
          }
          
          lyrics = lyrics.copyWith(mediaID: mediaItem.id);
          emit(LyricsLoaded(lyrics, mediaItem));
          
          BloomeeDBService.getSettingBool(GlobalStrConsts.autoSaveLyrics)
              .then((value) {
            if ((value ?? false) && lyrics != null) {
              BloomeeDBService.putLyrics(lyrics);
              log("Lyrics saved for ID: ${mediaItem.id} Duration: ${lyrics.duration} Provider: ${lyrics.provider}",
                  name: "LyricsCubit");
            }
          });
          
          log("Lyrics loaded for ID: ${mediaItem.id} Duration: ${lyrics.duration} Provider: ${lyrics.provider} [Online]",
              name: "LyricsCubit");
        } catch (e) {
          log("Error loading lyrics: $e", name: "LyricsCubit");
          emit(LyricsError(mediaItem));
        }
      } else if (lyrics.mediaID == mediaItem.id) {
        emit(LyricsLoaded(lyrics, mediaItem));
        log("Lyrics loaded for ID: ${mediaItem.id} Duration: ${lyrics.duration} [Offline]",
            name: "LyricsCubit");
      }
    }
  }

  void setLyricsToDB(Lyrics lyrics, String mediaID) {
    final l1 = lyrics.copyWith(mediaID: mediaID);
    BloomeeDBService.putLyrics(l1).then((v) {
      emit(LyricsLoaded(l1, state.mediaItem));
    });
    log("Lyrics updated for ID: ${l1.mediaID} Duration: ${l1.duration}",
        name: "LyricsCubit");
  }

  void deleteLyricsFromDB(MediaItemModel mediaItem) {
    BloomeeDBService.removeLyricsById(mediaItem.id).then((value) {
      emit(LyricsInitial());
      getLyrics(mediaItem);

      log("Lyrics deleted for ID: ${mediaItem.id}", name: "LyricsCubit");
    });
  }

  /// Search lyrics from all providers and return options
  Future<Map<LyricsProvider, List<Lyrics>>> searchAllProviders(MediaItemModel mediaItem) async {
    String? videoId;
    if (mediaItem.extras?['source'] == 'youtube') {
      videoId = mediaItem.id.replaceAll('youtube', '');
    }
    
    return await LyricsRepository.getAllAvailableLyrics(
      mediaItem.title,
      mediaItem.artist ?? "",
      album: mediaItem.album,
      duration: mediaItem.duration,
      videoId: videoId,
    );
  }

  /// Get lyrics from a specific provider
  Future<void> getLyricsFromProvider(MediaItemModel mediaItem, LyricsProvider provider) async {
    emit(LyricsLoading(mediaItem));
    
    try {
      String? videoId;
      if (mediaItem.extras?['source'] == 'youtube') {
        videoId = mediaItem.id.replaceAll('youtube', '');
      }
      
      final lyrics = await LyricsRepository.getLyrics(
        mediaItem.title,
        mediaItem.artist ?? "",
        album: mediaItem.album,
        duration: mediaItem.duration,
        videoId: videoId,
        provider: provider,
      );
      
      final updatedLyrics = lyrics.copyWith(mediaID: mediaItem.id);
      emit(LyricsLoaded(updatedLyrics, mediaItem));
      
      log("Lyrics loaded from ${provider.name} for ID: ${mediaItem.id}", name: "LyricsCubit");
    } catch (e) {
      log("Error loading lyrics from $provider: $e", name: "LyricsCubit");
      emit(LyricsError(mediaItem));
    }
  }

  @override
  Future<void> close() {
    _mediaItemSubscription?.cancel();
    return super.close();
  }
}
